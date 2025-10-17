import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sms.transaction.dart';
import '../utils/notifiers.dart';

class SMSService {
  static const int _timeoutDuration = 10; // Timeout in seconds
  static const int _maxRetries = 3; // Max retry attempts
  static const Duration _cacheDuration = Duration(minutes: 30); // Cache expiration

  // Set headers with token
  Future<Map<String, String>> _setHeaders(String token) async {
    var cleanToken = token.replaceAll('"', '');
    debugPrint(cleanToken);

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': cleanToken,
    };
  }

  // Generic HTTP GET with exponential backoff retry
  Future<http.Response> _getWithRetry(String url, Map<String, String> headers) async {
    int attempt = 0;
    while (attempt < _maxRetries) {
      try {
        debugPrint("Request URL: $url");
        final response = await http
            .get(Uri.parse(url), headers: headers)
            .timeout(Duration(seconds: _timeoutDuration));
        debugPrint("URL: $url");
        debugPrint("Headers: $headers");
        debugPrint("Response: ${response.body}");
        return response;
      } catch (e) {
        attempt++;
        if (attempt == _maxRetries) {
          throw Exception('GET request failed after $_maxRetries attempts: $e');
        }
        await Future.delayed(Duration(milliseconds: 500 * (attempt * attempt)));
      }
    }
    throw Exception('Unreachable code');
  }

  // Generic HTTP POST with exponential backoff retry
  Future<http.Response> _postWithRetry(String url, Map<String, String> headers, String body) async {
    int attempt = 0;
    while (attempt < _maxRetries) {
      try {
        final response = await http
            .post(Uri.parse(url), headers: headers, body: body)
            .timeout(const Duration(seconds: _timeoutDuration));
        debugPrint("URL: $url");
        debugPrint("Headers: $headers");
        debugPrint("Body: $body");
        debugPrint("Response: ${response.body}");
        return response;
      } catch (e) {
        attempt++;
        if (attempt == _maxRetries) {
          throw Exception('POST request failed after $_maxRetries attempts: $e');
        }
        await Future.delayed(Duration(milliseconds: 500 * (attempt * attempt)));
      }
    }
    throw Exception('Unreachable code');
  }

  // Get SMS balance for a school
  Future<SMSBalanceModel> getSMSBalance(String schoolId) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);

      // Check cache
      final cachedBalance = sharedPreferences.getString('sms_balance_$schoolId');
      final cacheTimestamp = sharedPreferences.getInt('sms_balance_timestamp_$schoolId');
      if (cachedBalance != null &&
          cacheTimestamp != null &&
          DateTime.now().millisecondsSinceEpoch - cacheTimestamp < _cacheDuration.inMilliseconds) {
        final jsonData = jsonDecode(cachedBalance);
        return SMSBalanceModel.fromJson(jsonData);
      }

      final response = await _getWithRetry(
        '${dotenv.get('mainUrl')}/api/schools/$schoolId/sms/balance',
        headers,
      );

      final results = jsonDecode(response.body);

      if (response.statusCode == 200 && results['success'] == true) {
        final balanceModel = SMSBalanceModel.fromJson(results);
        
        // Cache the response with timestamp
        await sharedPreferences.setString('sms_balance_$schoolId', response.body);
        await sharedPreferences.setInt('sms_balance_timestamp_$schoolId', DateTime.now().millisecondsSinceEpoch);
        debugPrint('Service - SMS balance cached successfully');
        
        return balanceModel;
      } else {
        debugPrint('Error fetching SMS balance: Status ${response.statusCode}, Message: ${results['message']}');
        return SMSBalanceModel(
          status: response.statusCode,
          success: false,
          message: results['message'] ?? 'Failed to fetch SMS balance',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error fetching SMS balance: $e');
      return SMSBalanceModel(
        status: 500,
        success: false,
        message: 'Failed to fetch SMS balance: $e',
        data: null,
      );
    }
  }

  // Top up SMS balance
  Future<SMSBalanceModel> topUpSMS({
    required String schoolId,
    required double amount,
    required String paymentMethod,
    required String paymentReference,
    String? description,
  }) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);

      final body = jsonEncode({
        'amount': amount,
        'paymentMethod': paymentMethod,
        'paymentReference': paymentReference,
        'description': description ?? 'SMS Credits Top-up',
      });

      final response = await _postWithRetry(
        '${dotenv.get('mainUrl')}/api/schools/$schoolId/sms/topup',
        headers,
        body,
      );

      final results = jsonDecode(response.body);
      debugPrint(results.toString());

      if (response.statusCode == 200 && results['success'] == true) {
        // Clear cache to force refresh
        await sharedPreferences.remove('sms_balance_$schoolId');
        await sharedPreferences.remove('sms_balance_timestamp_$schoolId');
        await sharedPreferences.remove('sms_transactions_$schoolId');
        await sharedPreferences.remove('sms_transactions_timestamp_$schoolId');

        showSuccessAlert(results['message'] ?? 'SMS top-up successful!', Get.context!);
        return SMSBalanceModel.fromJson(results);
      } else {
        showErrorAlert(results['message'] ?? 'Failed to top up SMS: ${response.statusCode}', Get.context!);
        throw Exception(results['message'] ?? 'Failed to top up SMS: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error topping up SMS: $e');
      showErrorAlert('Failed to top up SMS: $e', Get.context!);
      throw Exception('Failed to top up SMS: $e');
    }
  }

  // Get SMS transaction history with pagination
  Future<SMSTransactionHistoryModel> getSMSTransactionHistory({
    required String schoolId,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);

      // Check cache only for first page
      if (page == 0) {
        final cachedTransactions = sharedPreferences.getString('sms_transactions_$schoolId');
        final cacheTimestamp = sharedPreferences.getInt('sms_transactions_timestamp_$schoolId');
        if (cachedTransactions != null &&
            cacheTimestamp != null &&
            DateTime.now().millisecondsSinceEpoch - cacheTimestamp < _cacheDuration.inMilliseconds) {
          final jsonData = jsonDecode(cachedTransactions);
          return SMSTransactionHistoryModel.fromJson(jsonData);
        }
      }

      final response = await _getWithRetry(
        '${dotenv.get('mainUrl')}/api/schools/$schoolId/sms/transactions?page=$page&size=$size',
        headers,
      );

      final results = jsonDecode(response.body);

      if (response.statusCode == 200 && results['success'] == true) {
        final historyModel = SMSTransactionHistoryModel.fromJson(results);
        
        // Cache the response with timestamp (only for first page)
        if (page == 0) {
          await sharedPreferences.setString('sms_transactions_$schoolId', response.body);
          await sharedPreferences.setInt('sms_transactions_timestamp_$schoolId', DateTime.now().millisecondsSinceEpoch);
          debugPrint('Service - SMS transactions cached successfully');
        }
        
        return historyModel;
      } else if (response.statusCode == 404) {
        debugPrint('No SMS transaction history found for schoolId: $schoolId');
        return SMSTransactionHistoryModel(
          status: 200,
          success: true,
          message: 'No transaction history found',
          data: SMSTransactionData(
            content: [],
            totalElements: 0,
            totalPages: 0,
            size: size,
            number: page,
          ),
        );
      } else {
        final errorMessage = results['message'] ?? 'Failed to load SMS transaction history: ${response.statusCode}';
        debugPrint('Error fetching SMS transaction history: $errorMessage, Response: ${response.body}');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Error fetching SMS transaction history: $e');
      throw Exception('Failed to fetch SMS transaction history: $e');
    }
  }

  // Send bulk SMS (if endpoint exists)
  Future<SMSBulkResponseModel> sendBulkSMS({
    required String schoolId,
    required List<String> recipients,
    required String message,
  }) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);

      final body = jsonEncode({
        'recipients': recipients,
        'message': message,
      });

      final response = await _postWithRetry(
        '${dotenv.get('mainUrl')}/api/schools/$schoolId/sms/send-bulk',
        headers,
        body,
      );

      final results = jsonDecode(response.body);
      debugPrint(results.toString());

      if (response.statusCode == 200 && results['success'] == true) {
        // Clear cache to force refresh
        await sharedPreferences.remove('sms_balance_$schoolId');
        await sharedPreferences.remove('sms_balance_timestamp_$schoolId');
        await sharedPreferences.remove('sms_transactions_$schoolId');
        await sharedPreferences.remove('sms_transactions_timestamp_$schoolId');

        showSuccessAlert(results['message'] ?? 'SMS sent successfully!', Get.context!);
        return SMSBulkResponseModel.fromJson(results);
      } else {
        showErrorAlert(results['message'] ?? 'Failed to send SMS: ${response.statusCode}', Get.context!);
        throw Exception(results['message'] ?? 'Failed to send SMS: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending bulk SMS: $e');
      showErrorAlert('Failed to send SMS: $e', Get.context!);
      throw Exception('Failed to send SMS: $e');
    }
  }

  // Send SMS to parents about fees
  Future<SMSBulkResponseModel> sendFeeNotificationSMS({
    required String schoolId,
    required String studentId,
    bool sendSMS = true,
  }) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);

      final response = await _postWithRetry(
        '${dotenv.get('mainUrl')}/api/schools/$schoolId/sms/fee-notification/student/$studentId?sendSms=$sendSMS',
        headers,
        '',
      );

      final results = jsonDecode(response.body);

      if (response.statusCode == 200 && results['success'] == true) {
        // Clear cache to force refresh
        await sharedPreferences.remove('sms_balance_$schoolId');
        await sharedPreferences.remove('sms_balance_timestamp_$schoolId');
        await sharedPreferences.remove('sms_transactions_$schoolId');
        await sharedPreferences.remove('sms_transactions_timestamp_$schoolId');

        showSuccessAlert(results['message'] ?? 'Fee notification sent successfully', Get.context!);
        return SMSBulkResponseModel.fromJson(results);
      } else {
        showErrorAlert(results['message'] ?? 'Failed to send fee notification: ${response.statusCode}', Get.context!);
        throw Exception(results['message'] ?? 'Failed to send fee notification: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending fee notification SMS: $e');
      showErrorAlert('Failed to send fee notification: $e', Get.context!);
      throw Exception('Failed to send fee notification: $e');
    }
  }

  // Get SMS usage statistics (if needed)
  Future<SMSUsageStatsModel> getSMSUsageStats({
    required String schoolId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);

      // Construct URL with query parameters
      final baseUrl = '${dotenv.get('mainUrl')}/api/schools/$schoolId/sms/stats';
      final queryParams = <String, String>{};
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['endDate'] = endDate;
      }

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      debugPrint('Request URL: $uri');

      final response = await _getWithRetry(uri.toString(), headers);
      final results = jsonDecode(response.body);

      if (response.statusCode == 200 && results['success'] == true) {
        return SMSUsageStatsModel.fromJson(results);
      } else {
        final errorMessage = results['message'] ?? 'Failed to load SMS usage stats: ${response.statusCode}';
        debugPrint('Error fetching SMS usage stats: $errorMessage, Response: ${response.body}');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Error fetching SMS usage stats: $e');
      throw Exception('Failed to fetch SMS usage stats: $e');
    }
  }

  // Clear cache for a specific school
  Future<void> clearSMSCache(String schoolId) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.remove('sms_balance_$schoolId');
    await sharedPreferences.remove('sms_balance_timestamp_$schoolId');
    await sharedPreferences.remove('sms_transactions_$schoolId');
    await sharedPreferences.remove('sms_transactions_timestamp_$schoolId');
    debugPrint('SMS cache cleared for school: $schoolId');
  }

  // Clear all SMS cache
  Future<void> clearAllSMSCache() async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final keys = sharedPreferences.getKeys();
    final smsKeys = keys.where((key) => 
        key.startsWith('sms_balance_') || 
        key.startsWith('sms_transactions_')
    ).toList();
    
    for (String key in smsKeys) {
      await sharedPreferences.remove(key);
    }
    debugPrint('All SMS cache cleared');
  }
}
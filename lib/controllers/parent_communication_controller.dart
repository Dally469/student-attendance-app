import 'package:attendance/models/student.model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/notifiers.dart';

// Recipient model for sendBulkSms API
class Recipient {
  final String phone;
  final String message;

  Recipient({required this.phone, required this.message});

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'message': message,
      };
}

class ParentCommunicationController extends GetxController {
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  RxString successMessage = ''.obs;
  RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> recipients = <Map<String, dynamic>>[].obs;

  static const int _timeoutDuration = 10; // Timeout in seconds
  static const int _maxRetries = 3; // Max retry attempts

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
  Future<http.Response> _getWithRetry(
      String url, Map<String, String> headers) async {
    int attempt = 0;
    while (attempt < _maxRetries) {
      try {
        final response = await http
            .get(Uri.parse(url), headers: headers)
            .timeout(Duration(seconds: _timeoutDuration));
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
  Future<http.Response> _postWithRetry(
      String url, Map<String, String> headers, String body) async {
    int attempt = 0;
    while (attempt < _maxRetries) {
      try {
        final response = await http
            .post(Uri.parse(url), headers: headers, body: body)
            .timeout(Duration(seconds: _timeoutDuration));
        return response;
      } catch (e) {
        attempt++;
        if (attempt == _maxRetries) {
          throw Exception(
              'POST request failed after $_maxRetries attempts: $e');
        }
        await Future.delayed(Duration(milliseconds: 500 * (attempt * attempt)));
      }
    }
    throw Exception('Unreachable code');
  }

  Future<bool> sendBulkSms({
    required String classroomId,
    required String message,
    required List<StudentData> students,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      // Prepare recipients with customized messages
      final recipients = students
          .map((student) {
            String finalMessage = message;
            finalMessage = finalMessage.replaceAll(
                '{{student_name}}', student.name ?? 'Student');
            finalMessage = finalMessage.replaceAll(
                '{{school}}', student.school ?? 'School');
            finalMessage = finalMessage.replaceAll(
                '{{classroom}}', student.classroom ?? 'Classroom');
            return Recipient(
              phone: student.parentContact ?? '',
              message: finalMessage,
            );
          })
          .where((recipient) => recipient.phone.isNotEmpty)
          .toList();

      if (recipients.isEmpty) {
        errorMessage.value = 'No valid parent contacts found';
        return false;
      }

      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);
      final baseUrl = '${dotenv.get('mainUrl')}/api/students';

      final data = {
        'sender_id': "swiftqom",
        'recipients': recipients,
        'message': message,
      };

      debugPrint(jsonEncode(data));

      final response = await _postWithRetry(
        '$baseUrl/bulk-parent-communication',
        headers,
        jsonEncode(data),
      );

      final results = jsonDecode(response.body);

      if (response.statusCode == 200 && results['success'] == true) {
        showSuccessAlert(
            results['message'] ?? 'Fee notification sent successfully',
            Get.context!);
        return true;
      } else {
        showErrorAlert(
            results['message'] ??
                'Failed to notify student fee to parent: ${response.statusCode}',
            Get.context!);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error sending messages: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}

import 'dart:convert';
import 'package:attendance/models/fee.payment.dto.dart';
import 'package:attendance/models/record.school.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendance/models/school.fee.type.dart';
import 'package:attendance/controllers/school_fees_controller.dart';

import '../models/classroom.fee.history.dart';
import '../models/fee.assign.dto.dart';
import '../models/school.model.dart';
import '../models/student.model.dart';
import '../utils/notifiers.dart'; // Import for StudentFeeDTO and FeePaymentDTO

class FeeService {
  static const int _timeoutDuration = 10; // Timeout in seconds
  static const int _maxRetries = 3; // Max retry attempts
  static const Duration _cacheDuration = Duration(hours: 1); // Cache expiration

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
        debugPrint("request url: $url");
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
  Future<http.Response> _putWithRetry(String url, Map<String, String> headers, String body) async {
    int attempt = 0;
    while (attempt < _maxRetries) {
      try {
        final response = await http
            .put(Uri.parse(url), headers: headers, body: body)
            .timeout(const Duration(seconds: _timeoutDuration));
            debugPrint("URL: $url");
            debugPrint("Headers: $headers");
            debugPrint("Body: $body");
            debugPrint("Response: ${response.body}");
        return response;
      } catch (e) {
        attempt++;
        if (attempt == _maxRetries) {
          throw Exception('PUT request failed after $_maxRetries attempts: $e');
        }
        await Future.delayed(Duration(milliseconds: 500 * (attempt * attempt)));
      }
    }
    throw Exception('Unreachable code');
  }
  Future<http.Response> _deleteWithRetry(String url, Map<String, String> headers) async {
    int attempt = 0;
    while (attempt < _maxRetries) {
      try {
        final response = await http
            .delete(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: _timeoutDuration));
              debugPrint("URL: $url");
              debugPrint("Headers: $headers");
              debugPrint("Response: ${response.body}");
        return response;
      } catch (e) {
        attempt++;
        if (attempt == _maxRetries) {
          throw Exception('DELETE request failed after $_maxRetries attempts: $e');
        }
        await Future.delayed(Duration(milliseconds: 500 * (attempt * attempt)));
      }
    }
    throw Exception('Unreachable code');
  }

  // Fetch fee types for a school
  Future<SchoolFeeTypeModel> fetchFeeTypes(String schoolId) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);

      // Check cache
      final cachedFeeTypes = sharedPreferences.getString('feeTypes_$schoolId');
      final cacheTimestamp = sharedPreferences.getInt('feeTypes_timestamp_$schoolId');
      if (cachedFeeTypes != null &&
          cacheTimestamp != null &&
          DateTime.now().millisecondsSinceEpoch - cacheTimestamp < _cacheDuration.inMilliseconds) {
        final jsonData = jsonDecode(cachedFeeTypes);
        return SchoolFeeTypeModel.fromJson(jsonData);
      }

      final response = await _getWithRetry(
        '${dotenv.get('mainUrl')}/api/fee-types/school/$schoolId',
        headers,
      );

      final results = jsonDecode(response.body);
      final feeTypeModel = SchoolFeeTypeModel.fromJson(results);

      if (response.statusCode == 200 && feeTypeModel.success == true) {
        // Cache the response with timestamp
        await sharedPreferences.setString('feeTypes_$schoolId', response.body);
        await sharedPreferences.setInt('feeTypes_timestamp_$schoolId', DateTime.now().millisecondsSinceEpoch);
        debugPrint('Service - Fee types cached successfully');
      } else {
        print('Error fetching fee types: Status ${response.statusCode}, Message: ${results['message']}');
        return SchoolFeeTypeModel(
          status: response.statusCode,
          success: false,
          message: results['message'] ?? 'Failed to fetch fee types',
          data: [],
        );
      }

      return feeTypeModel;
    } catch (e) {
      print('Error fetching fee types: $e');
      return SchoolFeeTypeModel(
        status: 500,
        success: false,
        message: 'Failed to fetch fee types: $e',
        data: [],
      );
    }
  }

  // Fetch fee history for a classroom
  Future<List<ClassroomFeesData>> fetchFeeHistory(String classroomId) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);
      final response = await _getWithRetry(
        '${dotenv.get('mainUrl')}/api/student-fees/classroom/$classroomId/fees',
        headers,
      );

      final results = jsonDecode(response.body);

      if (response.statusCode == 200 && results['success'] == true) {
        final feeHistory = (results['data'] as List?)?.map((item) => ClassroomFeesData.fromJson(item)).toList() ?? [];
        return feeHistory;
      } else if (response.statusCode == 404) {
        // Handle no payment history case
        debugPrint('No fee history found for classroomId: $classroomId');
        return [];
      } else {
        final errorMessage = results['message'] ?? 'Failed to load fee history: ${response.statusCode}';
        debugPrint('Error fetching fee history: $errorMessage, Response: ${response.body}');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Error fetching fee history: $e');
      throw Exception('Failed to fetch fee history: $e');
    }
  }

    


  Future<List<ClassroomFeesData>> fetchSchoolFeeHistory({
    String? classroomId,
    String? academicYear,
    String? status,
    String? feeTypeId,
    String? term,
  }) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);

      // Construct URL with only non-null and non-empty query parameters
      final baseUrl = '${dotenv.get('mainUrl')}/api/student-fees/school/fees';
      final queryParams = <String, String>{};
      if (classroomId != null && classroomId.isNotEmpty) {
        queryParams['classroomId'] = classroomId;
      }
      if (academicYear != null && academicYear.isNotEmpty) {
        queryParams['academicYear'] = academicYear;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (feeTypeId != null && feeTypeId.isNotEmpty) {
        queryParams['feeTypeId'] = feeTypeId;
      }
      if (term != null && term.isNotEmpty) {
        queryParams['term'] = term;
      }

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      debugPrint('Request URL: $uri'); // Log the URL for debugging
      final response = await _getWithRetry(uri.toString(), headers);

      final results = jsonDecode(response.body);

      if (response.statusCode == 200 && results['success'] == true) {
        final feeHistory = (results['data'] as List?)?.map((item) => ClassroomFeesData.fromJson(item)).toList() ?? [];
        return feeHistory;
      } else if (response.statusCode == 404) {
        debugPrint('No fee history found for the given filters');
        return [];
      } else {
        final errorMessage = results['message'] ?? 'Failed to load fee history: ${response.statusCode}';
        debugPrint('Error fetching fee history: $errorMessage, Response: ${response.body}');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Error fetching fee history: $e');
      throw Exception('Failed to fetch fee history: $e');
    }
  }
 

  // Apply a fee (single/multiple students or class-level)
  Future<StudentFeeDTO> applyFee({
    required String classroomId,
    required String feeTypeId,
    required double amount,
    required String dueDate,
    required String academicYear,
    required String term,
    List<String>? studentIds,
    String? singleStudentId,
    bool isClassLevel = false,
    bool notifyParent = true,
  }) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);
      final baseUrl = '${dotenv.get('mainUrl')}/api/student-fees';

      if (isClassLevel) {
        // Class-level fee assignment
        final body = jsonEncode({
          'feeTypeId': feeTypeId,
          'dueDate': dueDate,
          'academicYear': academicYear,
          'term': term,
        });

        final response = await _postWithRetry(
          '$baseUrl/classroom/$classroomId/assign?sendSms=$notifyParent',
          headers,
          body,
        );

        final results = jsonDecode(response.body);
        debugPrint(results.toString());

        if (response.statusCode == 200 && results['success'] == true) {

          showSuccessAlert(results['message'], Get.context!);
          return StudentFeeDTO(
            id: 'class-level-', // Placeholder ID
            studentId: '',
            feeTypeId: feeTypeId,
            amountDue: amount,
            dueDate: dueDate,
            academicYear: academicYear,
            term: term,
            status: 'UNPAID',
          );
        } else {
          throw Exception(results['message'] ?? 'Failed to assign fee to classroom: ${response.statusCode}');
        }
      } else {
        // Single or multiple student fee assignment
        final targetStudentIds = singleStudentId != null ? [singleStudentId] : (studentIds ?? []);
        if (targetStudentIds.isEmpty) {
          throw Exception('No student IDs provided');
        }

        // Assume single student for simplicity; extend for multiple if needed
        final body = jsonEncode({
          'studentId': targetStudentIds.first,
          'feeTypeId': feeTypeId,
          'amountDue': amount,
          'dueDate': dueDate,
          'academicYear': academicYear,
          'term': term,
        });

        final response = await _postWithRetry(
          '$baseUrl/assign?sendSms=$notifyParent',
          headers,
          body,
        );

        final results = jsonDecode(response.body);

        if (response.statusCode == 200 && results['success'] == true) {
          showSuccessAlert(results['message'], Get.context!);
          return StudentFeeDTO.fromJson(results['data']);
        } else {
          throw Exception(results['message'] ?? 'Failed to assign fee: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error applying fee: $e');
      showErrorAlert(e.toString(), Get.context!);
      throw Exception('Failed to apply fee: $e');
    }
  }

  // Record a payment
  Future<PaymentResponseModel> recordPayment({
    required String feeId,
    required double amount,
    required String paymentMethod,
    required String referenceNumber,
    required String receivedBy,
    String? remarks,
  }) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);
      final baseUrl = '${dotenv.get('mainUrl')}/api/student-fees';

      final body = jsonEncode({
        'amount': amount,
        'paymentMethod': paymentMethod,
        'referenceNumber': referenceNumber,
        'receivedBy': receivedBy,
        'remarks': remarks ?? '',
      });

      final response = await _postWithRetry(
        '$baseUrl/$feeId/payments',
        headers,
        body,
      );

      final results = jsonDecode(response.body);

      if (response.statusCode == 200 && results['success'] == true) {
        debugPrint(results.toString());
        return PaymentResponseModel.fromJson(results);
      } else {
        throw Exception(results['message'] ?? 'Failed to record payment: ${response.statusCode}');
      }
    } catch (e) {
      print('Error recording payment: $e');
      throw Exception('Failed to record payment: $e');
    }
  }

  Future<List<ClassroomFeesData>> fetchFeeHistoryOlder(String classroomId) async {
  try {
    if (classroomId.isEmpty) {
      throw Exception('Invalid classroom ID provided');
    }

    final sharedPreferences = await SharedPreferences.getInstance();
    final token = sharedPreferences.getString("token") ?? "";
    final headers = await _setHeaders(token);
    final baseUrl = '${dotenv.get('mainUrl')}/api/student-fees';

    // Check cache
    final cachedFeeHistory = sharedPreferences.getString('feeHistory_$classroomId');
    final cacheTimestamp = sharedPreferences.getInt('feeHistory_timestamp_$classroomId');
    if (cachedFeeHistory != null &&
        cacheTimestamp != null &&
        DateTime.now().millisecondsSinceEpoch - cacheTimestamp < _cacheDuration.inMilliseconds) {
      final jsonData = jsonDecode(cachedFeeHistory);
      return (jsonData as List).map((item) => ClassroomFeesData.fromJson(item)).toList();
    }

    final response = await _getWithRetry(
      '$baseUrl/classroom/$classroomId/fees',
      headers,
    );

    final results = jsonDecode(response.body);

    if (response.statusCode == 200 && results['success'] == true) {
      final feeHistory = (results['data'] as List?)?.map((item) => ClassroomFeesData.fromJson(item)).toList() ?? [];
      // Cache the response with timestamp
      await sharedPreferences.setString('feeHistory_$classroomId', jsonEncode(results['data'] ?? []));
      await sharedPreferences.setInt('feeHistory_timestamp_$classroomId', DateTime.now().millisecondsSinceEpoch);
      return feeHistory;
    } else if (response.statusCode == 404) {
      // Handle no payment history case
      debugPrint('No fee history found for classroomId: $classroomId');
      await sharedPreferences.setString('feeHistory_$classroomId', jsonEncode([]));
      await sharedPreferences.setInt('feeHistory_timestamp_$classroomId', DateTime.now().millisecondsSinceEpoch);
      return [];
    } else {
      final errorMessage = results['message'] ?? 'Failed to load fee history: ${response.statusCode}';
      debugPrint('Error fetching fee history: $errorMessage, Response: ${response.body}');
      throw Exception(errorMessage);
    }
  } catch (e) {
    debugPrint('Error fetching fee history: $e');
    throw Exception('Failed to fetch fee history: $e');
  }
}

  // Fetch fees for a student
  Future<List<StudentFeeDTO>> fetchStudentFees(String studentId) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);
      final baseUrl = '${dotenv.get('mainUrl')}/api/student-fees';

      final response = await _getWithRetry(
        '$baseUrl/student/$studentId',
        headers,
      );

      final results = jsonDecode(response.body);

      if (response.statusCode == 200 && results['success'] == true && results['data'] != null) {
        return (results['data'] as List).map((item) => StudentFeeDTO.fromJson(item)).toList();
      } else {
        throw Exception(results['message'] ?? 'Failed to load student fees: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching student fees: $e');
      throw Exception('Failed to fetch student fees: $e');
    }
  }

  Future<void> notifyStudentFeeToParent(String studentId, {bool sendSMS = true}) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);
      final baseUrl = '${dotenv.get('mainUrl')}/api/student-fees';


      final response = await _postWithRetry(
        '$baseUrl/notify-overdue/student/$studentId?sendSms=$sendSMS',
        headers,
        '',
      );

      final results = jsonDecode(response.body);

      if (response.statusCode == 200 && results['success'] == true) {
        showSuccessAlert(results['message'] ?? 'Fee notification sent successfully', Get.context!);
        return;
      } else {
        showErrorAlert(results['message'] ?? 'Failed to notify student fee to parent: ${response.statusCode}', Get.context!);
        throw Exception(results['message'] ?? 'Failed to notify student fee to parent: ${response.statusCode}');
      }
    } catch (e) {
      print('Error notifying student fee to parent: $e');
      throw Exception('Failed to notify student fee to parent: $e');
    }
  }

// Updated searchStudents method
  Future<StudentModel> searchStudents(String query) async {
    try {
      if (query.trim().isEmpty) {
        return StudentModel(
          status: 400,
          success: false,
          message: 'Search query cannot be empty',
          data: [],
        );
      }

      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      // final schoolId = sharedPreferences.getString("schoolId") ?? "";
      if (token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      // Generate a cache key based on query and schoolId
      final cacheKey = 'search_students_${query.hashCode}';
      final cachedResults = sharedPreferences.getString(cacheKey);
      final cacheTimestamp = sharedPreferences.getInt('${cacheKey}_timestamp');
      if (cachedResults != null &&
          cacheTimestamp != null &&
          DateTime.now().millisecondsSinceEpoch - cacheTimestamp < _cacheDuration.inMilliseconds) {
        final jsonData = jsonDecode(cachedResults);
        return StudentModel.fromJson(jsonData);
      }

      final headers = await _setHeaders(token);
      final response = await _getWithRetry(
        '${dotenv.get('mainUrl')}/api/students/search?query=${Uri.encodeQueryComponent(query)}',
        headers,
      );

      final results = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 204) {
        final studentModel = StudentModel.fromJson(results);
        // Cache the response
        await sharedPreferences.setString(cacheKey, response.body);
        await sharedPreferences.setInt('${cacheKey}_timestamp', DateTime.now().millisecondsSinceEpoch);
        debugPrint('Service - Students cached successfully for query: $query');
        return studentModel;
      } else if (response.statusCode == 400) {
        return StudentModel(
          status: 400,
          success: false,
          message: results['message'] ?? 'Invalid search query',
          data: [],
        );
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid token');
      } else {
        throw Exception(results['message'] ?? 'Failed to search students: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching students: $e');
      return StudentModel(
        status: 500,
        success: false,
        message: 'Failed to search students: $e',
        data: [],
      );
    }
  }


    Future<List<SchoolData>> fetchSchools() async {
      try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);

       final response = await _getWithRetry(
        '${dotenv.get('mainUrl')}/api/schools',
        headers,
      );
      final results = jsonDecode(response.body);

      if (response.statusCode == 200 && results['success'] == true) {
        final schools = (results['data'] as List?)?.map((item) => SchoolData.fromJson(item)).toList() ?? [];
        return schools;
      } else if (response.statusCode == 404) {
        // Handle no payment history case
        debugPrint('No school found');
        return [];
      } else {
        final errorMessage = results['message'] ?? 'Failed to load school: ${response.statusCode}';
        debugPrint('Error fetching school: $errorMessage, Response: ${response.body}');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Error fetching school: $e');
      throw Exception('Failed to fetch school: $e');
    }
  }

  Future<RecordSchoolModel> addSchool(SchoolData schoolData) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);

      debugPrint(jsonEncode(schoolData));

      final response = await _postWithRetry(
        '${dotenv.get('mainUrl')}/api/schools',
        headers,
        jsonEncode({
          'name': schoolData.name,
          'phone': schoolData.phone,
          'email': schoolData.email,
          'logo': schoolData.logo,
          'status': schoolData.status,
          'slogan': schoolData.slogan,
        }),
      );

      final results = jsonDecode(response.body);

      if (response.statusCode == 201  && results['success'] == true) {
        return RecordSchoolModel.fromJson(results);
      } else {
        throw Exception(results['message'] ?? 'Failed to add school: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error adding school: $e');
      throw Exception('Failed to add school: $e');
    }
  }
  Future<RecordSchoolModel> updateSchool(
    {required String id,
    String? name,
    String? phone,
    String? email,
    String? logo,
    String? status,
    String? slogan}
  ) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);

      final response = await _putWithRetry(
        '${dotenv.get('mainUrl')}/api/schools/$id',
        headers,
        jsonEncode({
          'name': name,
          'phone': phone,
          'email': email,
          'logo': logo,
          'status': status,
          'slogan': slogan,
        }),
      );

      final results = jsonDecode(response.body);

      if (response.statusCode == 200 && results['success'] == true) {
        return RecordSchoolModel.fromJson(results);
      } else {
        throw Exception(results['message'] ?? 'Failed to update school: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating school: $e');
      throw Exception('Failed to update school: $e');
    }
  }
  Future<RecordSchoolModel> deleteSchool(String id) async {
    try {
      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);

      final response = await _deleteWithRetry(
        '${dotenv.get('mainUrl')}/api/schools/$id',
        headers,
      );

      final results = jsonDecode(response.body);

      if (response.statusCode == 200 && results['success'] == true) {
        return RecordSchoolModel.fromJson(results);
      } else {
        throw Exception(results['message'] ?? 'Failed to delete school: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting school: $e');
      throw Exception('Failed to delete school: $e');
    }
  }

}
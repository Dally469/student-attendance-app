// ignore_for_file: depend_on_referenced_packages, no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'dart:io';

import 'package:attendance/models/single.student.model.dart';
import 'package:attendance/models/student.model.dart';
import 'package:attendance/models/user.login.model.dart';
import 'package:attendance/models/parent.lookup.model.dart';
import 'package:flutter/cupertino.dart';

import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/attendance.dart';
import '../models/classroom.model.dart';
import '../constants/api_endpoints.dart';

class AuthService {
  // Fetch students by parent phone number or student registration number (public endpoint)
  Future<ParentLookupModel> fetchStudentsByParent(String query) async {
    Map<String, String> headers = {'Content-Type': 'application/json'};
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    final uri = Uri.parse(ApiEndpoints.studentsSearchByPhoneOrCode)
        .replace(queryParameters: {'query': query});

    debugPrint('=== GET Parent Student Lookup Request ===');
    debugPrint('URL: $uri');
    debugPrint('Headers: $headers');
    debugPrint('Query: $query');

    try {
      var response = await http.get(uri, headers: headers);

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('======================================');

      Map<String, dynamic> results = jsonDecode(response.body);

      // Handle both 200 (success with data) and 204 (success but no data)
      if (response.statusCode == 200 || response.statusCode == 204) {
        ParentLookupModel model = ParentLookupModel.fromJson(results);

        // Store the token if available
        if (model.data?.token != null && model.data!.token!.isNotEmpty) {
          sharedPreferences.setString('parentToken', model.data!.token!);
          sharedPreferences.setString(
              'parentTokenExpiresIn', model.data!.expiresIn ?? '7 days');
          debugPrint('Parent token stored: ${model.data!.token}');
        }

        return model;
      } else {
        // Return error model
        return ParentLookupModel(
          status: response.statusCode,
          success: false,
          message: results['message'] ?? 'Failed to fetch student information',
          data: null,
        );
      }
    } catch (e) {
      debugPrint('Error fetching students by parent: $e');
      return ParentLookupModel(
        status: 500,
        success: false,
        message: 'An error occurred: $e',
        data: null,
      );
    }
  }

  Future<UserLoginModel> postClientLogin(
      String username, String password) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    Map<String, String> headers = {'Content-Type': 'application/json'};

    final url = ApiEndpoints.login;
    final requestBody = {
      'username': username,
      'password': '***'
    }; // Hide password in logs

    debugPrint('=== POST Login Request ===');
    debugPrint('URL: $url');
    debugPrint('Headers: $headers');
    debugPrint('Body: ${json.encode(requestBody)}');

    var response = await http.post(Uri.parse(url),
        headers: headers,
        body: json.encode({
          'username': username.toString(),
          'password': password.toString()
        }));

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    debugPrint('=========================');

    Map<String, dynamic> results = jsonDecode(response.body);
    if (response.statusCode == 200) {
      UserLoginModel model = UserLoginModel.fromJson(results);
      sharedPreferences.setString('currentUser', jsonEncode(model.data));
      sharedPreferences.setString(
          'currentSchool', jsonEncode(model.data?.school));
      sharedPreferences.setString('token', jsonEncode(model.token));
      sharedPreferences.setString('role', jsonEncode(model.data?.role));

      return model;
    } else if (response.statusCode == 400) {
      UserLoginModel model = UserLoginModel.fromJson(results);
      return model;
    } else {
      UserLoginModel model = UserLoginModel.fromJson(results);
      return model;
    }
  }

  Future<UserLoginModel> postParentLogin(
      String username, String password) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    Map<String, String> headers = {'Content-Type': 'application/json'};

    // Try parent login endpoint first, fallback to regular login if not available
    final url = ApiEndpoints.parentLogin;
    final requestBody = {
      'username': username,
      'password': '***'
    }; // Hide password in logs

    debugPrint('=== POST Parent Login Request ===');
    debugPrint('URL: $url');
    debugPrint('Headers: $headers');
    debugPrint('Body: ${json.encode(requestBody)}');

    try {
      var response = await http.post(Uri.parse(url),
          headers: headers,
          body: json.encode({
            'username': username.toString(),
            'password': password.toString()
          }));

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('===============================');

      Map<String, dynamic> results = jsonDecode(response.body);
      if (response.statusCode == 200) {
        UserLoginModel model = UserLoginModel.fromJson(results);
        sharedPreferences.setString('currentUser', jsonEncode(model.data));
        sharedPreferences.setString(
            'currentSchool', jsonEncode(model.data?.school));
        sharedPreferences.setString('token', jsonEncode(model.token));
        sharedPreferences.setString('role', jsonEncode(model.data?.role));

        return model;
      } else if (response.statusCode == 400) {
        UserLoginModel model = UserLoginModel.fromJson(results);
        return model;
      } else {
        // If parent endpoint doesn't exist (404) or other error, try regular login endpoint
        // (backend might handle parent login through the same endpoint)
        debugPrint(
            'Parent endpoint not available, falling back to regular login');
        return postClientLogin(username, password);
      }
    } catch (e) {
      // If parent endpoint doesn't exist or other error, try regular login endpoint
      debugPrint(
          'Error with parent login endpoint: $e, falling back to regular login');
      return postClientLogin(username, password);
    }
  }

  Future<SchoolClassroomModel> fetchSchoolClassrooms(String token) async {
    var newToken = token.replaceAll('"', "");
    _setHeaders() => {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': newToken
        };

    try {
      final url = ApiEndpoints.classrooms;

      debugPrint('=== GET Classrooms Request ===');
      debugPrint('URL: $url');
      debugPrint('Headers: ${_setHeaders()}');

      final response = await http.get(
        Uri.parse(url),
        headers: _setHeaders(),
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('==============================');

      final Map<String, dynamic> results = jsonDecode(response.body);

      // Always parse the response into the model regardless of status code
      // The success/failure is handled by checking the 'success' field in the model
      return SchoolClassroomModel.fromJson(results);
    } catch (e) {
      // Handle network or parsing errors
      print("Error fetching classrooms: $e");
      // Return a model with error information
      return SchoolClassroomModel(
        status: 500,
        success: false,
        message: "Failed to fetch classrooms: $e",
        data: null,
      );
    }
  }

  Future<StudentModel> fetchStudents(String classroom) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String token = sharedPreferences.getString("token") ?? "";

    var newToken = token.replaceAll('"', "");
    _setHeaders() => {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': newToken
        };

    final url = ApiEndpoints.studentsFilterByClassroom;
    final requestBody = {'classroom': classroom.toString()};

    debugPrint('=== POST Filter Students Request ===');
    debugPrint('URL: $url');
    debugPrint('Headers: ${_setHeaders()}');
    debugPrint('Body: ${json.encode(requestBody)}');

    var response = await http.post(Uri.parse(url),
        headers: _setHeaders(), body: json.encode(requestBody));

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    debugPrint('====================================');

    Map<String, dynamic> results = jsonDecode(response.body);

    if (response.statusCode == 200) {
      StudentModel schoolClassroomModel = StudentModel.fromJson(results);
      await saveDataToFile(classroom, results);

      return schoolClassroomModel;
    } else if (response.statusCode == 400) {
      StudentModel schoolClassroomModel = StudentModel.fromJson(results);
      return schoolClassroomModel;
    } else {
      StudentModel schoolClassroomModel = StudentModel.fromJson(results);
      return schoolClassroomModel;
    }
  }

  Future<void> saveDataToFile(
      String classroom, Map<String, dynamic> data) async {
    try {
      // Get the app's document directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$classroom.json';

      // Convert the data to JSON format and write it to the file
      File file = File(filePath);
      await file.writeAsString(jsonEncode(data));

      print('Data saved to file: $filePath');
    } catch (e) {
      print('Error saving data to file: $e');
    }
  }

  Future<SingleStudentModel> assignCardToStudents(
      String studentId, String cardId) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String token = sharedPreferences.getString("token") ?? "";

    var newToken = token.replaceAll('"', "");
    _setHeaders() => {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': newToken
        };
    final url = ApiEndpoints.assignCard(studentId);
    final requestBody = {'cardId': cardId.toString()};

    debugPrint('=== POST Assign Card Request ===');
    debugPrint('URL: $url');
    debugPrint('Headers: ${_setHeaders()}');
    debugPrint('Body: ${json.encode(requestBody)}');

    var response = await http.post(Uri.parse(url),
        headers: _setHeaders(), body: json.encode(requestBody));

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    debugPrint('================================');

    Map<String, dynamic> results = jsonDecode(response.body);

    if (response.statusCode == 200) {
      SingleStudentModel schoolClassroomModel =
          SingleStudentModel.fromJson(results);

      return schoolClassroomModel;
    } else if (response.statusCode == 400) {
      SingleStudentModel schoolClassroomModel =
          SingleStudentModel.fromJson(results);
      return schoolClassroomModel;
    } else {
      SingleStudentModel schoolClassroomModel =
          SingleStudentModel.fromJson(results);
      return schoolClassroomModel;
    }
  }

  Future<AttendanceModel> createAttendance(
    String classroomId, {
    required String mode,
    required String deviceType,
    required String schoolId,
  }) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? token = sharedPreferences.getString("token") ?? "";

    var newToken = token.replaceAll('"', "");
    _setHeaders() => {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': newToken
        };

    // Prepare request body
    final requestBody = {
      'mode': mode,
      'deviceType': deviceType,
      'schoolId': schoolId,
    };

    final url = ApiEndpoints.createAttendance(classroomId);

    debugPrint('=== POST Create Attendance Request ===');
    debugPrint('URL: $url');
    debugPrint('Headers: ${_setHeaders()}');
    debugPrint('Body: ${json.encode(requestBody)}');

    var response = await http.post(
      Uri.parse(url),
      headers: _setHeaders(),
      body: json.encode(requestBody),
    );

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    debugPrint('======================================');

    Map<String, dynamic> results = jsonDecode(response.body);

    // Parse the response using the updated model structure
    AttendanceModel attendanceModel = AttendanceModel.fromJson(results);

    // Set success status based on HTTP status code if not already set
    if (attendanceModel.success == null) {
      attendanceModel.success =
          response.statusCode >= 200 && response.statusCode < 300;
    }

    return attendanceModel;
  }

  // Pay student fee via MoPay (for parents)
  Future<Map<String, dynamic>> payStudentFee({
    required String feeId,
    required String studentCode,
    required String payerPhone,
    required double amount,
  }) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? parentToken = sharedPreferences.getString('parentToken');

    if (parentToken == null || parentToken.isEmpty) {
      return {
        'success': false,
        'message': 'Authentication token not found',
        'data': null,
      };
    }

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': parentToken.replaceAll('"', ''),
    };

    final url = ApiEndpoints.payStudentFee;

    // Format phone number to 12 digits (remove non-digits, ensure country code)
    String formattedPhone = payerPhone.replaceAll(RegExp(r'[^\d]'), '');

    // If phone starts with 0, replace with 250 (Rwanda country code)
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '250${formattedPhone.substring(1)}';
    }
    // If phone doesn't start with 250, add it
    else if (!formattedPhone.startsWith('250')) {
      formattedPhone = '250$formattedPhone';
    }

    // Ensure it's exactly 12 digits
    if (formattedPhone.length != 12) {
      return {
        'success': false,
        'message': 'Invalid phone number format. Phone must be 12 digits.',
        'data': null,
      };
    }

    final requestBody = {
      'feeId': feeId,
      'studentCode': studentCode,
      'payerPhone': formattedPhone,
      'amount': amount,
    };

    debugPrint('=== POST Pay Student Fee Request ===');
    debugPrint('URL: $url');
    debugPrint('Headers: $headers');
    debugPrint('Body: ${json.encode(requestBody)}');

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(requestBody),
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('===================================');

      Map<String, dynamic> results = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': results,
          'message': results['message'] ?? 'Payment initiated successfully',
        };
      } else {
        return {
          'success': false,
          'message': results['message'] ?? 'Payment failed',
          'data': results,
        };
      }
    } catch (e) {
      debugPrint('Error paying student fee: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
        'data': null,
      };
    }
  }

  // Check payment status
  Future<Map<String, dynamic>> checkPaymentStatus(String transactionId) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? parentToken = sharedPreferences.getString('parentToken');

    if (parentToken == null || parentToken.isEmpty) {
      return {
        'success': false,
        'message': 'Authentication token not found',
        'data': null,
      };
    }

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': parentToken.replaceAll('"', ''),
    };

    final url = ApiEndpoints.checkPaymentStatus(transactionId);

    debugPrint('=== GET Payment Status Request ===');
    debugPrint('URL: $url');
    debugPrint('Headers: $headers');

    try {
      var response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('===================================');

      Map<String, dynamic> results = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': results,
          'message': results['message'] ?? 'Payment status retrieved',
        };
      } else {
        return {
          'success': false,
          'message': results['message'] ?? 'Failed to check payment status',
          'data': results,
        };
      }
    } catch (e) {
      debugPrint('Error checking payment status: $e');
      return {
        'success': false,
        'message': 'An error occurred: $e',
        'data': null,
      };
    }
  }
}

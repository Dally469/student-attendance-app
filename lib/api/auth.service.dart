// ignore_for_file: depend_on_referenced_packages, no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'dart:io';

import 'package:attendance/models/single.student.model.dart';
import 'package:attendance/models/student.model.dart';
import 'package:attendance/models/user.login.model.dart';
import 'package:flutter/cupertino.dart';

import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/attendance.dart';
import '../models/classroom.model.dart';

class AuthService {
  Future<UserLoginModel> postClientLogin(
      String username, String password) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    Map<String, String> headers = {'Content-Type': 'application/json'};
    
    final url = '${dotenv.get('mainUrl')}/auth/login';
    final requestBody = {'username': username, 'password': '***'}; // Hide password in logs
    
    debugPrint('=== POST Login Request ===');
    debugPrint('URL: $url');
    debugPrint('Headers: $headers');
    debugPrint('Body: ${json.encode(requestBody)}');
    
    var response = await http.post(
        Uri.parse(url),
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
      sharedPreferences.setString('currentSchool', jsonEncode(model.data?.school));
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

    
Future<SchoolClassroomModel> fetchSchoolClassrooms(String token) async {

  var newToken = token.replaceAll('"', "");
    _setHeaders() => {
          'Content-type': 'application/json',
          'Accept': 'application/json',
          'Authorization': newToken
        };

    try {
      final url = '${dotenv.get('mainUrl')}/api/classrooms';
      
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

    final url = '${dotenv.get('mainUrl')}/api/students/filter/classroom';
    final requestBody = {'classroom': classroom.toString()};
    
    debugPrint('=== POST Filter Students Request ===');
    debugPrint('URL: $url');
    debugPrint('Headers: ${_setHeaders()}');
    debugPrint('Body: ${json.encode(requestBody)}');
    
    var response = await http.post(
        Uri.parse(url),
        headers: _setHeaders(),
        body: json.encode(requestBody));

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
    final url = '${dotenv.get('mainUrl')}/api/students/$studentId/assign-card';
    final requestBody = {'cardId': cardId.toString()};
    
    debugPrint('=== POST Assign Card Request ===');
    debugPrint('URL: $url');
    debugPrint('Headers: ${_setHeaders()}');
    debugPrint('Body: ${json.encode(requestBody)}');
    
    var response = await http.post(
        Uri.parse(url),
        headers: _setHeaders(),
        body: json.encode(requestBody));

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
    
    final url = '${dotenv.get('mainUrl')}/api/attendance/classroom/$classroomId';
    
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
      attendanceModel.success = response.statusCode >= 200 && response.statusCode < 300;
    }
    
    return attendanceModel;
  }


}

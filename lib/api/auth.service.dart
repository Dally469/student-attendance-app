// ignore_for_file: depend_on_referenced_packages

import 'dart:convert';

import 'package:attendance/models/student.model.dart';
import 'package:attendance/models/user.login.model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/classroom.model.dart';

class AuthService {
  Future<UserLoginModel> postClientLogin(
      String username, String password) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    Map<String, String> headers = {'Content-Type': 'application/json'};
    var response = await http.post(
        Uri.parse('${dotenv.get('mainUrl')}/auth/login'),
        headers: headers,
        body: json.encode({
          'username': username.toString(),
          'password': password.toString()
        }));

    Map<String, dynamic> results = jsonDecode(response.body);
    if (response.statusCode == 200) {
      UserLoginModel model = UserLoginModel.fromJson(results);

      sharedPreferences.setString('currentUser', jsonEncode(model.data));
      sharedPreferences.setString('token', jsonEncode(model.token));

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
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': '${token.toString()}}'
    };

    var response = await http.get(
      Uri.parse('${dotenv.get('mainUrl')}/api/classrooms'),
      headers: headers,
    );

    Map<String, dynamic> results = jsonDecode(response.body);
    if (response.statusCode == 200) {
      SchoolClassroomModel schoolClassroomModel =
          SchoolClassroomModel.fromJson(results);
      return schoolClassroomModel;
    } else if (response.statusCode == 400) {
      SchoolClassroomModel schoolClassroomModel =
          SchoolClassroomModel.fromJson(results);
      return schoolClassroomModel;
    } else {
      SchoolClassroomModel schoolClassroomModel =
          SchoolClassroomModel.fromJson(results);
      return schoolClassroomModel;
    }
  }

  Future<StudentModel> fetchStudents(String classroom) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? token = sharedPreferences.getString("token");

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': '${token.toString()}}'
    };
    var response = await http.post(
        Uri.parse('${dotenv.get('mainUrl')}/api/students/filter/classroom'),
        headers: headers,
        body: json.encode({
          'classroom': classroom.toString(),
        }));

    Map<String, dynamic> results = jsonDecode(response.body);

    if (response.statusCode == 200) {
      StudentModel schoolClassroomModel = StudentModel.fromJson(results);

      return schoolClassroomModel;
    } else if (response.statusCode == 400) {
      StudentModel schoolClassroomModel = StudentModel.fromJson(results);
      return schoolClassroomModel;
    } else {
      StudentModel schoolClassroomModel = StudentModel.fromJson(results);
      return schoolClassroomModel;
    }
  }
  Future<StudentModel> assignCardToStudents(String studentCode, String cardId) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? token = sharedPreferences.getString("token");

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': '${token.toString()}}'
    };
    var response = await http.post(
        Uri.parse('${dotenv.get('mainUrl')}/api/students/$studentCode/assign-card'),
        headers: headers,
        body: json.encode({
          'cardId': cardId.toString(),
        }));

    Map<String, dynamic> results = jsonDecode(response.body);
    print(results);

    if (response.statusCode == 200) {
      StudentModel schoolClassroomModel = StudentModel.fromJson(results);

      return schoolClassroomModel;
    } else if (response.statusCode == 400) {
      StudentModel schoolClassroomModel = StudentModel.fromJson(results);
      return schoolClassroomModel;
    } else {
      StudentModel schoolClassroomModel = StudentModel.fromJson(results);
      return schoolClassroomModel;
    }
  }
}

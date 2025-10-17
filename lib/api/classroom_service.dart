import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/classroom.model.dart';

class ClassroomService {
  static const int _timeoutDuration = 10; // Timeout in seconds
  static const int _maxRetries = 2; // Max retry attempts for failed requests

  // Common headers for HTTP requests
  Future<Map<String, String>> _setHeaders(String token) async {
    var newToken = token.replaceAll('"', "");
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': newToken,
    };
  }

  // Generic HTTP GET with retry logic
  Future<http.Response> _getWithRetry(String url, Map<String, String> headers) async {
    int attempt = 0;
    while (attempt < _maxRetries) {
      try {
        debugPrint('=== GET Request (Attempt ${attempt + 1}/$_maxRetries) ===');
        debugPrint('URL: $url');
        debugPrint('Headers: $headers');
        
        final response = await http
            .get(Uri.parse(url), headers: headers)
            .timeout(Duration(seconds: _timeoutDuration));
        
        debugPrint('Response Status: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        debugPrint('========================================');
        
        return response;
      } catch (e) {
        attempt++;
        debugPrint('Request failed (Attempt $attempt/$_maxRetries): $e');
        if (attempt == _maxRetries) {
          debugPrint('Max retries reached. Request failed.');
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
    throw Exception('Request failed after $_maxRetries attempts');
  }

  // Fetch school classrooms
  Future<SchoolClassroomModel> fetchSchoolClassrooms() async {
    try {
        SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      String token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);
      // Check cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedClassrooms = prefs.getString('classrooms');
      if (cachedClassrooms != null) {
        final jsonData = jsonDecode(cachedClassrooms);
        return SchoolClassroomModel.fromJson(jsonData);
      }

      final response = await _getWithRetry(
        '${dotenv.get('mainUrl')}/api/classrooms?page=0&size=50',
        headers,
      );

      final Map<String, dynamic> results = jsonDecode(response.body);
      debugPrint("Classrooms: ${results['data'].toString()}");
      final classroomModel = SchoolClassroomModel.fromJson(results);
      debugPrint("Classroom Model: ${classroomModel.data?.classrooms?.length}");

      if (response.statusCode == 200 && classroomModel.success == true) {
        // Cache the response
        await prefs.setString('classrooms', jsonEncode(results));
      }

      return classroomModel;
    } catch (e) {
      print("Error fetching classrooms: $e");
      return SchoolClassroomModel(
        status: 500,
        success: false,
        message: "Failed to fetch classrooms: $e",
        data: null,
      );
    }
  }
}
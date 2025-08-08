import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ParentCommunicationController extends GetxController {
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  RxString successMessage = ''.obs;
  RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> recipients = <Map<String, dynamic>>[].obs;

  Future<void> fetchRecipients(String classroomId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('YOUR_API_ENDPOINT/classrooms/$classroomId/recipients'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        recipients.value = List<Map<String, dynamic>>.from(data['recipients']);
        successMessage.value = 'Recipients loaded successfully';
      } else {
        errorMessage.value = 'Failed to load recipients: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Error loading recipients: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendCommunication({
    required String classroomId,
    required String message,
    required List<String> recipientIds,
    String? studentId,
    bool isClassLevel = false,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      // Fetch student name if studentId is provided
      String finalMessage = message;
      if (studentId != null) {
        final studentResponse = await http.get(
          Uri.parse('YOUR_API_ENDPOINT/students/$studentId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (studentResponse.statusCode == 200) {
          final studentData = jsonDecode(studentResponse.body);
          String studentName = studentData['name'] ?? 'Student';
          finalMessage = message.replaceAll('{{student_name}}', studentName);
        } else {
          // Fallback if student name can't be fetched
          finalMessage = message.replaceAll('{{student_name}}', 'Student');
        }
      }

      final response = await http.post(
        Uri.parse('YOUR_API_ENDPOINT/communications'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'classroomId': classroomId,
          'message': finalMessage,
          'recipientIds': recipientIds,
          'studentId': studentId,
          'isClassLevel': isClassLevel,
        }),
      );

      if (response.statusCode == 201) {
        successMessage.value = 'Message sent successfully';
        messages.add(jsonDecode(response.body));
      } else {
        errorMessage.value = 'Failed to send message: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Error sending message: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchCommunicationHistory(String classroomId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('YOUR_API_ENDPOINT/communications/$classroomId/history'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        messages.value = List<Map<String, dynamic>>.from(jsonDecode(response.body)['messages']);
        successMessage.value = 'Communication history loaded successfully';
      } else {
        errorMessage.value = 'Failed to load history: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage.value = 'Error loading history: $e';
    } finally {
      isLoading.value = false;
    }
  }
}
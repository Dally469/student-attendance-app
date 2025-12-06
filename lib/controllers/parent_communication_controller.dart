import 'package:attendance/controllers/sms.controller.dart';
import 'package:attendance/models/student.model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// Firebase removed - will use another solution later
// import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../models/sms.transaction.dart';
import '../routes/routes.names.dart';
import '../utils/notifiers.dart';
// Import your SMS controller

// Recipient model for sendBulkSms and sendBulkWhatsApp APIs
class Recipient {
  final String phone;
  final String message;

  Recipient({required this.phone, required this.message});

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'message': message,
      };
}

class WhatsappRecipient {
  final String message;
  final String phoneNumbers;

  WhatsappRecipient({required this.message, required this.phoneNumbers});

  Map<String, dynamic> toJson() =>
      {'message': message, 'phoneNumbers': phoneNumbers};
}

class ParentCommunicationController extends GetxController {
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  RxString successMessage = ''.obs;
  RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> recipients = <Map<String, dynamic>>[].obs;

  // Get SMS controller instance
  final SMSController smsController = Get.put<SMSController>(SMSController() , permanent: true);

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

  // Check if SMS balance is sufficient
  bool _checkSMSBalance(int totalRecipients) {
    if (smsController.smsBalance.value < totalRecipients) {
      errorMessage.value = 
          'Insufficient SMS balance. Need $totalRecipients credits, but you have ${smsController.smsBalance.value.toInt()} credits available.';
      showErrorAlert(errorMessage.value, Get.context!);
      return false;
    }
    return true;
  }

  // Deduct SMS balance after successful sending
  void _deductSMSBalance(int sentCount) {
    smsController.smsBalance.value -= sentCount;
    
    // Add transaction to history
    smsController.smsHistory.insert(0, SMSTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      transactionType: 'usage',
      amount: -sentCount.toDouble(),
      previousBalance: smsController.smsBalance.value,
      newBalance: smsController.smsBalance.value - sentCount,
      description: 'SMS sent to $sentCount recipients',
      createdAt: DateTime.now().toIso8601String(),
      status: 'completed',
    ));
  }

  // Upload file to Firebase Storage and return the download URL
  // Firebase removed - will use another solution later
  Future<String?> uploadFileToFirebase(File file, String fileName) async {
    // TODO: Implement alternative file upload solution
    errorMessage.value = 'File upload not available - Firebase removed. Will implement alternative solution.';
    return null;
    // try {
    //   isLoading.value = true;
    //   final storageRef = FirebaseStorage.instance
    //       .ref()
    //       .child('uploads/${DateTime.now().millisecondsSinceEpoch}_$fileName');
    //   final uploadTask = await storageRef.putFile(file);
    //   final downloadUrl = await uploadTask.ref.getDownloadURL();
    //   return downloadUrl;
    // } catch (e) {
    //   errorMessage.value = 'Error uploading file to Firebase: $e';
    //   return null;
    // } finally {
    //   isLoading.value = false;
    // }
  }

  // Modified SMS functionality with balance check
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

      // Check SMS balance before sending
      if (!_checkSMSBalance(recipients.length)) {
        return false;
      }

      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);
      final baseUrl = '${dotenv.get('mainUrl')}/api/students';

      final data = {
        'sender_id': "swiftqom",
        'recipients': recipients.map((r) => r.toJson()).toList(),
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
        // Deduct SMS balance after successful sending
        _deductSMSBalance(recipients.length);
        
        showSuccessAlert(
            results['message'] ?? 'SMS notification sent successfully',
            Get.context!);
        Get.toNamed(home);
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

  // Show SMS balance confirmation dialog before sending
  Future<bool> showSMSBalanceConfirmation(int recipientCount) async {
    bool? confirmed = await Get.dialog<bool>(
      CupertinoAlertDialog(
        title: const Text('SMS Balance Confirmation'),
        content: Text(
          'You are about to send SMS to $recipientCount recipients.\n\n'
          'Current SMS Balance: ${smsController.smsBalance.value.toInt()}\n'
          'Required Credits: $recipientCount\n'
          'Remaining After Send: ${(smsController.smsBalance.value - recipientCount).toInt()}\n\n'
          'Do you want to proceed?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Get.back(result: false),
          ),
          CupertinoDialogAction(
            child: const Text('Send SMS'),
            onPressed: () => Get.back(result: true),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  // Enhanced sendBulkSms with confirmation dialog
  Future<bool> sendBulkSmsWithConfirmation({
    required String classroomId,
    required String message,
    required List<StudentData> students,
  }) async {
    // Prepare recipients first to get count
    final validRecipients = students
        .where((student) => (student.parentContact ?? '').isNotEmpty)
        .toList();

    if (validRecipients.isEmpty) {
      errorMessage.value = 'No valid parent contacts found';
      showErrorAlert(errorMessage.value, Get.context!);
      return false;
    }

    // Check balance
    if (!_checkSMSBalance(validRecipients.length)) {
      return false;
    }

    // Show confirmation dialog
    bool confirmed = await showSMSBalanceConfirmation(validRecipients.length);
    if (!confirmed) {
      return false;
    }

    // Proceed with sending
    return await sendBulkSms(
      classroomId: classroomId,
      message: message,
      students: students,
    );
  }

  // WhatsApp functionality remains unchanged
  Future<bool> sendBulkWhatsApp({
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
            return WhatsappRecipient(
              message: finalMessage,
              phoneNumbers: student.parentContact ?? '',
            );
          })
          .where((recipient) => recipient.phoneNumbers.isNotEmpty)
          .toList();

      if (recipients.isEmpty) {
        errorMessage.value = 'No valid parent contacts found';
        return false;
      }

      bool allSuccessful = true;
      // Send messages one by one to ensure each customized message is sent
      for (var recipient in recipients) {
        final success = await sendWhatsApp(
          message: recipient.message,
          phones: [recipient.phoneNumbers],
        );
        if (!success) {
          allSuccessful = false;
        }
      }

      if (allSuccessful) {
        showSuccessAlert(
            'WhatsApp messages sent successfully to all recipients',
            Get.context!);
        Get.toNamed(home);
        return true;
      } else {
        showErrorAlert('Some WhatsApp messages failed to send', Get.context!);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error sending WhatsApp messages: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> sendWhatsApp({
    required String message,
    required List<String> phones,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      debugPrint(jsonEncode(phones));

      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);
      final baseUrl = '${dotenv.get('mainUrl')}/api/sms';

      final data = {
        'message': message,
        'phoneNumbers': phones,
      };

      debugPrint(jsonEncode(data));

      final response = await _postWithRetry(
        '$baseUrl/bulk-json',
        headers,
        jsonEncode(data),
      );

      final results = jsonDecode(response.body);

      if (response.statusCode == 200 && results['success'] == true) {
        successMessage.value =
            results['message'] ?? 'WhatsApp messages sent successfully';
        return true;
      } else {
        errorMessage.value = results['message'] ??
            'Failed to send WhatsApp messages: ${response.statusCode}';
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error sending WhatsApp messages: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // WhatsApp image message functionality
  Future<bool> sendWhatsAppImage({
    required String classroomId,
    required String caption,
    required String imageUrl,
    required List<StudentData> students,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      // Prepare phone numbers
      final phoneNumbers = students
          .map((student) => student.parentContact ?? '')
          .where((phone) => phone.isNotEmpty)
          .toList();

      if (phoneNumbers.isEmpty) {
        errorMessage.value = 'No valid parent contacts found';
        return false;
      }

      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);
      final baseUrl = '${dotenv.get('mainUrl')}/api/sms';

      final data = {
        'caption': caption,
        'image': imageUrl,
        'tel': phoneNumbers,
      };

      debugPrint(jsonEncode(data));

      final response = await _postWithRetry(
        '$baseUrl/send-image',
        headers,
        jsonEncode(data),
      );

      final results = jsonDecode(response.body);

      if (response.statusCode == 200 && results['success'] == true) {
        showSuccessAlert(
            results['message'] ?? 'WhatsApp image sent successfully',
            Get.context!);
        return true;
      } else {
        showErrorAlert(
            results['message'] ??
                'Failed to send WhatsApp image: ${response.statusCode}',
            Get.context!);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error sending WhatsApp image: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // WhatsApp document message functionality
  Future<bool> sendWhatsAppDocument({
    required String classroomId,
    required String caption,
    required String documentUrl,
    required String documentName,
    required List<StudentData> students,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      // Prepare phone numbers
      final phoneNumbers = students
          .map((student) => student.parentContact ?? '')
          .where((phone) => phone.isNotEmpty)
          .toList();

      if (phoneNumbers.isEmpty) {
        errorMessage.value = 'No valid parent contacts found';
        return false;
      }

      final sharedPreferences = await SharedPreferences.getInstance();
      final token = sharedPreferences.getString("token") ?? "";
      final headers = await _setHeaders(token);
      final baseUrl = '${dotenv.get('mainUrl')}/api/sms';

      final data = {
        'caption': caption,
        'name': documentName,
        'doc': documentUrl,
        'tel': phoneNumbers,
      };

      debugPrint(jsonEncode(data));

      final response = await _postWithRetry(
        '$baseUrl/send-document',
        headers,
        jsonEncode(data),
      );

      final results = jsonDecode(response.body);

      if (response.statusCode == 200 && results['success'] == true) {
        showSuccessAlert(
            results['message'] ?? 'WhatsApp document sent successfully',
            Get.context!);
        return true;
      } else {
        showErrorAlert(
            results['message'] ??
                'Failed to send WhatsApp document: ${response.statusCode}',
            Get.context!);
        return false;
      }
    } catch (e) {
      errorMessage.value = 'Error sending WhatsApp document: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
import 'package:attendance/api/sms.service.dart';
import 'package:get/get.dart';
import '../models/sms.transaction.dart';

class SMSController extends GetxController {
  final SMSService _smsService = SMSService();

  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  RxString successMessage = ''.obs;
  RxDouble smsBalance = 0.0.obs;
  RxList<SMSTransaction> smsHistory = <SMSTransaction>[].obs;

  String schoolId = ""; // Set this when initializing the controller

  @override
  void onInit() {
    super.onInit();
    if (schoolId.isNotEmpty) {
      getSMSBalance();
      getSMSHistory();
    }
  }

  // Get current SMS balance from service
  Future<void> getSMSBalance() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final balanceModel = await _smsService.getSMSBalance(schoolId);
      if (balanceModel.success && balanceModel.data != null) {
        smsBalance.value = balanceModel.data!.currentBalance;
      } else {
        errorMessage.value = balanceModel.message ?? 'Failed to fetch balance';
      }
    } catch (e) {
      errorMessage.value = 'Failed to get SMS balance: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Top up SMS balance using service
  Future<void> topUpSMS({
    required double amount,
    required String paymentMethod,
    required String paymentReference,
    String? description,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final result = await _smsService.topUpSMS(
        schoolId: schoolId,
        amount: amount,
        paymentMethod: paymentMethod,
        paymentReference: paymentReference,
        description: description,
      );

      if (result.success && result.data != null) {
        smsBalance.value = result.data!.currentBalance;
        successMessage.value = result.message ?? 'Top-up successful!';
        await getSMSHistory(); // Refresh transaction history
      } else {
        errorMessage.value = result.message ?? 'Top-up failed';
      }
    } catch (e) {
      errorMessage.value = 'Top-up failed: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Get SMS transaction history from service
  Future<void> getSMSHistory({int page = 0, int size = 10}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final historyModel = await _smsService.getSMSTransactionHistory(
        schoolId: schoolId,
        page: page,
        size: size,
      );

      if (historyModel.success && historyModel.data != null) {
        smsHistory.value = historyModel.data!.content;
      } else {
        smsHistory.clear();
        errorMessage.value = historyModel.message ?? 'No transaction history found';
      }
    } catch (e) {
      errorMessage.value = 'Failed to get SMS history: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Send bulk SMS
  Future<void> sendBulkSMS(List<String> recipients, String message) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      if (smsBalance.value < recipients.length) {
        errorMessage.value =
            'Insufficient SMS balance. Need ${recipients.length}, have ${smsBalance.value}';
        return;
      }

      final response = await _smsService.sendBulkSMS(
        schoolId: schoolId,
        recipients: recipients,
        message: message,
      );

      if (response.success) {
        // Deduct from balance and refresh history
        await getSMSBalance();
        await getSMSHistory();
        successMessage.value = response.message ?? 'SMS sent successfully!';
      } else {
        errorMessage.value = response.message ?? 'Failed to send SMS';
      }
    } catch (e) {
      errorMessage.value = 'Failed to send SMS: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Send fee notification SMS to a specific student
  Future<void> sendFeeNotification(String studentId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final response = await _smsService.sendFeeNotificationSMS(
        schoolId: schoolId,
        studentId: studentId,
      );

      if (response.success) {
        await getSMSBalance();
        successMessage.value = response.message ?? 'Fee notification sent!';
      } else {
        errorMessage.value = response.message ?? 'Failed to send notification';
      }
    } catch (e) {
      errorMessage.value = 'Failed to send notification: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Optionally clear cache for this school
  Future<void> clearCache() async {
    await _smsService.clearSMSCache(schoolId);
  }
}

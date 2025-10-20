import 'package:attendance/api/auth.service.dart';
import 'package:attendance/models/single.student.model.dart';
import 'package:get/get.dart';

class AssignStudentCardController extends GetxController {
  final AuthService _authService = AuthService();
  
  // Observable variables
  final RxBool isLoading = false.obs;
  final RxBool isSuccess = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<SingleStudentModel?> studentModel = Rx<SingleStudentModel?>(null);
  final RxString assignedCardId = ''.obs;
  
  // CRITICAL: Reset state when controller is first created
  @override
  void onInit() {
    super.onInit();
    reset();
  }

  // Function to reset the state - ENHANCED
  void reset() {
    isLoading.value = false;
    isSuccess.value = false;
    errorMessage.value = '';
    studentModel.value = null;
    assignedCardId.value = '';
  }
  
  // Function to assign card to student
  Future<void> assignCardToStudent(String studentCode, String cardId) async {
    try {
      // Reset previous state before new operation
      isLoading.value = true;
      errorMessage.value = '';
      isSuccess.value = false;
      
      final result = await _authService.assignCardToStudents(studentCode, cardId);
      
      if (result.success == true) {
        studentModel.value = result;
        assignedCardId.value = cardId;
        isSuccess.value = true;
        
        // Show success message
        Get.snackbar(
          'Success',
          cardId.isEmpty 
              ? 'Card removed successfully' 
              : 'Card assigned successfully',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primaryContainer,
          colorText: Get.theme.colorScheme.onPrimaryContainer,
          duration: const Duration(seconds: 2),
        );
      } else {
        errorMessage.value = result.message ?? 'Failed to assign card';
        isSuccess.value = false;
        
        // Show error message
        Get.snackbar(
          'Error',
          errorMessage.value,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.errorContainer,
          colorText: Get.theme.colorScheme.onErrorContainer,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
      isSuccess.value = false;
      
      // Show error message
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.errorContainer,
        colorText: Get.theme.colorScheme.onErrorContainer,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  // Function to remove card from student
  Future<void> removeCardFromStudent(String studentCode) async {
    // Removing a card is just assigning an empty string or null
    await assignCardToStudent(studentCode, '');
  }
  
  // Check if student has a card assigned
  bool get hasCardAssigned => assignedCardId.value.isNotEmpty;
  
  // Clean up when controller is disposed
  @override
  void onClose() {
    reset();
    super.onClose();
  }
}
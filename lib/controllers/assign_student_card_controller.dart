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

  // Function to reset the state
  void reset() {
    isLoading.value = false;
    isSuccess.value = false;
    errorMessage.value = '';
    studentModel.value = null;
  }

  // Function to assign card to student
  Future<void> assignCardToStudent(String studentCode, String cardId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      isSuccess.value = false;
      
      final result = await _authService.assignCardToStudents(studentCode, cardId);
      
      if (result.success) {
        studentModel.value = result;
        isSuccess.value = true;
      } else {
        errorMessage.value = result.message.toString();
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
    } finally {
      isLoading.value = false;
    }
  }
}

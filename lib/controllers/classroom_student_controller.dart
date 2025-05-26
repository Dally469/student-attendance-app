import 'package:attendance/api/auth.service.dart';
import 'package:attendance/models/student.model.dart';
import 'package:get/get.dart';

class ClassroomStudentController extends GetxController {
  final AuthService _authService = AuthService();
  
  // Observable variables
  final RxBool isLoading = false.obs;
  final RxList<StudentData> students = <StudentData>[].obs;
  final RxString errorMessage = ''.obs;
  
  // Function to fetch students by classroom ID
  Future<void> getStudentsByClassroomId(String classroom) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final result = await _authService.fetchStudents(classroom);
      if (result.success) {
        students.assignAll(result.data ?? []);
      } else {
        errorMessage.value = result.message ?? 'Failed to fetch students';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
    } finally {
      isLoading.value = false;
    }
  }
  
  // Function to get student by card ID
  Future<StudentData?> getStudentByCardId(String classroom, String cardId) async {
    try {
      // First check if we already have the students loaded for this classroom
      if (students.isNotEmpty) {
        final student = students.firstWhereOrNull(
          (student) => student.cardId == cardId
        );
        if (student != null) {
          return student;
        }
      }
      
      // If not found in loaded students, fetch fresh data
      await getStudentsByClassroomId(classroom);
      
      // Search again in the newly fetched data
      final student = students.firstWhereOrNull(
        (student) => student.cardId == cardId
      );
      
      return student;
    } catch (e) {
      print('Error getting student by card ID: $e');
      errorMessage.value = 'Error finding student: $e';
      return null;
    }
  }
  
  // Function to get student by ID
  StudentData? getStudentById(String studentId) {
    try {
      return students.firstWhereOrNull(
        (student) => student.id == studentId
      );
    } catch (e) {
      print('Error getting student by ID: $e');
      return null;
    }
  }
  
  // Function to check if a student exists by card ID
  bool hasStudentWithCardId(String cardId) {
    return students.any((student) => student.cardId == cardId);
  }
  
  // Function to reset the controller
  void reset() {
    isLoading.value = false;
    students.clear();
    errorMessage.value = '';
  }
}
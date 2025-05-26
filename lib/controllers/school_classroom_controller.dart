import 'package:attendance/api/auth.service.dart';
import 'package:attendance/models/classroom.model.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SchoolClassroomController extends GetxController {
  final AuthService _authService = AuthService();
  
  // Observable variables
  final RxBool isLoading = false.obs;
  final RxList<Classroom> classrooms = <Classroom>[].obs;
  final RxString errorMessage = ''.obs;

  // Function to get school classrooms using the stored token
  Future<void> getSchoolClassrooms() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      // Get token from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null) {
        errorMessage.value = 'Authentication token not found';
        isLoading.value = false;
        return;
      }
      
      final result = await _authService.fetchSchoolClassrooms(token);
      
      if (result.success) {
        classrooms.assignAll(result.data ?? []);
      } else {
        errorMessage.value = result.message ?? 'Failed to fetch classrooms';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
    } finally {
      isLoading.value = false;
    }
  }
  
  // Original function (kept for backward compatibility)
  Future<void> fetchSchoolClassrooms(String token) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      
      final result = await _authService.fetchSchoolClassrooms(token);
      
      if (result.success) {
        classrooms.assignAll(result.data ?? []);
      } else {
        errorMessage.value = result.message ?? 'Failed to fetch classrooms';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
    } finally {
      isLoading.value = false;
    }
  }
  
  // Function to reset the controller
  void reset() {
    isLoading.value = false;
    classrooms.clear();
    errorMessage.value = '';
  }
}

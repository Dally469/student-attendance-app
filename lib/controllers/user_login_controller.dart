import 'package:attendance/api/auth.service.dart';
import 'package:attendance/models/user.login.model.dart';
import 'package:attendance/models/parent.lookup.model.dart';
import 'package:attendance/routes/routes.names.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserLoginController extends GetxController {
  final AuthService _authService = AuthService();

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<UserLoginModel?> user = Rx<UserLoginModel?>(null);
  final Rx<ParentLookupModel?> parentStudents = Rx<ParentLookupModel?>(null);

  @override
  void onInit() {
    super.onInit();
    checkAuthStatus();
  }

  // Check if user is already authenticated
  Future<void> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null && token.isNotEmpty) {
        isAuthenticated.value = true;
      }
    } catch (e) {
      print('Error checking auth status: $e');
    }
  }

  // Function to login user
  Future<void> login(String username, String password) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _authService.postClientLogin(username, password);

      if (result.success) {
        user.value = result;
        if (result.data?.role == "ADMIN") {
          Get.offAllNamed(
              schoolsRoute); // Navigate to home page after successful login
        } else {
          Get.offAllNamed(
              '/home'); // Navigate to dashboard page after successful login
        }
      } else {
        errorMessage.value = result.message ?? 'Login failed';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Function to fetch students by parent phone number or student registration number
  Future<void> fetchStudentsByParent(String query) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      parentStudents.value = null;

      final result = await _authService.fetchStudentsByParent(query);

      if (result.success == true &&
          result.data != null &&
          result.data!.students != null &&
          result.data!.students!.isNotEmpty) {
        parentStudents.value = result;
        // Navigate to parent student view screen
        Get.toNamed('/parent-student-view', arguments: {
          'studentsWithFees': result.data!.students!,
          'query': query,
          'token': result.data!.token,
          'expiresIn': result.data!.expiresIn,
        });
      } else {
        errorMessage.value = result.message ??
            'No students found. Please check the registration number or phone number.';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Function to logout
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('currentUser');
      await prefs.remove('currentSchool');
      await prefs.setBool('showHome', false);

      isAuthenticated.value = false;
      user.value = null;
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}

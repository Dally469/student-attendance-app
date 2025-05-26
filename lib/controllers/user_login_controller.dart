import 'package:attendance/api/auth.service.dart';
import 'package:attendance/models/user.login.model.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserLoginController extends GetxController {
  final AuthService _authService = AuthService();
  
  // Observable variables
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<UserLoginModel?> user = Rx<UserLoginModel?>(null);

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
        Get.offAllNamed('/home'); // Navigate to home page after successful login
      } else {
        errorMessage.value = result.message ?? 'Login failed';
        Get.snackbar('Error', errorMessage.value);
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
      Get.snackbar('Error', errorMessage.value);
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

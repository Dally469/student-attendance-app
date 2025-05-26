import 'package:attendance/api/auth.service.dart';
import 'package:attendance/api/attendance.service.dart';
import 'package:get/get.dart';
import '../models/attendance.dart';
import '../models/check_in.dart';

class AttendanceController extends GetxController {
  // Helper method to safely get attendance ID from the nested structure
  String getAttendanceId() {
    if (currentAttendance.value?.data?.id != null) {
      return currentAttendance.value!.data!.id!;
    }
    return attendanceId.value;
  }
  final AttendanceService _attendanceService = AttendanceService();
  final AuthService _authService = AuthService();
  
  // Observable variables
  final RxBool isLoading = false.obs;
  final RxBool isCreatingAttendance = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs; // Added for success messages
  final RxString attendanceId = ''.obs;
  final Rx<AttendanceModel?> currentAttendance = Rx<AttendanceModel?>(null);
  final Rx<CheckInModel?> checkInModel = Rx<CheckInModel?>(null);
  final RxString lastCheckedInStudent = RxString('');
  final RxInt checkInCount = RxInt(0);

  // Function to create attendance
  Future<void> createAttendance(String classroomId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';
      
      // Clear previous attendance data
      currentAttendance.value = null;
      attendanceId.value = '';
      
      final result = await _authService.createAttendance(classroomId);
      
      // Log result for debugging
      print('API Response: $result');
      if (result.data != null) {
        print('Attendance data: ${result.data!.toJson()}');
      }
      
      if (result.success == true && result.data != null) {
        // Store the full response
        currentAttendance.value = result;
        
        // Store the ID in a separate observable for easier access
        if (result.data!.id != null && result.data!.id!.isNotEmpty) {
          attendanceId.value = result.data!.id!;
          print('Setting attendanceId to: ${attendanceId.value}');
        }
        
        // Set success message from API or use default
        successMessage.value = result.message ?? 'Attendance created successfully';
        
        // Wait a moment to ensure UI has updated properly
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Home screen will detect these changes and handle navigation
      } else {
        // Handle error case
        errorMessage.value = result.message ?? 'Failed to create attendance';
        
        // Wait a moment before showing error message
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Just set the error message and don't try to show UI
        // Let the screens handle UI feedback based on these observable values
        print('Error creating attendance: ${errorMessage.value}');
      }
    } catch (e) {
      print('Exception in createAttendance: $e');
      errorMessage.value = 'An error occurred: $e';
      
      // Wait a moment before showing error message
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Just set the error message and don't try to show UI
      // Let the screens handle UI feedback based on these observable values
      print('Error creating attendance: ${errorMessage.value}');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Function to check in a student using their card
  Future<void> checkInStudent({required String studentId, required String classroomId, required String attendanceId}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';
      
      // Reset previous check-in data
      checkInModel.value = null;
      
      // Log the parameters for debugging
      print('Check-in attempt - StudentID: $studentId, ClassroomID: $classroomId, AttendanceID: $attendanceId');
      
      final result = await _attendanceService.checkInStudent(studentId, classroomId, attendanceId);
      
      // Log the result for debugging
      print('Check-in API Response: $result');
      if (result.data != null) {
        print('Check-in data: ${result.data.toString()}');
      }
      
      if (result.success == true) {
        // Store the check-in result
        checkInModel.value = result;
        
        // Set success message from API or use default
        successMessage.value = result.message ?? 'Check-in successful';
        
        // Add a short delay to ensure reactive state is updated
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Just log success and update observables, don't directly update UI
        print('Student check-in successful: ${successMessage.value}');
        lastCheckedInStudent.value = studentId; // Update this observable for UI to react
      } else {
        // Handle error case
        errorMessage.value = result.message ?? 'Failed to check in student';
        
        // Just log error and update observables, don't directly update UI
        print('Student check-in failed: ${errorMessage.value}');
      }
    } catch (e) {
      print('Exception in checkInStudent: $e');
      errorMessage.value = 'An error occurred during check-in: $e';
      
      // Just log error, don't try to show UI
      print('Error during student check-in: ${errorMessage.value}');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Function to sync offline check-ins
  Future<void> syncOfflineCheckIns() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';
      
      final result = await _attendanceService.syncOfflineCheckIns();
      
      if (result) {
        successMessage.value = 'Offline check-ins synced successfully';
      } else {
        errorMessage.value = 'Failed to sync offline check-ins';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Clear attendance data
  void clearAttendanceData() {
    attendanceId.value = '';
    currentAttendance.value = null;
  }

  // Function to get attendance by ID
  // This method would be implemented when the API supports it
  // For now, we'll handle attendance by ID in other ways
  Future<void> getAttendanceById(String attendanceId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';
      
      // Since there is no getAttendanceById in the service yet, 
      // just set a placeholder implementation
      successMessage.value = 'Fetching attendance details';
      
      // Implement when API is available
      
    } catch (e) {
      errorMessage.value = 'An error occurred: $e';
    } finally {
      isLoading.value = false;
    }
  }
  
  // Function to reset the controller
  void reset() {
    isLoading.value = false;
    isCreatingAttendance.value = false;
    errorMessage.value = '';
    successMessage.value = '';
    attendanceId.value = '';
    currentAttendance.value = null;
  }
}

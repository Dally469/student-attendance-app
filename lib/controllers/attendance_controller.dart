import 'dart:convert';
import 'package:attendance/api/auth.service.dart';
import 'package:attendance/api/attendance.service.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/attendance.dart';
import '../models/check_in.dart';

class AttendanceController extends GetxController {
  final AttendanceService _attendanceService = AttendanceService();
  final AuthService _authService = AuthService();
  
  // Observable variables
  final RxBool isLoading = false.obs;
  final RxBool isCreatingAttendance = false.obs;
  final RxBool isCheckingExisting = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;
  final RxString attendanceId = ''.obs;
  final Rx<AttendanceModel?> currentAttendance = Rx<AttendanceModel?>(null);
  final Rx<AttendanceModel?> existingAttendance = Rx<AttendanceModel?>(null);
  final Rx<CheckInModel?> checkInModel = Rx<CheckInModel?>(null);
  final RxString lastCheckedInStudentName = ''.obs;
  final RxString lastCheckedInStudentCode = ''.obs;
  final RxInt checkInCount = RxInt(0);
  final RxSet<String> checkedInStudents = <String>{}.obs;

  // Helper method to safely get attendance ID
  String getAttendanceId() {
    if (currentAttendance.value?.data?.id != null) {
      return currentAttendance.value!.data!.id!;
    }
    if (existingAttendance.value?.data?.id != null) {
      return existingAttendance.value!.data!.id!;
    }
    return attendanceId.value;
  }

  // Load current checked-in students from attendance
  Future<void> loadCurrentAttendanceStudents(String attendanceId) async {
    try {
      isLoading.value = true;
      final attendance = await _attendanceService.getAttendanceById(attendanceId);
      if (attendance.success == true && attendance.data != null) {
        // Assuming attendance.data.toJson() has 'checkIns' list of maps with 'studentId' and 'checkOutTime'
        final dataJson = attendance.data!.toJson();
        final List<dynamic>? checkIns = dataJson['checkIns'];
        if (checkIns != null) {
          final checkedIn = <String>{};
          for (var cin in checkIns) {
            final studentId = cin['studentId'] as String?;
            final checkOutTime = cin['checkOutTime'];
            if (studentId != null && checkOutTime == null) {
              checkedIn.add(studentId);
            }
          }
          checkedInStudents.value = checkedIn;
          checkInCount.value = checkedIn.length;
          print('Loaded ${checkedIn.length} checked-in students');
        }
      }
    } catch (e) {
      print('Error loading current attendance students: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Check if today's attendance exists for a classroom
  Future<AttendanceModel?> checkTodayAttendance(String classroomId) async {
    try {
      isCheckingExisting.value = true;
      errorMessage.value = '';
      
      final today = DateTime.now();
      final dateStr = _formatDate(today);
      
      print('Checking existing attendance for classroom: $classroomId on date: $dateStr');
      
      // Check via the service method
      final hasAttendance = await _attendanceService.getAttendanceByClassroomDate(
        classroomId,
        dateStr,
      );
      
      if (hasAttendance.success == true && hasAttendance.data != null) {
        print('Found existing attendance for today');
        // Fetch the actual attendance data
        final attendanceData = await _fetchAttendanceByDate(classroomId, dateStr);
        
        if (attendanceData != null) {
          existingAttendance.value = attendanceData;
          print('Stored existing attendance: ${attendanceData.data?.id}');
          return attendanceData;
        }
      } else {
        print('No existing attendance found for today');
        existingAttendance.value = null;
      }
      
      return null;
    } catch (e) {
      print('Error checking today\'s attendance: $e');
      errorMessage.value = 'Failed to check existing attendance';
      existingAttendance.value = null;
      return null;
    } finally {
      isCheckingExisting.value = false;
    }
  }

  // Check attendance by specific date
  Future<AttendanceModel?> checkAttendanceByDate(
    String classroomId,
    DateTime date,
  ) async {
    try {
      final dateStr = _formatDate(date);
      
      final hasAttendance = await _attendanceService.getAttendanceByClassroomDate(
        classroomId,
        dateStr,
      );
      
      if (hasAttendance.success == true && hasAttendance.data != null) {
        return await _fetchAttendanceByDate(classroomId, dateStr);
      }
      
      return null;
    } catch (e) {
      print('Error checking attendance by date: $e');
      return null;
    }
  }

  // Fetch attendance details by date
  Future<AttendanceModel?> _fetchAttendanceByDate(
    String classroomId,
    String dateStr,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      if (token == null) {
        print('No authentication token found');
        return null;
      }

      // Call the API to get attendance details
      final result = await _attendanceService.getAttendanceByClassroomDate(
        classroomId,
        dateStr,
      );
      
      if (result.success == true && result.data != null) {
        return result;
      }
      
      return null;
    } catch (e) {
      print('Error fetching attendance by date: $e');
      return null;
    }
  }

  // Format date as YYYY-MM-DD
  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  // Function to create attendance
  Future<void> createAttendance(
    String classroomId, {
    String mode = 'CHECK_IN_ONLY',
    String deviceType = 'FACE',
    String? schoolId,
  }) async {
    try {
      isCreatingAttendance.value = true;
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';
      
      // First, check if attendance already exists for today
      print('Checking for existing attendance before creating new one...');
      final existingToday = await checkTodayAttendance(classroomId);
      
      if (existingToday != null) {
        errorMessage.value = 'Attendance already exists for today';
        print('Attendance already exists, aborting creation');
        return;
      }
      
      // Clear previous attendance data
      currentAttendance.value = null;
      attendanceId.value = '';
      
      // Get schoolId from SharedPreferences if not provided
      String? finalSchoolId = schoolId;
      if (finalSchoolId == null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? schoolJson = prefs.getString('currentSchool');
        if (schoolJson != null && schoolJson != 'no') {
          try {
            Map<String, dynamic> schoolMap = jsonDecode(schoolJson);
            finalSchoolId = schoolMap['id'];
          } catch (e) {
            print('Error parsing school JSON: $e');
          }
        }
      }
      
      if (finalSchoolId == null || finalSchoolId.isEmpty) {
        errorMessage.value = 'School ID not found. Please login again.';
        return;
      }
      
      print('Creating attendance - ClassroomID: $classroomId, Mode: $mode, DeviceType: $deviceType, SchoolID: $finalSchoolId');
      
      // Call API
      final result = await _authService.createAttendance(
        classroomId,
        mode: mode,
        deviceType: deviceType,
        schoolId: finalSchoolId,
      );
      
      print('API Response: $result');
      if (result.data != null) {
        print('Attendance data: ${result.data!.toJson()}');
      }
      
      if (result.success == true && result.data != null) {
        currentAttendance.value = result;
        
        if (result.data!.id != null && result.data!.id!.isNotEmpty) {
          attendanceId.value = result.data!.id!;
          print('Created new attendance with ID: ${attendanceId.value}');
        }
        
        successMessage.value = result.message ?? 'Attendance created successfully';
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        errorMessage.value = result.message ?? 'Failed to create attendance';
        await Future.delayed(const Duration(milliseconds: 500));
        print('Error creating attendance: ${errorMessage.value}');
      }
    } catch (e) {
      print('Exception in createAttendance: $e');
      errorMessage.value = 'An error occurred: $e';
      await Future.delayed(const Duration(milliseconds: 500));
      print('Error creating attendance: ${errorMessage.value}');
    } finally {
      isCreatingAttendance.value = false;
      isLoading.value = false;
    }
  }
  
  // Function to check in a student
  Future<void> checkInStudent({
    required String studentId,
    required String classroomId,
    required String attendanceId,
    String deviceType = 'MANUAL',
    String? deviceIdentifier,
    String? notes,
    String? checkTime,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';
      
      checkInModel.value = null;
      
      print('Check-in attempt - StudentID: $studentId, ClassroomID: $classroomId, AttendanceID: $attendanceId');
      print('DeviceType: $deviceType, DeviceIdentifier: $deviceIdentifier');
      
      final result = await _attendanceService.checkInStudent(
        studentId,
        classroomId,
        attendanceId,
        deviceType: deviceType,
        deviceIdentifier: deviceIdentifier,
        notes: notes,
        checkTime: checkTime,
        autoCheckOutPrevious: false, // Manual handling
      );
      
      print('Check-in API Response: $result');
      if (result.data != null) {
        print('Check-in data: ${result.data.toString()}');
      }
      
      if (result.success == true) {
        checkInModel.value = result;
        successMessage.value = result.message ?? 'Check-in successful';
        lastCheckedInStudentName.value = result.data?.studentName ?? '';
        lastCheckedInStudentCode.value = result.data?.studentId ?? '';
        checkedInStudents.add(studentId);
        checkInCount.value++;
        await Future.delayed(const Duration(milliseconds: 300));
        
        print('Student check-in successful: ${successMessage.value}');
      } else {
        errorMessage.value = result.message ?? 'Failed to check in student';
        print('Student check-in failed: ${errorMessage.value}');
      }
    } catch (e) {
      print('Exception in checkInStudent: $e');
      errorMessage.value = 'An error occurred during check-in: $e';
      print('Error during student check-in: ${errorMessage.value}');
    } finally {
      isLoading.value = false;
    }
  }

  // Function to check out a student
  // Future<void> checkOutStudent({
  //   required String studentId,
  //   required String classroomId,
  //   required String attendanceId,
  //   String deviceType = 'MANUAL',
  //   String? deviceIdentifier,
  //   String? notes,
  //   String? checkTime,
  // }) async {
  //   try {
  //     isLoading.value = true;
  //     errorMessage.value = '';
  //     successMessage.value = '';
      
  //     print('Check-out attempt - StudentID: $studentId, ClassroomID: $classroomId, AttendanceID: $attendanceId');
      
  //     final result = await _attendanceService.checkOutStudent(
  //       studentId,
  //       classroomId,
  //       attendanceId,
  //       deviceType: deviceType,
  //       deviceIdentifier: deviceIdentifier,
  //       notes: notes,
  //       checkTime: checkTime,
  //     );
      
  //     print('Check-out API Response: $result');
      
  //     if (result.success == true) {
  //       successMessage.value = result.message ?? 'Check-out successful';
  //       lastCheckedInStudentName.value = '';
  //       lastCheckedInStudentCode.value = '';
  //       checkedInStudents.remove(studentId);
  //       checkInCount.value--;
  //       await Future.delayed(const Duration(milliseconds: 300));
        
  //       print('Student check-out successful: ${successMessage.value}');
  //     } else {
  //       errorMessage.value = result.message ?? 'Failed to check out student';
  //       print('Student check-out failed: ${errorMessage.value}');
  //     }
  //   } catch (e) {
  //     print('Exception in checkOutStudent: $e');
  //     errorMessage.value = 'An error occurred during check-out: $e';
  //     print('Error during student check-out: ${errorMessage.value}');
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  
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
    existingAttendance.value = null;
    checkedInStudents.clear();
    checkInCount.value = 0;
    lastCheckedInStudentName.value = '';
    lastCheckedInStudentCode.value = '';
  }

  // Function to get attendance by ID
  Future<void> getAttendanceById(String attendanceId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';
      
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
    isCheckingExisting.value = false;
    errorMessage.value = '';
    successMessage.value = '';
    attendanceId.value = '';
    currentAttendance.value = null;
    existingAttendance.value = null;
    checkedInStudents.clear();
    checkInCount.value = 0;
    lastCheckedInStudentName.value = '';
    lastCheckedInStudentCode.value = '';
  }
}
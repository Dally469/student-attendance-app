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
      final attendance =
          await _attendanceService.getAttendanceById(attendanceId);
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
          checkedInStudents.clear();
          checkedInStudents.addAll(checkedIn);
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
      // Don't clear errorMessage here - let the caller handle it

      final today = DateTime.now();
      final dateStr = _formatDate(today);

      print(
          'Checking existing attendance for classroom: $classroomId on date: $dateStr');

      // Check via the service method
      final hasAttendance =
          await _attendanceService.getAttendanceByClassroomDate(
        classroomId,
        dateStr,
      );

      if (hasAttendance.success == true && hasAttendance.data != null) {
        print('Found existing attendance for today');
        // Fetch the actual attendance data
        final attendanceData =
            await _fetchAttendanceByDate(classroomId, dateStr);

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
      // Connection errors or other failures - treat as "no attendance found"
      // This allows creation to proceed
      print('Error checking today\'s attendance (will proceed with creation): $e');
      existingAttendance.value = null;
      return null; // Return null to allow creation to proceed
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

      final hasAttendance =
          await _attendanceService.getAttendanceByClassroomDate(
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

  // Function to create attendance.
  // Use mode CHECK_IN_OUT so users can clock in and clock out (scan: first=in, second=out; explicit: check-in then check-out).
  Future<void> createAttendance(
    String classroomId, {
    String mode = 'CHECK_IN_OUT',
    String deviceType = 'FACE',
    String? schoolId,
  }) async {
    try {
      isCreatingAttendance.value = true;
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      // First, check if attendance already exists for today
      // If check fails (connection error, etc.), we'll proceed with creation
      print('Checking for existing attendance before creating new one...');
      final existingToday = await checkTodayAttendance(classroomId);

      if (existingToday != null && existingToday.data != null) {
        // Found existing attendance - set it as current and return
        currentAttendance.value = existingToday;
        if (existingToday.data?.id != null && existingToday.data!.id!.isNotEmpty) {
          attendanceId.value = existingToday.data!.id!;
          print('Using existing attendance with ID: ${attendanceId.value}');
        }
        successMessage.value = 'Using existing attendance session';
        await Future.delayed(const Duration(milliseconds: 500));
        return;
      }
      
      // No attendance found or check failed - proceed with creation
      print('No existing attendance found, proceeding with creation...');

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

      print(
          'Creating attendance - ClassroomID: $classroomId, Mode: $mode, DeviceType: $deviceType, SchoolID: $finalSchoolId');

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

        successMessage.value =
            result.message ?? 'Attendance created successfully';
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        // Check if the error indicates attendance already exists
        final errorMsg = (result.message ?? '').toLowerCase();
        if (result.status == 400 && 
            (errorMsg.contains('already exists') || 
             errorMsg.contains('already exist'))) {
          print('Attendance already exists, attempting to fetch it...');
          
          // Try to fetch the existing attendance
          try {
            final today = DateTime.now();
            final dateStr = _formatDate(today);
            
            // Get all attendances for today
            final allAttendances = await _attendanceService.getAllAttendancesByClassroomDate(
              classroomId,
              dateStr,
            );
            
            // Find the attendance matching deviceType and mode
            Data? matchingAttendance;
            try {
              matchingAttendance = allAttendances.firstWhere(
                (att) => 
                  att.deviceType?.toUpperCase() == deviceType.toUpperCase() &&
                  att.mode?.toUpperCase() == mode.toUpperCase(),
              );
            } catch (e) {
              // No exact match found, try to get the first one if available
              if (allAttendances.isNotEmpty) {
                matchingAttendance = allAttendances.first;
              }
            }
            
            if (matchingAttendance != null) {
              // Create AttendanceModel from the found attendance
              currentAttendance.value = AttendanceModel(
                status: 200,
                success: true,
                message: 'Using existing attendance',
                data: Data(
                  id: matchingAttendance.id,
                  classroomId: matchingAttendance.classroomId ?? classroomId,
                  classroomName: matchingAttendance.classroomName,
                  attendanceDate: matchingAttendance.attendanceDate ?? dateStr,
                  mode: matchingAttendance.mode ?? mode,
                  deviceType: matchingAttendance.deviceType ?? deviceType,
                  schoolId: matchingAttendance.schoolId ?? finalSchoolId,
                ),
              );
              
              if (matchingAttendance.id != null && matchingAttendance.id!.isNotEmpty) {
                attendanceId.value = matchingAttendance.id!;
                print('Found existing attendance with ID: ${attendanceId.value}');
              }
              
              successMessage.value = 'Using existing attendance session';
              await Future.delayed(const Duration(milliseconds: 500));
              return; // Successfully found and set existing attendance
            }
          } catch (e) {
            print('Error fetching existing attendance: $e');
            // Fall through to show error message
          }
        }
        
        errorMessage.value = result.message ?? 'Failed to create attendance';
        await Future.delayed(const Duration(milliseconds: 500));
        print('Error creating attendance: ${errorMessage.value}');
      }
    } catch (e) {
      print('Exception in createAttendance: $e');
      
      // Check if it's a connection error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('connection refused') || 
          errorString.contains('socketexception') ||
          errorString.contains('failed host lookup') ||
          errorString.contains('network is unreachable')) {
        errorMessage.value = 'Cannot connect to server. Please check your internet connection and try again.';
      } else {
        errorMessage.value = 'An error occurred while creating attendance: ${e.toString()}';
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      print('Error creating attendance: ${errorMessage.value}');
    } finally {
      isCreatingAttendance.value = false;
      isLoading.value = false;
    }
  }

  // Function to check in a student (or check out if already checked in)
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

      // Check if student already checked in today (without check-out)
      final alreadyCheckedIn = checkedInStudents.contains(studentId);

      if (alreadyCheckedIn) {
        // Student already checked in, perform check-out instead
        print(
            'Student already checked in, performing check-out - StudentID: $studentId, AttendanceID: $attendanceId');

        final result = await _attendanceService.checkOutStudent(
          studentId: studentId,
          classroomId: classroomId,
          attendanceId: attendanceId,
          deviceType: deviceType,
          deviceIdentifier: deviceIdentifier,
          notes: notes,
          checkTime: checkTime,
        );

        print('Check-out API Response: $result');
        if (result.data != null) {
          print('Check-out data: ${result.data.toString()}');
        }

        if (result.success == true) {
          // Convert legacy model to CheckInModel for consistency
          final legacyData = result.data;

          checkInModel.value = CheckInModel(
            statusCode: result.status,
            success: result.success,
            message: result.message,
            data: legacyData != null
                ? CheckInData(
                    id: legacyData.id,
                    studentId: legacyData.studentId,
                    studentName: legacyData.studentName,
                    checkInTime: legacyData.checkInTime,
                    checkOutTime: legacyData.checkOutTime,
                    status: legacyData.status,
                    attendanceId: legacyData.attendanceId,
                    deviceType: legacyData.deviceType,
                    deviceIdentifier: legacyData.deviceIdentifier,
                  )
                : null,
          );

          // Always use check-out message since we're in the check-out branch
          successMessage.value = 'Successfully Attendance Recorded';

          lastCheckedInStudentName.value = legacyData?.studentName ?? '';
          lastCheckedInStudentCode.value = legacyData?.studentId ?? '';

          // Remove from checked-in students set since they've checked out
          checkedInStudents.remove(studentId);
          checkInCount.value = checkedInStudents.length;

          await Future.delayed(const Duration(milliseconds: 300));
          print('Student check-out successful: ${successMessage.value}');
        } else {
          // Check if the error indicates student already checked out
          final errorMsg = (result.message ?? '').toLowerCase();
          if (errorMsg.contains('already') &&
              (errorMsg.contains('checked out') ||
                  errorMsg.contains('clocked out') ||
                  errorMsg.contains('check-out') ||
                  errorMsg.contains('checkout'))) {
            errorMessage.value =
                'This student has already clocked out today. Cannot clock out again.';
          } else if (errorMsg.contains('already') &&
              (errorMsg.contains('checked in') ||
                  errorMsg.contains('clocked in'))) {
            errorMessage.value =
                'This student has already clocked in. Please scan again to clock out.';
          } else {
            errorMessage.value =
                result.message ?? 'Failed to check out student';
          }
          print('Student check-out failed: ${errorMessage.value}');
        }
      } else {
        // Student not checked in, perform check-in
        print(
            'Check-in attempt - StudentID: $studentId, ClassroomID: $classroomId, AttendanceID: $attendanceId');
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
          // Check if the response indicates they've already checked out
          final responseData = result.data;
          if (responseData != null &&
              responseData.checkOutTime != null &&
              responseData.checkOutTime!.isNotEmpty) {
            // Student already has a check-out time, meaning they've already clocked out
            errorMessage.value =
                'This student has already clocked out today. Cannot check in again.';
            print('Student already clocked out: ${errorMessage.value}');
          } else {
            checkInModel.value = result;
            successMessage.value = 'Successfully Attendance Recorded';
            lastCheckedInStudentName.value = result.data?.studentName ?? '';
            lastCheckedInStudentCode.value = result.data?.studentId ?? '';
            checkedInStudents.add(studentId);
            checkInCount.value++;
            await Future.delayed(const Duration(milliseconds: 300));

            print('Student check-in successful: ${successMessage.value}');
          }
        } else {
          // Check if the error indicates student already checked out
          final errorMsg = (result.message ?? '').toLowerCase();
          if (errorMsg.contains('already') &&
              (errorMsg.contains('checked out') ||
                  errorMsg.contains('clocked out') ||
                  errorMsg.contains('check-out') ||
                  errorMsg.contains('checkout'))) {
            errorMessage.value =
                'This student has already clocked out today. Cannot check in again.';
          } else if (errorMsg.contains('already') &&
              (errorMsg.contains('checked in') ||
                  errorMsg.contains('clocked in'))) {
            errorMessage.value =
                'This student has already clocked in. Please scan again to clock out.';
          } else {
            errorMessage.value = result.message ?? 'Failed to check in student';
          }
          print('Student check-in failed: ${errorMessage.value}');
        }
      }
    } catch (e) {
      print('Exception in checkInStudent: $e');
      errorMessage.value = 'An error occurred: $e';
      print('Error: ${errorMessage.value}');
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

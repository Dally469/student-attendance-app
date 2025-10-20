import 'dart:convert';
import 'dart:io';

import 'package:attendance/models/attendance.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/check.in.model.dart' as legacy;
import '../models/check_in.dart';
import '../models/offline_check_in.dart';
import '../models/attendance_sync_request.dart';

class AttendanceService {
  Future<void> saveOfflineCheckIn(OfflineCheckIn checkIn) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String key = 'offline_checkins_${checkIn.classroomId}';
      List<String> existingCheckins = prefs.getStringList(key) ?? [];
      // Ensure synced is false when saving
      Map<String, dynamic> checkInJson = checkIn.toJson();
      checkInJson['synced'] = false;
      existingCheckins.add(jsonEncode(checkInJson));
      await prefs.setStringList(key, existingCheckins);
    } catch (e) {
      print('Error saving offline check-in: $e');
    }
  }

  // Method for checking in a student - wrapper for compatibility with controller
  Future<CheckInModel> checkInStudent(
    String studentId,
    String classroomId,
    String attendanceId, {
    String deviceType = 'MANUAL',
    String? deviceIdentifier,
    String? notes,
    String? checkTime,
    String? mode,
    bool autoCheckOutPrevious = false,
  }) async {
    // Call the legacy method and convert the result
    legacy.CheckInModel legacyResult = await markAttendance(
      studentId: studentId,
      classroomId: classroomId,
      attendanceId: attendanceId,
      deviceType: deviceType,
      deviceIdentifier: deviceIdentifier,
      notes: notes,
      checkTime: checkTime,
      mode: mode,
      autoCheckOutPrevious: autoCheckOutPrevious,
    );
    
    // Convert legacy model to new model
    return CheckInModel(
      statusCode: legacyResult.status,
      success: legacyResult.success,
      message: legacyResult.message,
      data: legacyResult.data != null ? CheckInData(
        id: legacyResult.data?.id,
        studentId: legacyResult.data?.studentId,
        studentName: legacyResult.data?.studentName,
        checkInTime: legacyResult.data?.checkInTime,
        checkOutTime: legacyResult.data?.checkOutTime,
        status: legacyResult.data?.status,
        attendanceId: legacyResult.data?.attendanceId,
        deviceType: legacyResult.data?.deviceType,
        deviceIdentifier: legacyResult.data?.deviceIdentifier,
      ) : null,
    );
  }
  
  Future<legacy.CheckInModel> markAttendance({
    required String studentId,
    required String classroomId,
    required String attendanceId,
    String deviceType = 'MANUAL',
    String? deviceIdentifier,
    String? notes,
    String? checkTime,
    String? mode,
    bool autoCheckOutPrevious = false,
  }) async {
    try {
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      String? token = sharedPreferences.getString("token");
      if (token == null) {
        return legacy.CheckInModel(
          success: false,
          status: 401,
          message: 'Authentication token not found',
        );
      }

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': token,
      };

      // Build request body matching EnhancedCheckInRequestDTO
      Map<String, dynamic> body = {
        'studentId': studentId,
        'classroomId': classroomId,
        'attendanceId': attendanceId,
        'deviceType': deviceType,
        'autoCheckOutPrevious': autoCheckOutPrevious,
      };
      if (deviceIdentifier != null && deviceIdentifier.isNotEmpty) {
        body['deviceIdentifier'] = deviceIdentifier;
      }
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }
      if (mode != null && mode.isNotEmpty) {
        body['mode'] = mode;
      }
      String checkInTimeStr = checkTime ?? DateTime.now().toIso8601String();
      body['checkInTime'] = checkInTimeStr;

      final uri = Uri.parse('${dotenv.get('mainUrl')}/api/student-attendance/check-in');
      
      print('=== POST Check-In Request ===');
      print('URL: $uri');
      print('Headers: $headers');
      print('Body: ${jsonEncode(body)}');

      var response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('=============================');
      
      Map<String, dynamic> results = jsonDecode(response.body);

      var connectivityResult = await Connectivity().checkConnectivity();
      bool hasInternet = connectivityResult != ConnectivityResult.none;

      if (response.statusCode == 200) {
        return legacy.CheckInModel.fromJson(results);
      } else {
        // Store offline if API call fails (only if had internet but failed)
        if (hasInternet) {
          await saveOfflineCheckIn(OfflineCheckIn(
            studentId: studentId,
            classroomId: classroomId,
            attendanceId: attendanceId,
            timestamp: DateTime.parse(checkInTimeStr),
          ));
        }

        return legacy.CheckInModel(
          success: false,
          status: response.statusCode,
          message: results['message'] ?? 'Failed to check in',
        );
      }
    } catch (e) {
      var connectivityResult = await Connectivity().checkConnectivity();
      bool hasInternet = connectivityResult != ConnectivityResult.none;

      if (!hasInternet) {
        // Store offline if no internet
        await saveOfflineCheckIn(OfflineCheckIn(
          studentId: studentId,
          classroomId: classroomId,
          attendanceId: attendanceId,
          timestamp: DateTime.now(),
        ));

        return legacy.CheckInModel(
          success: true,
          status: 200,
          message: 'Stored offline, will sync when online',
        );
      }

      return legacy.CheckInModel(
        success: false,
        status: 500,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  // Check-out a student
  Future<legacy.CheckInModel> checkOutStudent({
    required String studentId,
    required String classroomId,
    required String attendanceId,
    String deviceType = 'MANUAL',
    String? deviceIdentifier,
    String? notes,
    String? checkTime,
    String? mode,
  }) async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      bool hasInternet = connectivityResult != ConnectivityResult.none;

      if (!hasInternet) {
        return legacy.CheckInModel(
          success: false,
          status: 503,
          message: 'Check-out requires internet connection',
        );
      }

      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      String? token = sharedPreferences.getString("token");
      if (token == null) {
        return legacy.CheckInModel(
          success: false,
          status: 401,
          message: 'Authentication token not found',
        );
      }

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': token,
      };

      // Build request body (assuming similar structure to check-in DTO but for check-out)
      Map<String, dynamic> body = {
        'studentId': studentId,
        'classroomId': classroomId,
        'attendanceId': attendanceId,
        'deviceType': deviceType,
      };
      if (deviceIdentifier != null && deviceIdentifier.isNotEmpty) {
        body['deviceIdentifier'] = deviceIdentifier;
      }
      if (notes != null && notes.isNotEmpty) {
        body['notes'] = notes;
      }
      if (mode != null && mode.isNotEmpty) {
        body['mode'] = mode;
      }
      String checkOutTimeStr = checkTime ?? DateTime.now().toIso8601String();
      body['checkOutTime'] = checkOutTimeStr;

      final uri = Uri.parse('${dotenv.get('mainUrl')}/api/attendance/check-out');
      
      print('=== POST Check-Out Request ===');
      print('URL: $uri');
      print('Headers: $headers');
      print('Body: ${jsonEncode(body)}');

      var response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('==============================');
      
      Map<String, dynamic> results = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return legacy.CheckInModel.fromJson(results);
      } else {
        return legacy.CheckInModel(
          success: false,
          status: response.statusCode,
          message: results['message'] ?? 'Failed to check out',
        );
      }
    } catch (e) {
      return legacy.CheckInModel(
        success: false,
        status: 500,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  /// Checks if the classroom has attendance records for the specified date.
  /// Date must be in YYYY-MM-DD format. Mode and deviceType are optional.
  Future<AttendanceModel> getAttendanceByClassroomDate(
    String classroomId,
    String date,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        return AttendanceModel(
          success: false,
          status: 401,
          message: 'Authentication token not found',
        );
      }

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': token,
      };

      final uri = Uri.parse(
        '${dotenv.get('mainUrl')}/api/attendance/classroom/$classroomId/date?date=$date',
      );

      print('=== GET Attendance by Date Request ===');
      print('URL: $uri');
      print('Headers: $headers');

      var response = await http.get(uri, headers: headers);

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('======================================');

      // Handle non-200 responses
      if (response.statusCode != 200) {
        Map<String, dynamic> errorResults = jsonDecode(response.body);
        return AttendanceModel(
          success: false,
          status: response.statusCode,
          message: errorResults['message'] ?? 'Failed to fetch attendance',
        );
      }

      Map<String, dynamic> results = jsonDecode(response.body);

      // Check if success is false even with 200 status
      if (results['success'] == false) {
        return AttendanceModel(
          success: false,
          status: response.statusCode,
          message: results['message'] ?? 'No attendance found',
        );
      }

      // Handle the data field
      if (results['data'] == null) {
        return AttendanceModel(
          success: false,
          status: 404,
          message: 'No attendance records found for this date',
        );
      }

      // If the API returns a list
      if (results['data'] is List) {
        final dataList = results['data'] as List;
        
        // If list is empty
        if (dataList.isEmpty) {
          return AttendanceModel(
            success: false,
            status: 404,
            message: 'No attendance records found for this date',
          );
        }
        
        // Take the first item from the list
        final firstAttendance = dataList[0];
        return AttendanceModel.fromJson({
          'success': results['success'],
          'status': response.statusCode,
          'message': results['message'],
          'data': firstAttendance,
        });
      }
      
      // If it's already a single object
      return AttendanceModel.fromJson(results);
    } catch (e, stackTrace) {
      print('Error in getAttendanceByClassroomDate: $e');
      print('Stack trace: $stackTrace');
      return AttendanceModel(
        success: false,
        status: 500,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  Future<List<OfflineCheckIn>> getUnsyncedCheckIns() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<OfflineCheckIn> unsyncedCheckIns = [];

      Set<String> keys = prefs.getKeys();
      List<String> checkInKeys =
          keys.where((key) => key.startsWith('offline_checkins_')).toList();

      for (String key in checkInKeys) {
        List<String>? records = prefs.getStringList(key);
        if (records != null) {
          unsyncedCheckIns.addAll(records
              .map((record) => OfflineCheckIn.fromJson(json.decode(record)))
              .where((checkIn) => !checkIn.synced));
        }
      }

      return unsyncedCheckIns;
    } catch (e) {
      print('Error getting unsynced check-ins: $e');
      return [];
    }
  }

  Future<bool> syncOfflineCheckIns() async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }

      List<OfflineCheckIn> unsyncedCheckIns = await getUnsyncedCheckIns();
      
      if (unsyncedCheckIns.isEmpty) return true;
      
      // Group check-ins by classroom and date for accurate syncing
      Map<String, Map<String, List<OfflineCheckIn>>> groupedCheckIns = {};
      for (var checkIn in unsyncedCheckIns) {
        String classroomId = checkIn.classroomId;
        String dateStr = _formatDate(checkIn.timestamp);
        groupedCheckIns.putIfAbsent(classroomId, () => <String, List<OfflineCheckIn>>{});
        groupedCheckIns[classroomId]!.putIfAbsent(dateStr, () => <OfflineCheckIn>[]);
        groupedCheckIns[classroomId]![dateStr]!.add(checkIn);
      }
      
      bool allSuccess = true;
      
      // Sync by classroom and date
      for (var classroomEntry in groupedCheckIns.entries) {
        String classroomId = classroomEntry.key;
        for (var dateEntry in classroomEntry.value.entries) {
          String dateStr = dateEntry.key;
          List<OfflineCheckIn> checkInsForDate = dateEntry.value;
          
          // Check if attendance already exists for this date
          AttendanceModel attendance = await getAttendanceByClassroomDate(
            classroomId,
            dateStr,
          );
          
          if (attendance.success == true && attendance.data != null) {
            print('Attendance already exists for classroom $classroomId on $dateStr, marking offline records as synced');
            await _markCheckInsAsSynced(classroomId, checkInsForDate);
            continue;
          }
          
          // Sync the records
          final syncSuccess = await _syncAttendanceRecordsByClassroomDate(
            classroomId,
            dateStr,
            checkInsForDate,
          );
          
          if (syncSuccess) {
            await _markCheckInsAsSynced(classroomId, checkInsForDate);
          } else {
            print('Failed to sync records for classroom $classroomId on $dateStr');
            allSuccess = false;
          }
        }
      }
      
      return allSuccess;
    } catch (e) {
      print('Error syncing offline check-ins: $e');
      return false;
    }
  }

  // Helper to format date as YYYY-MM-DD
  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  // Helper to mark specific check-ins as synced by updating the synced field
  Future<void> _markCheckInsAsSynced(String classroomId, List<OfflineCheckIn> checkIns) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String key = 'offline_checkins_$classroomId';
      List<String> existingCheckins = prefs.getStringList(key) ?? [];
      List<String> updatedCheckins = [];
      
      Set<String> checkInSignatures = checkIns.map((checkIn) => 
        '${checkIn.studentId}_${checkIn.timestamp.toIso8601String()}'
      ).toSet();
      
      for (String recordStr in existingCheckins) {
        Map<String, dynamic> recordJson = json.decode(recordStr);
        String signature = '${recordJson['studentId']}_${recordJson['timestamp']}';
        if (checkInSignatures.contains(signature)) {
          recordJson['synced'] = true;
        }
        updatedCheckins.add(jsonEncode(recordJson));
      }
      
      await prefs.setStringList(key, updatedCheckins);
    } catch (e) {
      print('Error marking check-ins as synced for classroom $classroomId: $e');
    }
  }
  
  // Get device ID for sync request
  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = 'unknown-device';
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.device!;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'ios-device';
      } else if (Platform.isMacOS) {
        final macOsInfo = await deviceInfo.macOsInfo;
        deviceId = macOsInfo.systemGUID ?? 'macos-device';
      }
    } catch (e) {
      print('Error getting device info: $e');
      deviceId = 'device-id-error';
    }
    
    return deviceId;
  }
  
  // Sync attendance records for a specific classroom and date
  Future<bool> _syncAttendanceRecordsByClassroomDate(
    String classroomId,
    String attendanceDate,
    List<OfflineCheckIn> checkIns,
  ) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      
      if (token == null) {
        print('Authentication token not found');
        return false;
      }
      
      // Get device ID for the request
      String deviceId = await _getDeviceId();
      
      // Convert offline check-ins to attendance records
      List<AttendanceRecord> attendanceRecords = checkIns.map((checkIn) {
        // Default status is PRESENT, but this could be enhanced to use actual status
        return AttendanceRecord(
          studentId: checkIn.studentId,
          status: 'PRESENT',
          recordedAt: checkIn.timestamp.toIso8601String(),
        );
      }).toList();
      
      // Create the sync request
      final syncRequest = AttendanceSyncRequest(
        classroomId: classroomId,
        attendanceDate: attendanceDate,
        syncTimestamp: DateTime.now().toIso8601String(),
        deviceId: deviceId,
        attendanceRecords: attendanceRecords,
      );
      
      // Make the API request
      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': token,
      };
      
      final url = '${dotenv.get('mainUrl')}/api/attendance/sync';
      final requestBody = syncRequest.toJson();
      
      print('=== POST Sync Attendance Request ===');
      print('URL: $url');
      print('Headers: $headers');
      print('Body: ${json.encode(requestBody)}');
      print('Syncing ${attendanceRecords.length} records for classroom: $classroomId on date: $attendanceDate');
      
      var response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(requestBody),
      );
      
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('====================================');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('API error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error syncing attendance records for classroom $classroomId on $attendanceDate: $e');
      return false;
    }
  }
}
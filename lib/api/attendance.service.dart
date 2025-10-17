import 'dart:convert';
import 'dart:io';

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
      existingCheckins.add(jsonEncode(checkIn.toJson()));
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
  }) async {
    try {
      var connectivityResult = await Connectivity().checkConnectivity();
      bool hasInternet = connectivityResult != ConnectivityResult.none;

      if (hasInternet) {
        SharedPreferences sharedPreferences =
            await SharedPreferences.getInstance();
        String? token = sharedPreferences.getString("token");

        Map<String, String> headers = {
          'Content-Type': 'application/json',
          'Authorization': '${token.toString()}}',
        };

        // Build query parameters
        final queryParams = <String, String>{
          'deviceType': deviceType,
        };
        if (deviceIdentifier != null && deviceIdentifier.isNotEmpty) {
          queryParams['deviceIdentifier'] = deviceIdentifier;
        }
        if (notes != null && notes.isNotEmpty) {
          queryParams['notes'] = notes;
        }
        if (checkTime != null && checkTime.isNotEmpty) {
          queryParams['checkTime'] = checkTime;
        }

        final uri = Uri.parse(
          '${dotenv.get('mainUrl')}/api/attendance/check-in/$attendanceId/student/$studentId'
        ).replace(queryParameters: queryParams);
        
        print('=== POST Check-In Request ===');
        print('URL: $uri');
        print('Headers: $headers');
        print('Query Params: $queryParams');

        var response = await http.post(uri, headers: headers);

        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');
        print('=============================');
        
        Map<String, dynamic> results = jsonDecode(response.body);

        if (response.statusCode == 200) {
          return legacy.CheckInModel.fromJson(results);
        } else {
          // Store offline if API call fails
          await saveOfflineCheckIn(OfflineCheckIn(
            studentId: studentId,
            classroomId: classroomId,
            attendanceId: attendanceId,
            timestamp: DateTime.now(),
          ));

          return legacy.CheckInModel(
            success: false,
            status: response.statusCode,
            message: results['message'] ?? 'Failed to check in',
          );
        }
      } else {
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
    } catch (e) {
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
    required String attendanceId,
    String deviceType = 'MANUAL',
    String? deviceIdentifier,
    String? notes,
    String? checkTime,
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

      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      String? token = sharedPreferences.getString("token");

      Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': '${token.toString()}}',
      };

      // Build query parameters
      final queryParams = <String, String>{
        'deviceType': deviceType,
      };
      if (deviceIdentifier != null && deviceIdentifier.isNotEmpty) {
        queryParams['deviceIdentifier'] = deviceIdentifier;
      }
      if (notes != null && notes.isNotEmpty) {
        queryParams['notes'] = notes;
      }
      if (checkTime != null && checkTime.isNotEmpty) {
        queryParams['checkTime'] = checkTime;
      }

      final uri = Uri.parse(
        '${dotenv.get('mainUrl')}/api/attendance/check-out/$attendanceId/student/$studentId'
      ).replace(queryParameters: queryParams);
      
      print('=== POST Check-Out Request ===');
      print('URL: $uri');
      print('Headers: $headers');
      print('Query Params: $queryParams');

      var response = await http.post(uri, headers: headers);

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

      // Group offline check-ins by classroom ID
      Map<String, List<OfflineCheckIn>> checkInsByClassroom = {};
      List<OfflineCheckIn> unsyncedCheckIns = await getUnsyncedCheckIns();
      
      if (unsyncedCheckIns.isEmpty) return true;
      
      // Group check-ins by classroom for batch processing
      for (var checkIn in unsyncedCheckIns) {
        if (!checkInsByClassroom.containsKey(checkIn.classroomId)) {
          checkInsByClassroom[checkIn.classroomId] = [];
        }
        checkInsByClassroom[checkIn.classroomId]!.add(checkIn);
      }
      
      // Sync attendance records by classroom
      for (var classroomId in checkInsByClassroom.keys) {
        final success = await _syncAttendanceRecordsByClassroom(
          classroomId,
          checkInsByClassroom[classroomId]!,
        );
        
        if (!success) {
          print('Failed to sync records for classroom: $classroomId');
        }
      }
      
      return true;
    } catch (e) {
      print('Error syncing offline check-ins: $e');
      return false;
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
  
  // Sync attendance records for a specific classroom
  Future<bool> _syncAttendanceRecordsByClassroom(
      String classroomId, List<OfflineCheckIn> checkIns) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      
      if (token == null) {
        print('Authentication token not found');
        return false;
      }
      
      // Get device ID for the request
      String deviceId = await _getDeviceId();
      
      // Format the date as required in the request (YYYY-MM-DD)
      final now = DateTime.now();
      final attendanceDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
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
      print('Syncing ${attendanceRecords.length} records for classroom: $classroomId');
      
      var response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(requestBody),
      );
      
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('====================================');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Clear the successfully synced records from storage
        String key = 'offline_checkins_$classroomId';
        List<String> existingCheckins = prefs.getStringList(key) ?? [];
        
        // Remove all the synced check-ins for this classroom
        existingCheckins.removeWhere((record) {
          var recordJson = json.decode(record);
          return checkIns.any((checkIn) =>
              recordJson['studentId'] == checkIn.studentId &&
              recordJson['timestamp'] == checkIn.timestamp.toIso8601String());
        });
        
        await prefs.setStringList(key, existingCheckins);
        return true;
      } else {
        print('API error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error syncing attendance records for classroom $classroomId: $e');
      return false;
    }
  }
}

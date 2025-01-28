import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/check.in.model.dart';
import '../models/offline_check_in.dart';

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

  Future<CheckInModel> markAttendance({
    required String studentId,
    required String classroomId,
    required String attendanceId,
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

        var response = await http.post(
            Uri.parse('${dotenv.get('mainUrl')}/api/attendance/check-in'),
            headers: headers,
            body: json.encode({
              'studentId': studentId,
              'classroomId': classroomId,
              'attendanceId': attendanceId,
            }));

        Map<String, dynamic> results = jsonDecode(response.body);
        print(results);

        if (response.statusCode == 200) {
          return CheckInModel.fromJson(results);
        } else {
          // Store offline if API call fails
          await saveOfflineCheckIn(OfflineCheckIn(
            studentId: studentId,
            classroomId: classroomId,
            attendanceId: attendanceId,
            timestamp: DateTime.now(),
          ));

          return CheckInModel(
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

        return CheckInModel(
          success: true,
          status: 200,
          message: 'Stored offline, will sync when online',
        );
      }
    } catch (e) {
      return CheckInModel(
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

      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      String? token = sharedPreferences.getString("token");

      for (var checkIn in unsyncedCheckIns) {
        try {
          var response = await markAttendance(
            studentId: checkIn.studentId,
            classroomId: checkIn.classroomId,
            attendanceId: checkIn.attendanceId,
          );

          if (response.success) {
            // Remove the synced check-in from storage
            String key = 'offline_checkins_${checkIn.classroomId}';
            List<String> existingCheckins =
                sharedPreferences.getStringList(key) ?? [];
            existingCheckins.removeWhere((record) {
              var recordJson = json.decode(record);
              return recordJson['studentId'] == checkIn.studentId &&
                  recordJson['timestamp'] ==
                      checkIn.timestamp.toIso8601String();
            });
            await sharedPreferences.setStringList(key, existingCheckins);
          }
        } catch (e) {
          print('Error syncing check-in: $e');
        }
      }

      return true;
    } catch (e) {
      print('Error syncing offline check-ins: $e');
      return false;
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/facial.check.in.response.dart';
import '../models/facial.sync.request.dart';
import '../models/offline.facial.check.in.response.dart';

class FacialService extends GetxController {
  static FacialService get to => Get.find<FacialService>();

  // Reactive state variables
  final Rx<FaceDetector?> _faceDetector = Rx<FaceDetector?>(null);
  final Rx<Interpreter?> _interpreter = Rx<Interpreter?>(null);
  final RxBool isInitialized = false.obs;
  final Rx<ConnectivityResult> connectivityStatus = ConnectivityResult.none.obs;

  @override
  void onInit() {
    super.onInit();
    // Monitor connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      connectivityStatus.value = result;
      if (result != ConnectivityResult.none) {
        syncOfflineFacialCheckIns();
      }
    });
    initModel();
  }

  Future<void> initModel() async {
    if (isInitialized.value) return;

    try {
      // Configure FaceDetector with optimized settings
      _faceDetector.value = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: false,
          enableClassification: false,
          minFaceSize: 0.15,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      // Load TFLite model
      const modelPath = 'assets/models/mobilefacenet.tflite';
      final assetData = await rootBundle.load(modelPath);
      if (assetData.lengthInBytes == 0) {
        _showError('Asset $modelPath is empty');
        throw Exception('Asset $modelPath is empty');
      }

      _interpreter.value = await Interpreter.fromAsset(modelPath);
      isInitialized.value = true;
      debugPrint('Successfully initialized facial recognition model: $modelPath');
    } catch (e) {
      _showError('Failed to initialize model: $e');
      throw Exception('Failed to initialize model: $e');
    }
  }

  @override
  void onClose() {
    _faceDetector.value?.close();
    _interpreter.value?.close();
    isInitialized.value = false;
    debugPrint('FacialService resources disposed');
    super.onClose();
  }

  Future<List<double>> getEmbedding(XFile image, {int maxRetries = 2}) async {
    try {
      // Load and decode the image
      final imageBytes = await File(image.path).readAsBytes();
      img.Image? decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        _showError('Invalid image format');
        throw Exception('Invalid image format');
      }

      // Preprocess image
      decodedImage = _preprocessImage(decodedImage);

      // Process image with ML Kit to detect faces
      final inputImage = InputImage.fromFilePath(image.path);
      List<Face> faces;
      int attempt = 0;

      do {
        faces = await _faceDetector.value!.processImage(inputImage);
        attempt++;
        if (faces.isEmpty && attempt < maxRetries) {
          debugPrint('No faces detected, retrying ($attempt/$maxRetries)');
          await Future.delayed(Duration(milliseconds: 100));
        }
      } while (faces.isEmpty && attempt < maxRetries);

      if (faces.isEmpty) {
        _showError('No face detected after $maxRetries attempts');
        throw Exception('No face detected');
      }
      if (faces.length > 1) {
        _showError('Multiple faces detected, expected only one');
        throw Exception('Multiple faces detected');
      }

      // Get the first face
      final face = faces.first;
      final boundingBox = face.boundingBox;

      // Validate face size
      if (boundingBox.width < 100 || boundingBox.height < 100) {
        _showError('Detected face is too small');
        throw Exception('Face is too small for recognition');
      }

      // Crop the face region with padding
      final padding = 0.2;
      final cropWidth = (boundingBox.width * (1 + padding)).toInt();
      final cropHeight = (boundingBox.height * (1 + padding)).toInt();
      final cropX = (boundingBox.left - boundingBox.width * padding / 2)
          .toInt()
          .clamp(0, decodedImage.width);
      final cropY = (boundingBox.top - boundingBox.height * padding / 2)
          .toInt()
          .clamp(0, decodedImage.height);

      final croppedImage = img.copyCrop(
        decodedImage,
        x: cropX,
        y: cropY,
        width: cropWidth.clamp(0, decodedImage.width - cropX),
        height: cropHeight.clamp(0, decodedImage.height - cropY),
      );

      // Resize to MobileFaceNet input size
      final resizedImage = img.copyResize(croppedImage, width: 112, height: 112);

      // Normalize pixel values
      final input = Float32List(1 * 112 * 112 * 3);
      int pixelIndex = 0;
      for (int y = 0; y < 112; y++) {
        for (int x = 0; x < 112; x++) {
          final pixel = resizedImage.getPixel(x, y);
          input[pixelIndex++] = (pixel.r / 127.5) - 1.0;
          input[pixelIndex++] = (pixel.g / 127.5) - 1.0;
          input[pixelIndex++] = (pixel.b / 127.5) - 1.0;
        }
      }

      // Prepare output tensor
      final output = List.filled(128, 0.0);
      if (_interpreter.value == null) {
        _showError('Facial recognition model not initialized');
        throw Exception('Facial recognition model not initialized');
      }
      _interpreter.value!.run(input, output);

      // Normalize output embedding
      double norm = 0.0;
      for (var value in output) {
        norm += value * value;
      }
      norm = norm == 0 ? 1 : sqrt(norm);
      final normalizedOutput = output.map((value) => value / norm).toList();

      debugPrint('Successfully generated face embedding');
      return normalizedOutput;
    } catch (e) {
      _showError('Failed to generate face embedding: $e');
      throw Exception('Failed to generate face embedding: $e');
    }
  }

  img.Image _preprocessImage(img.Image image) {
    return img.adjustColor(
      image,
      brightness: 1.1,
      contrast: 1.2,
    );
  }

  Future<bool> checkFacialData(String studentCode, String token) async {
    try {
      if (connectivityStatus.value == ConnectivityResult.none) {
        _showError('No internet connection');
        return false;
      }

      final url = '${dotenv.get('mainUrl')}/api/students/$studentCode/has-facial-data';
      final headers = {'Authorization': 'Bearer $token'};
      
      debugPrint('=== GET Check Facial Data Request ===');
      debugPrint('URL: $url');
      debugPrint('Headers: $headers');
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('=====================================');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] as bool;
      }
      _showError('Failed to check facial data');
      return false;
    } catch (e) {
      _showError('Error checking facial data: $e');
      return false;
    }
  }

  Future<bool> updateFaceEmbedding(
      String studentCode, XFile image, String token) async {
    try {
      final embedding = await getEmbedding(image);
      final base64Embedding = base64Encode(_floatToByte(embedding));

      if (connectivityStatus.value == ConnectivityResult.none) {
        _showError('Offline face embedding update not supported');
        return false;
      }

      final url = '${dotenv.get('mainUrl')}/api/students/$studentCode/face-embedding';
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': token,
      };
      final requestBody = {'embedding': base64Embedding.substring(0, 50) + '...'}; // Log truncated embedding
      
      debugPrint('=== POST Update Face Embedding Request ===');
      debugPrint('URL: $url');
      debugPrint('Headers: $headers');
      debugPrint('Body (truncated): ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({'embedding': base64Embedding}),
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('==========================================');
      
      if (response.statusCode == 200) {
        Get.snackbar('Success', 'Face embedding updated successfully');
        return true;
      }
      _showError('Failed to update face embedding');
      return false;
    } catch (e) {
      _showError('Error updating face embedding: $e');
      return false;
    }
  }

  Future<void> saveOfflineFacialCheckIn(OfflineFacialCheckIn checkIn) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String key = 'offline_facial_checkins_${checkIn.classroomId}';
      List<String> existingCheckins = prefs.getStringList(key) ?? [];
      existingCheckins.add(jsonEncode(checkIn.toJson()));
      await prefs.setStringList(key, existingCheckins);
      Get.snackbar('Success', 'Saved offline facial check-in');
    } catch (e) {
      _showError('Error saving offline facial check-in: $e');
    }
  }

  Future<FacialCheckInModel> markFacialAttendance({
    required String studentCode,
    required String classroomId,
    required String attendanceId,
    required XFile image,
  }) async {
    try {
      bool hasInternet = connectivityStatus.value != ConnectivityResult.none;

      if (hasInternet) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString("token");
        if (token == null) {
          return FacialCheckInModel(
            success: false,
            status: 401,
            message: 'Authentication token not found',
          );
        }

        final hasFacialData = await checkFacialData(studentCode, token);
        if (!hasFacialData) {
          return FacialCheckInModel(
            success: false,
            status: 400,
            message: 'Student has no facial data registered',
          );
        }

        final embedding = await getEmbedding(image);
        final base64Embedding = base64Encode(_floatToByte(embedding));

        final url = '${dotenv.get('mainUrl')}/api/students/attendance/facial';
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };
        final requestBody = {
          'studentCode': studentCode,
          'embedding': base64Embedding.substring(0, 50) + '...', // Truncated for logging
          'classroomId': classroomId,
          'attendanceId': attendanceId,
        };
        
        debugPrint('=== POST Facial Attendance Request ===');
        debugPrint('URL: $url');
        debugPrint('Headers: $headers');
        debugPrint('Body (embedding truncated): ${jsonEncode(requestBody)}');
        
        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode({
            'studentCode': studentCode,
            'embedding': base64Embedding,
            'classroomId': classroomId,
            'attendanceId': attendanceId,
          }),
        );

        debugPrint('Response Status: ${response.statusCode}');
        debugPrint('Response Body: ${response.body}');
        debugPrint('======================================');
        
        Map<String, dynamic> results = jsonDecode(response.body);

        if (response.statusCode == 200) {
          Get.snackbar('Success', 'Facial attendance marked successfully');
          return FacialCheckInModel.fromJson(results);
        } else {
          await saveOfflineFacialCheckIn(OfflineFacialCheckIn(
            studentCode: studentCode,
            classroomId: classroomId,
            attendanceId: attendanceId,
            base64Embedding: base64Embedding,
            timestamp: DateTime.now(),
          ));
          return FacialCheckInModel(
            success: false,
            status: response.statusCode,
            message: results['message'] ?? 'Failed to mark facial attendance',
          );
        }
      } else {
        final embedding = await getEmbedding(image);
        final base64Embedding = base64Encode(_floatToByte(embedding));
        await saveOfflineFacialCheckIn(OfflineFacialCheckIn(
          studentCode: studentCode,
          classroomId: classroomId,
          attendanceId: attendanceId,
          base64Embedding: base64Embedding,
          timestamp: DateTime.now(),
        ));
        Get.snackbar('Info', 'Stored offline, will sync when online');
        return FacialCheckInModel(
          success: true,
          status: 200,
          message: 'Stored offline, will sync when online',
        );
      }
    } catch (e) {
      _showError('Error marking facial attendance: $e');
      return FacialCheckInModel(
        success: false,
        status: 500,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  Future<List<OfflineFacialCheckIn>> getUnsyncedFacialCheckIns() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<OfflineFacialCheckIn> unsyncedCheckIns = [];

      Set<String> keys = prefs.getKeys();
      List<String> checkInKeys = keys
          .where((key) => key.startsWith('offline_facial_checkins_'))
          .toList();

      for (String key in checkInKeys) {
        List<String>? records = prefs.getStringList(key);
        if (records != null) {
          unsyncedCheckIns.addAll(records
              .map((record) =>
                  OfflineFacialCheckIn.fromJson(json.decode(record)))
              .where((checkIn) => !checkIn.synced));
        }
      }

      debugPrint('Retrieved ${unsyncedCheckIns.length} unsynced facial check-ins');
      return unsyncedCheckIns;
    } catch (e) {
      _showError('Error getting unsynced facial check-ins: $e');
      return [];
    }
  }

  Future<bool> syncOfflineFacialCheckIns() async {
    try {
      if (connectivityStatus.value == ConnectivityResult.none) {
        _showError('No internet connection for sync');
        return false;
      }

      Map<String, List<OfflineFacialCheckIn>> checkInsByClassroom = {};
      List<OfflineFacialCheckIn> unsyncedCheckIns =
          await getUnsyncedFacialCheckIns();

      if (unsyncedCheckIns.isEmpty) {
        debugPrint('No unsynced facial check-ins to sync');
        return true;
      }

      for (var checkIn in unsyncedCheckIns) {
        checkInsByClassroom.putIfAbsent(checkIn.classroomId, () => []).add(checkIn);
      }

      bool allSuccess = true;
      for (var classroomId in checkInsByClassroom.keys) {
        final success = await _syncFacialAttendanceRecordsByClassroom(
          classroomId,
          checkInsByClassroom[classroomId]!,
        );
        if (!success) {
          debugPrint('Failed to sync facial records for classroom: $classroomId');
          allSuccess = false;
        }
      }

      if (allSuccess) {
        Get.snackbar('Success', 'All offline facial check-ins synced');
      }
      return allSuccess;
    } catch (e) {
      _showError('Error syncing offline facial check-ins: $e');
      return false;
    }
  }

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceId = 'unknown-device';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = androidInfo.id ?? 'android-device';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'ios-device';
      } else if (Platform.isMacOS) {
        final macOsInfo = await deviceInfo.macOsInfo;
        deviceId = macOsInfo.systemGUID ?? 'macos-device';
      }
    } catch (e) {
      _showError('Error getting device info: $e');
      deviceId = 'device-id-error';
    }

    return deviceId;
  }

  Future<bool> _syncFacialAttendanceRecordsByClassroom(
      String classroomId, List<OfflineFacialCheckIn> checkIns) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");

      if (token == null) {
        _showError('Authentication token not found');
        return false;
      }

      String deviceId = await _getDeviceId();
      final now = DateTime.now();
      final attendanceDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      List<FacialAttendanceRecord> attendanceRecords = checkIns.map((checkIn) {
        return FacialAttendanceRecord(
          studentCode: checkIn.studentCode,
          base64Embedding: checkIn.base64Embedding,
          recordedAt: checkIn.timestamp.toIso8601String(),
        );
      }).toList();

      final syncRequest = FacialAttendanceSyncRequest(
        classroomId: classroomId,
        attendanceDate: attendanceDate,
        syncTimestamp: DateTime.now().toIso8601String(),
        deviceId: deviceId,
        attendanceRecords: attendanceRecords,
      );

      final url = '${dotenv.get('mainUrl')}/api/students/attendance/facial/sync';
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final requestBody = syncRequest.toJson();
      
      debugPrint('=== POST Sync Facial Attendance Request ===');
      debugPrint('URL: $url');
      debugPrint('Headers: $headers');
      debugPrint('Syncing ${attendanceRecords.length} facial records for classroom: $classroomId');
      debugPrint('Body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('===========================================');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        String key = 'offline_facial_checkins_$classroomId';
        List<String> existingCheckins = prefs.getStringList(key) ?? [];

        existingCheckins.removeWhere((record) {
          var recordJson = json.decode(record);
          return checkIns.any((checkIn) =>
              recordJson['studentCode'] == checkIn.studentCode &&
              recordJson['timestamp'] == checkIn.timestamp.toIso8601String());
        });

        await prefs.setStringList(key, existingCheckins);
        debugPrint('Successfully synced facial records for classroom $classroomId');
        return true;
      } else {
        _showError('API error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _showError('Error syncing facial attendance records: $e');
      return false;
    }
  }

  Uint8List _floatToByte(List<double> embedding) {
    final buffer = ByteData(embedding.length * 4);
    for (int i = 0; i < embedding.length; i++) {
      buffer.setFloat32(i * 4, embedding[i]);
    }
    return buffer.buffer.asUint8List();
  }

  void _showError(String message) {
    debugPrint(message);
    Get.snackbar('Error', message, snackPosition: SnackPosition.BOTTOM);
  }
}
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:attendance/controllers/attendance_controller.dart';
import 'package:attendance/controllers/classroom_student_controller.dart';
import 'package:attendance/routes/routes.names.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:path_provider/path_provider.dart';

class AttendancePage extends StatefulWidget {
  final String? classroomId;
  final String? classroom;
  final String? attendanceId;

  const AttendancePage({
    Key? key,
    this.classroomId,
    this.classroom,
    this.attendanceId,
  }) : super(key: key);

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> with SingleTickerProviderStateMixin {
  // NFC scanning states
  bool isReading = false;
  bool isNfcAvailable = false;
  bool continuousScanning = true; // Flag to control continuous scanning
  
  // Animation controller for scan effect
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  
  // GetX controllers
  final AttendanceController _attendanceController = Get.find<AttendanceController>();
  final ClassroomStudentController _classroomStudentController = Get.find<ClassroomStudentController>();

  @override
  void initState() {
    super.initState();
    
    // Setup animation for the NFC scanning effect
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Validate required parameters
    _validateAndRedirectIfNeeded();
    
    // Initialize NFC
    checkNfcAvailability();
    
    // Fetch students data using GetX controller
    if (widget.classroom != null && widget.classroom!.isNotEmpty) {
      _classroomStudentController.getStudentsByClassroomId(widget.classroom!);
    }
    
    // Print debug info
    print('MakeAttendance screen initialized with:');
    print('ClassroomID: ${widget.classroomId}');
    print('Classroom: ${widget.classroom}');
    print('AttendanceID: ${widget.attendanceId}');
    
    _setupControllerListeners();
  }
  
  void _setupControllerListeners() {
    // Listen for success messages from the controller
    ever(_attendanceController.successMessage, (message) {
      if (message.isNotEmpty) {
        // Wait a moment to ensure UI is stable
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Get.snackbar(
              'Success',
              message,
              backgroundColor: Colors.green,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
            
            // Increment check-in counter
            _attendanceController.checkInCount.value++;
          }
        });
      }
    });
    
    // Listen for error messages from the controller
    ever(_attendanceController.errorMessage, (message) {
      if (message.isNotEmpty) {
        // Wait a moment to ensure UI is stable
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            Get.snackbar(
              'Error',
              message,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 3),
            );
          }
        });
      }
    });
    
    // Listen for last checked-in student to update UI
    ever(_attendanceController.lastCheckedInStudent, (studentId) {
      if (studentId.isNotEmpty) {
        // Update UI or perform any actions when a student is checked in
        print('Student checked in: $studentId');
      }
    });
  }

  // Validate parameters and redirect if needed
  void _validateAndRedirectIfNeeded() {
    // Check if we have all the required parameters
    if (widget.attendanceId == null || widget.attendanceId!.isEmpty) {
      print('Missing attendance ID - checking controller');
      
      // Try to get from controller
      final attendanceId = _attendanceController.getAttendanceId();
      
      if (attendanceId.isNotEmpty) {
        print('Found attendance ID in controller: $attendanceId');
        
        // We have the ID from controller, but need to redirect to include it in URL
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAndToNamed(
            makeAttendance,
            parameters: {
              'classroomId': widget.classroomId ?? '',
              'classroom': widget.classroom ?? '',
              'attendanceId': attendanceId,
            }
          );
        });
        return;
      }
      
      // If we can't get the attendance ID, show an error and go back to home
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.snackbar(
          'Error',
          'Missing attendance ID. Please create attendance again.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        
        // Delay navigation slightly to show the snackbar
        Future.delayed(const Duration(milliseconds: 1500), () {
          Get.offAllNamed(home);
        });
      });
    }
  }

  Future<void> checkNfcAvailability() async {
    try {
      isNfcAvailable = await NfcManager.instance.isAvailable();
      setState(() {});
      if (isNfcAvailable) {
        startNfcSession();
      }
    } catch (e) {
      debugPrint('NFC Availability Error: $e');
      setState(() {
        isNfcAvailable = false;
      });
    }
  }
  
  // Function to handle continuous NFC scanning
  Future<void> startNfcSession() async {
    if (!isNfcAvailable) {
      Get.snackbar(
        'NFC Error',
        'NFC is not available on this device',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() {
      isReading = true;
    });

    try {
      // Stop any existing NFC session first
      await NfcManager.instance.stopSession();
      
      print('Starting NFC session for continuous scanning');
      
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            // Extract the tag ID
            final tagId = tag.data['nfca']?['identifier'] ??
                tag.data['isodep']?['identifier'] ??
                tag.data['mifareclassic']?['identifier'] ??
                tag.data['mifareultralight']?['identifier'];

            if (tagId != null) {
              // Convert byte array to hex string
              final cardId = tagId
                  .map((e) => e.toRadixString(16).padLeft(2, '0'))
                  .join('');
                  
              print('Card detected: $cardId');

              // Get student ID from card ID
              final studentId = await getStudentIdFromCard(
                  widget.classroom.toString(), cardId);

              if (studentId != null) {
                print('Found student with ID: $studentId');
                
                // Process the check-in with the controller
                await _attendanceController.checkInStudent(
                  studentId: studentId,
                  classroomId: widget.classroomId.toString(),
                  attendanceId: widget.attendanceId.toString(),
                );
                
                // Temporarily stop the session to give feedback
                await NfcManager.instance.stopSession();
                
                // Vibrate to give tactile feedback for successful scan
                HapticFeedback.mediumImpact();
                
                // Give the system a short break to process and show feedback
                await Future.delayed(const Duration(milliseconds: 1500));
                
                // Restart the NFC session for continuous scanning
                if (continuousScanning && mounted) {
                  startNfcSession();
                }
              } else {
                // Card not registered to any student
                // Temporarily stop the session to give feedback
                await NfcManager.instance.stopSession();
                
                // Vibrate to indicate error
                HapticFeedback.heavyImpact();
                
                Get.snackbar(
                  'Unknown Card',
                  'This card is not registered to any student',
                  backgroundColor: Colors.orange,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 2),
                );
                
                // Restart the NFC session after a short delay
                await Future.delayed(const Duration(milliseconds: 1500));
                if (continuousScanning && mounted) {
                  startNfcSession();
                }
              }
            }
          } catch (e) {
            debugPrint('Error processing NFC tag: $e');
            
            // Use GetX for showing error messages
            Get.snackbar(
              'Error',
              'Error processing card: $e',
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
            
            // Restart the NFC session after error
            await Future.delayed(const Duration(milliseconds: 1500));
            if (continuousScanning && mounted) {
              startNfcSession();
            }
          }
        },
        // Configure NFC read mode for optimal performance
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
        },
      );
    } catch (e) {
      debugPrint('NFC Session Error: $e');
      setState(() {
        isReading = false;
      });
      
      Get.snackbar(
        'NFC Error',
        'Failed to start NFC scanning: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      
      // Try to restart the session after an error
      await Future.delayed(const Duration(seconds: 3));
      if (continuousScanning && mounted) {
        startNfcSession();
      }
    }
  }

  // Function to get student ID from card ID
  Future<String?> getStudentIdFromCard(String classroom, String cardId) async {
    try {
      // First try to get it from the controller
      final studentData = await _classroomStudentController.getStudentByCardId(classroom, cardId);
      if (studentData != null) {
        return studentData.id;
      }
      
      // If not found in controller, try fallback methods
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/students.json');
      
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> students = jsonDecode(jsonString);
        
        for (var student in students) {
          if (student['cardId'] == cardId && student['classroom'] == classroom) {
            return student['id'];
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting student ID: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classroom ?? 'Attendance'),
        centerTitle: true,
        actions: [
          // Add a counter for check-ins
          Obx(() => Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                'Check-ins: ${_attendanceController.checkInCount.value}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ))
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Scan Student Card',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (isNfcAvailable)
              Stack(
                alignment: Alignment.center,
                children: [
                  // NFC Icon with animation
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: isReading ? Colors.green.withOpacity(0.7) : Colors.grey.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.nfc,
                              size: 100,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  // Latest student checked in
                  Positioned(
                    bottom: 0,
                    child: Obx(() {
                      final lastStudent = _attendanceController.lastCheckedInStudent.value;
                      if (lastStudent.isEmpty) return const SizedBox.shrink();
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Last: $lastStudent',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }),
                  ),
                ],
              )
            else
              const Column(
                children: [
                  Icon(
                    Icons.nfc,
                    size: 100,
                    color: Colors.red,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'NFC is not available on this device',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ],
              ),
            
            const SizedBox(height: 30),
            
            // Status indicator
            Obx(() => Container(
              height: 60,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: _attendanceController.isLoading.value 
                  ? Colors.orange 
                  : (_attendanceController.successMessage.value.isNotEmpty 
                    ? Colors.green 
                    : Colors.blue),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _attendanceController.isLoading.value 
                    ? 'Processing...' 
                    : (_attendanceController.successMessage.value.isNotEmpty 
                      ? 'Ready for next scan' 
                      : 'Waiting for card'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    _animationController.dispose();
    super.dispose();
  }
}

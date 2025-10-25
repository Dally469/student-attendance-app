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
    
    // Load current checked-in students
    if (widget.attendanceId != null && widget.attendanceId!.isNotEmpty) {
      _attendanceController.loadCurrentAttendanceStudents(widget.attendanceId!);
    }
    
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
            final title = message.toLowerCase().contains('check-out') ? 'Checked Out' : 'Success';
            Get.snackbar(
              title,
              message,
              backgroundColor: message.toLowerCase().contains('check-out') ? Colors.orange : Colors.green,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
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
    ever(_attendanceController.lastCheckedInStudentName, (name) {
      if (name.isNotEmpty) {
        // Update UI or perform any actions when a student is checked in
        print('Student checked in: $name');
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
                
                // Check if already checked in
                final alreadyCheckedIn = _attendanceController.checkedInStudents.contains(studentId);
                
                if (alreadyCheckedIn) {
                  // Perform check-out
                  // await _attendanceController.checkOutStudent(
                  //   studentId: studentId,
                  //   classroomId: widget.classroomId.toString(),
                  //   attendanceId: widget.attendanceId.toString(),
                  // );

                    await _attendanceController.checkInStudent(
                    studentId: studentId,
                    classroomId: widget.classroomId.toString(),
                    attendanceId: widget.attendanceId.toString(),
                  );
                } else {
                  // Perform check-in
                  await _attendanceController.checkInStudent(
                    studentId: studentId,
                    classroomId: widget.classroomId.toString(),
                    attendanceId: widget.attendanceId.toString(),
                  );
                }
                
                // Temporarily stop the session to give feedback
                await NfcManager.instance.stopSession();
                
                // Vibrate to give tactile feedback
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
    final theme = Theme.of(context);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              widget.classroom ?? 'Attendance',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          // Check-in counter with animated container
          Obx(() => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(right: 16.0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_attendanceController.checkInCount.value}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.2),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Stats dashboard
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          icon: Icons.people_alt_outlined,
                          value: _classroomStudentController.students.length.toString(),
                          label: 'Total',
                          color: theme.colorScheme.primary,
                        ),
                        _buildDivider(),
                        Obx(() => _buildStatColumn(
                          icon: Icons.check_circle_outline,
                          value: _attendanceController.checkInCount.value.toString(),
                          label: 'Present',
                          color: Colors.green,
                        )),
                        _buildDivider(),
                        Obx(() => _buildStatColumn(
                          icon: Icons.cancel_outlined,
                          value: ((_classroomStudentController.students.length) - _attendanceController.checkInCount.value).toString(),
                          label: 'Absent',
                          color: Colors.redAccent,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Scan Student Card',
                        style: GoogleFonts.poppins(
                          fontSize: 24, 
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hold NFC card close to the back of your device',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // NFC Scanning visualization
                      if (isNfcAvailable)
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background rings
                            ...[0.6, 0.8, 1.0].map((opacity) => AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                final scale = _pulseAnimation.value * (1.0 + (1.0 - opacity) * 0.3);
                                return Opacity(
                                  opacity: opacity,
                                  child: Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isReading 
                                            ? theme.colorScheme.primary
                                            : Colors.grey.withOpacity(0.5),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )),
                            
                            // Central NFC Icon
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: isReading
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: isReading
                                      ? theme.colorScheme.primary.withOpacity(0.3)
                                      : Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.contactless_rounded,
                                  size: 70,
                                  color: isReading ? Colors.white : theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.not_interested,
                                size: 70,
                                color: Colors.red.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'NFC Unavailable',
                                style: GoogleFonts.poppins(
                                  color: Colors.red.shade300,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Last scanned student card
              Obx(() {
                final lastName = _attendanceController.lastCheckedInStudentName.value;
                final lastCode = _attendanceController.lastCheckedInStudentCode.value;
                if (lastName.isEmpty) {
                  return const SizedBox(height: 100);
                }
                
                return Container(
                  margin: const EdgeInsets.all(16),
                  height: 100,
                  width: double.infinity,
                  child: Card(
                    elevation: 0,
                    color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Avatar or initials
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              lastName.isNotEmpty 
                                ? lastName.substring(0, 1).toUpperCase()
                                : "?",
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Last Check-in",
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.black45,
                                  ),
                                ),
                                Text(
                                  lastName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                // Text(
                                //   'Code: $lastCode',
                                //   style: GoogleFonts.poppins(
                                //     fontSize: 14,
                                //     color: Colors.black54,
                                //     fontWeight: FontWeight.w500,
                                //   ),
                                // ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Present',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              
              // Status indicator
              Obx(() => Container(
                height: 60,
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _attendanceController.isLoading.value 
                      ? [Colors.orange.shade300, Colors.orange.shade500]
                      : (_attendanceController.successMessage.value.isNotEmpty 
                        ? [Colors.green.shade300, Colors.green.shade500] 
                        : [theme.colorScheme.primary.withOpacity(0.7), theme.colorScheme.primary]),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _attendanceController.isLoading.value 
                        ? Icons.hourglass_top_rounded
                        : (_attendanceController.successMessage.value.isNotEmpty 
                          ? Icons.check_circle_outline
                          : Icons.contactless_rounded),
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _attendanceController.isLoading.value 
                        ? 'Processing...' 
                        : (_attendanceController.successMessage.value.isNotEmpty 
                          ? 'Ready for next scan' 
                          : 'Waiting for card'),
                      style: GoogleFonts.poppins(
                        color: Colors.white, 
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper method to build stat columns
  Widget _buildStatColumn({required IconData icon, required String value, required String label, required Color color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
  
  // Helper method to build vertical dividers
  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.withOpacity(0.3),
    );
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    _animationController.dispose();
    super.dispose();
  }
}
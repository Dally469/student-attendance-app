// lib/screens/create_attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/attendance_controller.dart';
import '../utils/colors.dart';
 
class CreateAttendanceScreen extends StatelessWidget {
  final String? classroomId;

  const CreateAttendanceScreen({
    Key? key,
    this.classroomId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AttendanceController attendanceController = Get.find<AttendanceController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Attendance'),
        backgroundColor: primaryColor,
      ),
      body: Obx(() {
        if (attendanceController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        } else {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 64,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Create a new attendance record',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This will create a new attendance record for the selected classroom',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    ),
                    onPressed: () {
                      if (classroomId != null) {
                        attendanceController.createAttendance(classroomId!);
                        
                        // Setup listener for completion
                        ever(attendanceController.currentAttendance, (attendance) {
                          if (attendance != null) {
                            Get.snackbar(
                              'Success', 
                              'Attendance created successfully',
                              backgroundColor: Colors.green.withOpacity(0.7),
                              colorText: Colors.white,
                            );
                            Get.back();
                          }
                        });
                      } else {
                        Get.snackbar(
                          'Error', 
                          'No classroom selected',
                          backgroundColor: Colors.red.withOpacity(0.7),
                          colorText: Colors.white,
                        );
                      }
                    },
                    child: const Text('Create Attendance', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          );
        }
      }),
    );
  }
}

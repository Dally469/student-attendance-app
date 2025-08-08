// lib/screens/create_attendance_screen.dart
import 'dart:async';
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
                    onPressed: () async {
                      if (classroomId != null) {
                        // First, remove any existing listener to avoid duplicates
                        attendanceController.successMessage.listen((message) {}).cancel();
                        
                        // Declare the subscription variable first
                        late final StreamSubscription<String> subscription;
                        
                        // Setup proper listeners BEFORE initiating the action
                        // Listen to success message instead of the object itself
                        subscription = attendanceController.successMessage.listen((message) {
                          if (message.isNotEmpty) {
                            // Add delay before UI updates as per best practices
                            Future.delayed(const Duration(milliseconds: 300), () {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(message),
                                    backgroundColor: Colors.green,
                                  )
                                );
                                
                                // Navigate back safely using context
                                Navigator.of(context).pop();
                              }
                            });
                            
                            // Clean up the subscription
                            subscription.cancel();
                          }
                        });
                        
                        // Now execute the action
                        await attendanceController.createAttendance(classroomId!);
                      } else {
                        // Show error directly since we're not in a reactive context
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No classroom selected'),
                            backgroundColor: Colors.red,
                          )
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

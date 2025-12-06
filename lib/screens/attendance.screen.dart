import 'package:attendance/controllers/classroom_student_controller.dart';
import 'package:attendance/controllers/attendance_controller.dart';
import 'package:attendance/routes/routes.names.dart';
import 'package:attendance/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class MakeAttendanceScreen extends StatefulWidget {
  final String? classroomId;
  final String? classroom;
  const MakeAttendanceScreen({super.key, this.classroomId, this.classroom});

  @override
  State<MakeAttendanceScreen> createState() => _MakeAttendanceScreenState();
}

class _MakeAttendanceScreenState extends State<MakeAttendanceScreen> {
  final ClassroomStudentController _studentController =
      Get.find<ClassroomStudentController>();
  final AttendanceController _attendanceController =
      Get.find<AttendanceController>();

  @override
  void initState() {
    super.initState();

    // Fetch students using GetX controller
    _studentController.getStudentsByClassroomId(widget.classroom.toString());

    // Listen for attendance creation success
    ever(_attendanceController.successMessage, (message) {
      if (message.isNotEmpty &&
          (message.toLowerCase().contains('created') ||
              message.toLowerCase().contains('success'))) {
        // Wait a bit to ensure attendance ID is set
        Future.delayed(const Duration(milliseconds: 500), () {
          final attendanceId = _attendanceController.getAttendanceId();
          if (attendanceId.isNotEmpty && mounted) {
            // Navigate to make attendance screen
            Get.offNamed(makeAttendance, parameters: {
              'classroomId': widget.classroomId ?? '',
              'classroom': widget.classroom ?? '',
              'attendanceId': attendanceId,
            });
          } else if (mounted) {
            // Try to get attendance ID from current attendance
            final currentAttendanceId =
                _attendanceController.currentAttendance.value?.data?.id;
            if (currentAttendanceId != null && currentAttendanceId.isNotEmpty) {
              Get.offNamed(makeAttendance, parameters: {
                'classroomId': widget.classroomId ?? '',
                'classroom': widget.classroom ?? '',
                'attendanceId': currentAttendanceId,
              });
            }
          }
        });
      }
    });

    // Listen for errors
    ever(_attendanceController.errorMessage, (message) {
      if (message.isNotEmpty) {
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

  Future<bool> _onWillPop() async {
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 0,
          toolbarHeight: 100,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.classroom.toString(),
                style:
                    const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Obx(() => Text(
                    "Total students: ${_studentController.students.length}",
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  )),
            ],
          ),
        ),
        body: Obx(() {
          if (_studentController.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          } else {
            final isCreating = _attendanceController.isCreatingAttendance.value;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      disabledBackgroundColor: primaryColor.withOpacity(0.5),
                    ),
                    onPressed: isCreating
                        ? null
                        : () {
                            if (widget.classroomId != null &&
                                widget.classroomId!.isNotEmpty) {
                              _attendanceController
                                  .createAttendance(widget.classroomId!);
                            } else {
                              Get.snackbar(
                                'Error',
                                'Classroom ID is missing',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          },
                    child: isCreating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            "Create Attendance",
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                  ),
                  if (isCreating) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Creating attendance...',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }
        }),
        bottomSheet: Container(
          color: whiteColor,
          height: 40,
          child: Center(
            child: Text(
              "Powered by Besoft & BePay ltd",
              style: GoogleFonts.poppins(fontSize: 12, color: blackColor),
            ),
          ),
        ),
      ),
    );
  }
}

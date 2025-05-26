import 'package:attendance/controllers/classroom_student_controller.dart';
import 'package:attendance/controllers/attendance_controller.dart';
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
  final ClassroomStudentController _studentController = Get.find<ClassroomStudentController>();
  final AttendanceController _attendanceController = Get.find<AttendanceController>();

  @override
  void initState() {
    super.initState();
    
    // Fetch students using GetX controller
    _studentController.getStudentsByClassroomId(widget.classroom.toString());
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
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
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
            return Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                onPressed: () {
                  if (widget.classroomId != null) {
                    _attendanceController.createAttendance(widget.classroomId!);
                  }
                },
                child: Text(
                  "Create Attendance",
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
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

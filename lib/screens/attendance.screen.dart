import 'package:attendance/api/auth.service.dart';
import 'package:attendance/states/classroom.student/classroom_student_bloc.dart';
import 'package:attendance/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class MakeAttendanceScreen extends StatefulWidget {
  final String? classroomId;
  final String? classroom;
  const MakeAttendanceScreen({super.key, this.classroomId, this.classroom});

  @override
  State<MakeAttendanceScreen> createState() => _MakeAttendanceScreenState();
}

class _MakeAttendanceScreenState extends State<MakeAttendanceScreen> {
  ClassroomStudentBloc classroomStudentBloc =
      ClassroomStudentBloc(ClassroomStudentInitial(), AuthService());

  @override
  void initState() {
    super.initState();
    classroomStudentBloc = BlocProvider.of<ClassroomStudentBloc>(context);
  }

  Future<bool> _onWillPop() async {
    return false;
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();

    classroomStudentBloc.add(
        FetchClassroomStudentEvent(classroom: widget.classroom.toString()));
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
          toolbarHeight: 100, // Set the height of the AppBar
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "${widget.classroom.toString()}",
                style:
                    const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
            ],
          ),
        ),
        body: const Column(children: []),
        bottomSheet: Container(
          color: whiteColor,
          height: 40,
          child: Center(
            child: Text(
              "Powerd by Besoft & BePay ltd",
              style: GoogleFonts.poppins(fontSize: 12, color: blackColor),
            ),
          ),
        ),
      ),
    );
  }
}

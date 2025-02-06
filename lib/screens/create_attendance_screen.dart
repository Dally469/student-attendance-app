// lib/screens/create_attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../states/attendance/attendance_bloc.dart';
import '../states/attendance/attendance_event.dart';
import '../states/attendance/attendance_state.dart';
 
class CreateAttendanceScreen extends StatelessWidget {
  final String? classroomId;

  const CreateAttendanceScreen({
    Key? key,
      this.classroomId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Attendance'),
      ),
      body: BlocConsumer<CreateAttendanceBloc, AttendanceState>(
        listener: (context, state) {
          if (state is AttendanceSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Attendance created successfully')),
            );
            Navigator.pop(context);
          } else if (state is AttendanceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is AttendanceLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Center(
            child: ElevatedButton(
              onPressed: () {
                context.read<CreateAttendanceBloc>().add(
                      CreateAttendanceEvent(classroomId: classroomId.toString()),
                    );
              },
              child: const Text('Create Attendance'),
            ),
          );
        },
      ),
    );
  }
}

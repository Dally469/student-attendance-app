// lib/blocs/attendance/attendance_event.dart
import 'package:equatable/equatable.dart';

abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object> get props => [];
}

class StartEvent extends AttendanceEvent {}

class CreateAttendanceEvent extends AttendanceEvent {
  final String classroomId;

  const CreateAttendanceEvent({required this.classroomId});

  @override
  List<Object> get props => [classroomId];
}

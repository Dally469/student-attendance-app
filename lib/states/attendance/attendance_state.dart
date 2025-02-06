// lib/blocs/attendance/attendance_state.dart
import 'package:equatable/equatable.dart';
import '../../models/attendance.dart';


abstract class AttendanceState extends Equatable {
  const AttendanceState();
  
  @override
  List<Object> get props => [];
}

class CreateAttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceSuccess extends AttendanceState {
  final AttendanceModel attendanceModel;

  const AttendanceSuccess({required this.attendanceModel});

  @override
  List<Object> get props => [attendanceModel];
}

class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError({required this.message});

  @override
  List<Object> get props => [message];
}
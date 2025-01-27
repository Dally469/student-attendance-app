
part of 'make_attendance_bloc.dart';


abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();

  @override
  List<Object> get props => [];
}

class StartAttendanceEvent extends AttendanceEvent {}

class CheckInEvent extends AttendanceEvent {
  final String studentId;
  final String classroomId;
  final String attendanceId;

  const CheckInEvent({
    required this.studentId,
    required this.classroomId,
    required this.attendanceId,
  });

  @override
  List<Object> get props => [studentId, classroomId, attendanceId];
}

class SyncOfflineDataEvent extends AttendanceEvent {}

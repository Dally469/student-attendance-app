// lib/blocs/attendance/attendance_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../api/auth.service.dart';
import '../../models/attendance.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class CreateAttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AuthService authService;

  CreateAttendanceBloc(AttendanceState initialState, this.authService)
      : super(initialState) {
    on<AttendanceEvent>((event, emit) async {
      if (event is StartEvent) {
        emit(CreateAttendanceInitial());
      } else {
        if (event is CreateAttendanceEvent) {
          emit(AttendanceLoading());

          try {
            AttendanceModel attendanceModel =
                await authService.createAttendance(event.classroomId);

            if (attendanceModel.id != null && attendanceModel.id!.isNotEmpty) {
              emit(AttendanceSuccess(attendanceModel: attendanceModel));
            } else {
              emit(AttendanceError(
                  message: attendanceModel.message ??
                      'Failed to create attendance'));
            }
          } catch (e) {
            emit(AttendanceError(message: e.toString()));
          }
        }
      }
    });
  }
}

import 'dart:async';

import 'package:attendance/api/attendance.service.dart';
import 'package:attendance/api/auth.service.dart';
import 'package:attendance/models/check.in.model.dart';
import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';

part 'make_attendance_event.dart';
part 'make_attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceService attendanceService;
  Timer? _syncTimer;
  StreamSubscription? _connectivitySubscription;

  AttendanceBloc(this.attendanceService) : super(AttendanceInitial()) {
    // Start periodic sync
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      add(SyncOfflineDataEvent());
    });

    // Listen to connectivity changes
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        add(SyncOfflineDataEvent());
      }
    });

    on<CheckInEvent>(_onCheckIn);
    on<SyncOfflineDataEvent>(_onSyncOfflineData);
    on<StartAttendanceEvent>(_onStartAttendance);
  }

  Future<void> _onCheckIn(
    CheckInEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceLoading());
    try {
      final result = await attendanceService.markAttendance(
        studentId: event.studentId,
        classroomId: event.classroomId,
        attendanceId: event.attendanceId,
      );

      if (result.success) {
        emit(AttendanceSuccess(
          checkInModel: result,
          isOffline:
              result.data == null, // If data is null, it was stored offline
        ));
      } else {
        emit(AttendanceError(message: result.message));
      }
    } catch (e) {
      emit(AttendanceError(message: e.toString()));
    }
  }

  Future<void> _onSyncOfflineData(
    SyncOfflineDataEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    if (state is AttendanceLoading) return;

    try {
      final bool syncResult = await attendanceService.syncOfflineCheckIns();
      if (syncResult) {
        // Only emit if we're not in the middle of another operation
        if (state is! AttendanceLoading) {
          emit(OfflineDataSynced());
          emit(AttendanceInitial());
        }
      }
    } catch (e) {
      print('Sync error: $e');
    }
  }

  Future<void> _onStartAttendance(
    StartAttendanceEvent event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(AttendanceInitial());
  }

  @override
  Future<void> close() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    return super.close();
  }
}

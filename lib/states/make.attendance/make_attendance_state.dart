part of 'make_attendance_bloc.dart';

abstract class AttendanceState extends Equatable {
  const AttendanceState();

  @override
  List<Object> get props => [];
}

class AttendanceInitial extends AttendanceState {}

class AttendanceLoading extends AttendanceState {}

class AttendanceSuccess extends AttendanceState {
  final CheckInModel checkInModel;
  final bool isOffline;

  const AttendanceSuccess({
    required this.checkInModel,
    this.isOffline = false,
  });

  @override
  List<Object> get props => [checkInModel, isOffline];
}

class AttendanceError extends AttendanceState {
  final String message;

  const AttendanceError({required this.message});

  @override
  List<Object> get props => [message];
}

class OfflineDataSynced extends AttendanceState {}

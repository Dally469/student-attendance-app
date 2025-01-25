// ignore_for_file: must_be_immutable

part of 'school_classroom_bloc.dart';

abstract class SchoolClassroomState extends Equatable {
  const SchoolClassroomState();
  
  @override
  List<Object> get props => [];
}
class SchoolClassroomInitial extends SchoolClassroomState {}


class SchoolClassroomLoading extends SchoolClassroomState {}


class SchoolClassroomSuccess extends SchoolClassroomState {
  SchoolClassroomModel schoolClassroomModel;
  SchoolClassroomSuccess({
    required this.schoolClassroomModel,
  });
}

class SchoolClassroomError extends SchoolClassroomState {
  String message;
  SchoolClassroomError({
    required this.message,
  });
}

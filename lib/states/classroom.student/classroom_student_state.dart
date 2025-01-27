// ignore_for_file: must_be_immutable

part of 'classroom_student_bloc.dart';

abstract class ClassroomStudentState extends Equatable {
  const ClassroomStudentState();
  
  @override
  List<Object> get props => [];
}
class ClassroomStudentInitial extends ClassroomStudentState {}


class ClassroomStudentLoading extends ClassroomStudentState {}


class ClassroomStudentSuccess extends ClassroomStudentState {
  StudentModel studentModel;
  ClassroomStudentSuccess({
    required this.studentModel,
  });
}

class ClassroomStudentError extends ClassroomStudentState {
  String message;
  ClassroomStudentError({
    required this.message,
  });
}

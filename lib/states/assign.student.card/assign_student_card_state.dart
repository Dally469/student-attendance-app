// ignore_for_file: must_be_immutable

part of 'assign_student_card_bloc.dart';

abstract class AssignStudentCardState extends Equatable {
  const AssignStudentCardState();

  @override
  List<Object> get props => [];
}

class AssignStudentCardInitial extends AssignStudentCardState {}

class AssignStudentCardLoading extends AssignStudentCardState {}

class AssignStudentCardSuccess extends AssignStudentCardState {
  SingleStudentModel studentModel;
  AssignStudentCardSuccess({
    required this.studentModel,
  });
}

class AssignStudentCardError extends AssignStudentCardState {
  String message;
  AssignStudentCardError({
    required this.message,
  });
}

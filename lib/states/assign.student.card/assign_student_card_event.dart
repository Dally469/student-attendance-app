part of 'assign_student_card_bloc.dart';


abstract class AssignStudentCardEvent extends Equatable {
  const AssignStudentCardEvent();

  @override
  List<Object> get props => [];
}


class StartEvent extends AssignStudentCardEvent {
}

class HandleAssignStudentCardEvent extends AssignStudentCardEvent {
  final String studentCode;
  final String cardId;

  const HandleAssignStudentCardEvent({required this.studentCode, required this.cardId});
}

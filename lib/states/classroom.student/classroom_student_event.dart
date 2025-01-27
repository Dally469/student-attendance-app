part of 'classroom_student_bloc.dart';


abstract class ClassroomStudentEvent extends Equatable {
  const ClassroomStudentEvent();

  @override
  List<Object> get props => [];
}


class StartEvent extends ClassroomStudentEvent {


}

class FetchClassroomStudentEvent extends ClassroomStudentEvent {
  final String classroom;
  const FetchClassroomStudentEvent({required this.classroom});
}

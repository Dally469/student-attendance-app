part of 'school_classroom_bloc.dart';


abstract class SchoolClassroomEvent extends Equatable {
  const SchoolClassroomEvent();

  @override
  List<Object> get props => [];
}


class StartEvent extends SchoolClassroomEvent {


}

class FetchSchoolClassroomEvent extends SchoolClassroomEvent {
  final String token;
  FetchSchoolClassroomEvent({required this.token});
}

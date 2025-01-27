import 'package:attendance/api/auth.service.dart';
import 'package:attendance/models/classroom.model.dart';
import 'package:attendance/models/student.model.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';



part 'classroom_student_event.dart';
part 'classroom_student_state.dart';

class ClassroomStudentBloc
    extends Bloc<ClassroomStudentEvent, ClassroomStudentState> {
  AuthService locationService;
  ClassroomStudentBloc(
      ClassroomStudentState availableDriverLocationState,
      this.locationService)
      : super(availableDriverLocationState) {
    on<ClassroomStudentEvent>((event, emit) async {
      if (event is StartEvent) {
        emit(ClassroomStudentInitial());
      } else {
        if (event is FetchClassroomStudentEvent) {
          emit(ClassroomStudentLoading());
          StudentModel schoolClassroomModel;
          schoolClassroomModel =
              await locationService.fetchStudents(
                event.classroom,
              );
          if (schoolClassroomModel.success) {
            emit(ClassroomStudentSuccess(
                studentModel: schoolClassroomModel));
          } else {
            emit(ClassroomStudentError(
                message: schoolClassroomModel.message.toString()));
          }
        }
      }
    });
  }
}

import 'package:attendance/api/auth.service.dart';
import 'package:attendance/models/single.student.model.dart';
import 'package:attendance/models/student.model.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';



part 'assign_student_card_event.dart';
part 'assign_student_card_state.dart';

class AssignStudentCardBloc
    extends Bloc<AssignStudentCardEvent, AssignStudentCardState> {
  AuthService locationService;
  AssignStudentCardBloc(
      AssignStudentCardState availableDriverLocationState,
      this.locationService)
      : super(availableDriverLocationState) {
    on<AssignStudentCardEvent>((event, emit) async {
      if (event is StartEvent) {
        emit(AssignStudentCardInitial());
      } else {
        if (event is HandleAssignStudentCardEvent) {
          emit(AssignStudentCardLoading());
          SingleStudentModel studentModel;
          studentModel =
              await locationService.assignCardToStudents(
                event.studentCode,event.cardId
              );
          if (studentModel.success) {
            emit(AssignStudentCardSuccess(
                studentModel: studentModel));
          } else {
            emit(AssignStudentCardError(
                message: studentModel.message.toString()));
          }
        }
      }
    });
  }
}

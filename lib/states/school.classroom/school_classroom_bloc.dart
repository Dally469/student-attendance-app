import 'package:attendance/api/auth.service.dart';
import 'package:attendance/models/classroom.model.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';



part 'school_classroom_event.dart';
part 'school_classroom_state.dart';

class SchoolClassroomBloc
    extends Bloc<SchoolClassroomEvent, SchoolClassroomState> {
  AuthService locationService;
  SchoolClassroomBloc(
      SchoolClassroomState availableDriverLocationState,
      this.locationService)
      : super(availableDriverLocationState) {
    on<SchoolClassroomEvent>((event, emit) async {
      if (event is StartEvent) {
        emit(SchoolClassroomInitial());
      } else {
        if (event is FetchSchoolClassroomEvent) {
          emit(SchoolClassroomLoading());
          SchoolClassroomModel schoolClassroomModel;
          schoolClassroomModel =
              await locationService.fetchSchoolClassrooms(
                event.token,
              );
          if (schoolClassroomModel.success) {
            emit(SchoolClassroomSuccess(
                schoolClassroomModel: schoolClassroomModel));
          } else {
            emit(SchoolClassroomError(
                message: schoolClassroomModel.message.toString()));
          }
        }
      }
    });
  }
}

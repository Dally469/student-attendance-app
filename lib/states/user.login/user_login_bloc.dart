import 'package:attendance/api/auth.service.dart';
import 'package:attendance/models/user.login.model.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';


part 'user_login_event.dart';
part 'user_login_state.dart';

class UserLoginBloc extends Bloc<UserLoginEvent, UserLoginState> {
  AuthService authService;

  UserLoginBloc(UserLoginState userLoginState, this.authService)
      : super(userLoginState) {
    on<UserLoginEvent>((event, emit) async {
      if (event is StartEvent) {
        emit(UserLoginInitial());
      } else {
        if (event is HandleUSerLogin) {
          emit(UserLoginLoading());
          UserLoginModel model;
          model =
              await authService.postClientLogin(event.username, event.password);
          if (model.success) {
            emit(UserLoginSuccess(userLoginModel: model));
          } else {
            emit(UserLoginError(message: model.message.toString()));
          }
        }
      }
    });
  }
}

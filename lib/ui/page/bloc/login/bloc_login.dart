// login_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fyp_mrsteam_web/core/config/get_it.dart';
import 'package:fyp_mrsteam_web/core/util/app_preferences.dart';
import 'package:fyp_mrsteam_web/data/model/response/res_login.dart';
import 'package:fyp_mrsteam_web/data/repo/repo_auth.dart';
import 'package:fyp_mrsteam_web/ui/page/bloc/login/event_login.dart';
import 'package:fyp_mrsteam_web/ui/page/bloc/login/state_login.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(const LoginState()) {
    on<UsernameChanged>(
      (e, emit) => emit(state.copyWith(username: e.username)),
    );
    on<PasswordChanged>(
      (e, emit) => emit(state.copyWith(password: e.password)),
    );
    on<LoginSubmitted>(_onLogin);
  }

  Future<void> _onLogin(LoginSubmitted e, Emitter<LoginState> emit) async {
    emit(state.copyWith(loading: true));
    try {
      LoginRes res = await getIt<AuthRepo>().login(
        state.username,
        state.password,
      );

      await AppPreferences.setAccessToken(res.accessToken);
      await AppPreferences.setRefreshToken(res.refreshToken);
      await AppPreferences.setSessionId(res.sessionId);
      await AppPreferences.setUserId(res.user.id);

      emit(state.copyWith(loading: false));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }
}

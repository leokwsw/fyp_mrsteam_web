import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:fyp_mrsteam_web/core/config/get_it.dart';
import 'package:fyp_mrsteam_web/core/util/app_preferences.dart';
import 'package:fyp_mrsteam_web/data/repo/repo_auth.dart';
import 'package:fyp_mrsteam_web/ui/page/bloc/home/event_home.dart';
import 'package:fyp_mrsteam_web/ui/page/bloc/home/state_home.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeState()) {
    on<LogoutSubmitted>(_onLogout);
  }

  Future<void> _onLogout(LogoutSubmitted e, Emitter<HomeState> emit) async {
    emit(state.copyWith(loading: true));

    String sessionId = AppPreferences.getSessionId();

    try {
      await getIt<AuthRepo>().logout(sessionId);

      if (kDebugMode) {
        // print(res);
      }

      await AppPreferences.clear();

      emit(state.copyWith(loading: false));
    } catch (err) {
      emit(state.copyWith(loading: false, error: err.toString()));
    }
  }
}

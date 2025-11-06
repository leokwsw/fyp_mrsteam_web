// lib/app_router.dart
import 'package:flutter/material.dart';
import 'package:fyp_mrsteam_web/core/util/app_preferences.dart';
import 'package:fyp_mrsteam_web/ui/page/page_home.dart';
import 'package:fyp_mrsteam_web/ui/page/page_login.dart';
import 'package:fyp_mrsteam_web/ui/page/page_splash.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  late final GoRouter router;

  AppRouter() {
    router = _createRouter();
  }

  GoRouter _createRouter() {
    // final auth = getIt<AuthNotifier>();

    return GoRouter(
      initialLocation: '/',
      // refreshListenable: auth,              // auth 變化時觸發 redirect
      routes: [
        GoRoute(
          path: '/',
          name: 'splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const LoginPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final offsetTween = Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeOutCubic));
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: animation.drive(offsetTween),
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 280),
          ),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const HomePage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final offsetTween = Tween<Offset>(
                    begin: const Offset(0.06, 0),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeOutCubic));
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: animation.drive(offsetTween),
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        ),
      ],
      redirect: (context, state) {
        final atLogin = state.fullPath == '/login';
        final atSplash = state.fullPath == '/';
        
        print(atSplash);

        final hasAll =
            AppPreferences.getAccessToken().isNotEmpty &&
            AppPreferences.getRefreshToken().isNotEmpty &&
            AppPreferences.getSessionId().isNotEmpty &&
            AppPreferences.getUserId().isNotEmpty;

        if (hasAll) {
          // if (atLogin || atSplash) return '/home';
          return '/home';
        } else {
          // if (!atLogin && !atSplash) return '/login';
          return '/login';
        }
      },
    );
  }
}

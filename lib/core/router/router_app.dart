// lib/app_router.dart
import 'package:flutter/material.dart';
import 'package:fyp_mrsteam_web/core/util/app_preferences.dart';
import 'package:fyp_mrsteam_web/screens/attendance_screen.dart';
import 'package:fyp_mrsteam_web/screens/auth/login_screen.dart';
import 'package:fyp_mrsteam_web/screens/auth/reset_password_screen.dart';
import 'package:fyp_mrsteam_web/screens/auth/set_new_password_screen.dart';
import 'package:fyp_mrsteam_web/screens/class_calendar_screen.dart';
import 'package:fyp_mrsteam_web/screens/class_list_screen.dart';
import 'package:fyp_mrsteam_web/screens/create_class_screen.dart';
import 'package:fyp_mrsteam_web/screens/dashboard_screen.dart';
import 'package:fyp_mrsteam_web/screens/account_management_screen.dart';
import 'package:fyp_mrsteam_web/screens/add_new_user_screen.dart';
import 'package:fyp_mrsteam_web/screens/user_profile_screen.dart';
import 'package:fyp_mrsteam_web/screens/my_profile_screen.dart';
import 'package:fyp_mrsteam_web/screens/change_password_screen.dart';
import 'package:fyp_mrsteam_web/ui/page/page_home.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  late final GoRouter router;

  AppRouter() {
    router = _createRouter();
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/reset-password',
          name: 'reset-password',
          builder: (context, state) => const ResetPasswordScreen(),
        ),
        GoRoute(
          path: '/set-new-password',
          name: 'set-new-password',
          builder: (context, state) => const SetNewPasswordScreen(),
        ),
        GoRoute(
          path: '/class',
          name: 'class',
          builder: (context, state) => const ClassCalendarScreen(),
        ),
        GoRoute(
          path: '/class/list',
          name: 'class-list',
          builder: (context, state) => const ClassListScreen(),
        ),
        GoRoute(
          path: '/class/create',
          name: 'class-create',
          builder: (context, state) => const CreateClassScreen(),
        ),
        GoRoute(
          path: '/attendance',
          name: 'attendance',
          builder: (context, state) => const AttendanceScreen(),
        ),
        // Account Management Routes
        GoRoute(
          path: '/account',
          name: 'account',
          builder: (context, state) => const AccountManagementScreen(),
        ),
        GoRoute(
          path: '/account/new',
          name: 'account-new',
          builder: (context, state) => const AddNewUserScreen(),
        ),
        GoRoute(
          path: '/account/user/:userId',
          name: 'user-profile',
          builder: (context, state) {
            final userId = state.pathParameters['userId'] ?? '';
            return UserProfileScreen(userId: userId);
          },
        ),
        // My Profile Routes
        GoRoute(
          path: '/myprofile',
          name: 'myprofile',
          builder: (context, state) => const MyProfileScreen(),
        ),
        GoRoute(
          path: '/myprofile/changepassword',
          name: 'change-password',
          builder: (context, state) => const ChangePasswordScreen(),
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
          ),
        ),
      ],
    );
  }
}
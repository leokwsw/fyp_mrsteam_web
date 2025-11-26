import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/class_calendar_screen.dart';
import 'screens/class_list_screen.dart';
import 'screens/create_class_screen.dart';
import 'screens/attendance_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TutorTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro Display',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/class': (context) => const ClassCalendarScreen(),
        '/class/list': (context) => const ClassListScreen(),
        '/class/create': (context) => const CreateClassScreen(),
        '/attendance': (context) => const AttendanceScreen(),
      },
    );
  }
}
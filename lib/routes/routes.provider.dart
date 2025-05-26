import 'package:attendance/routes/routes.names.dart';
import 'package:attendance/screens/add.card.dart';
import 'package:attendance/screens/assign.card.screen.dart';
import 'package:attendance/screens/attendance.screen.dart';
import 'package:attendance/screens/home.screen.dart';
import 'package:attendance/screens/login.dart';
import 'package:attendance/screens/make.attendance.screen.dart';
import 'package:attendance/screens/splash.screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/create_attendance_screen.dart';

class AppNavigation {
  AppNavigation._();

  // Root navigator key for main app navigation
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  // Shell navigator key for nested navigation
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routerNeglect: true, // Prevents route killing

    // Global redirect to handle auth state
    redirect: (BuildContext context, GoRouterState state) {
      // Add your auth logic here
      return null;
    },

    routes: <RouteBase>[
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return Material(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: splash,
            builder: (context, state) => Splash(key: state.pageKey),
          ),
          GoRoute(
            path: '/login',
            name: login,
            builder: (context, state) => LoginPage(key: state.pageKey),
          ),
          GoRoute(
            path: '/home',
            name: home,
            builder: (context, state) => Home(key: state.pageKey),
          ),
          GoRoute(
            path: '/assignCard',
            name: assignCard,
            builder: (context, state) => AssignStudentCard(
              key: state.pageKey,
              classroomId: state.uri.queryParameters['classroomId'],
              classroom: state.uri.queryParameters['classroom'],
            ),
          ),
          GoRoute(
            path: '/makeAttendance',
            name: makeAttendance,
            builder: (context, state) {
              // Extract parameters from query
              final classroomId = state.uri.queryParameters['classroomId'] ?? '';
              final classroom = state.uri.queryParameters['classroom'] ?? '';
              final attendanceId = state.uri.queryParameters['attendanceId'] ?? '';
              
              // Log navigation for debugging
              debugPrint('Navigating to MakeAttendance with:');
              debugPrint('ClassroomID: $classroomId');
              debugPrint('Classroom: $classroom');
              debugPrint('AttendanceID: $attendanceId');
              
              return AttendancePage(
                key: state.pageKey,
                classroomId: classroomId,
                classroom: classroom,
                attendanceId: attendanceId,
              );
            },
          ),

          GoRoute(
            path: '/createAttendance',
            name: createAttendance,
            builder: (context, state) => CreateAttendanceScreen(
              key: state.pageKey,
              classroomId: state.uri.queryParameters['classroomId'],
            
            ),
          ),
          GoRoute(
            path: '/addCard',
            name: addCard,
            builder: (context, state) => AssignCardPage(
              key: state.pageKey,
              studentId: state.uri.queryParameters['studentId'],
              studentCode: state.uri.queryParameters['studentCode'],
              studentName: state.uri.queryParameters['studentName'],
              classroom: state.uri.queryParameters['classroom'],
              profileImage: state.uri.queryParameters['profileImage'],
            ),
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Material(
      child: Center(
        child: Text(
          'Error: ${state.error}',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    ),
  );

  // Navigation helper methods

  static void navigateToProfile(BuildContext context, String clientId) {
    context.safeGoNamed('/clientProfile?clientId=$clientId');
  }

  static void navigateToRefreshRequest(BuildContext context) {
    context.safeGoNamed(myRequests,
        params: {'refresh': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  static void navigateToRefreshHome(BuildContext context) {
    context.safeGoNamed(home,
        params: {'refresh': DateTime.now().millisecondsSinceEpoch.toString()});
  }

  static void navigateBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.safeGoNamed('/home');
    }
  }

  static Future<bool> handleWillPop(BuildContext context) async {
    // Check the current route name
    final currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute == '/home') {
      // Disable back press if the route is '/home'
      return false;
    }

    if (context.canPop()) {
      context.pop();
      return false;
    }
    return true;
  }
}

// Extension for easier navigation
extension NavigationExtension on BuildContext {
  void safePop() {
    if (canPop()) {
      pop();
    } else {
      go('/home');
    }
  }

  void safeGoNamed(String name, {Map<String, String>? params}) {
    try {
      if (params != null) {
        goNamed(name, queryParameters: params);
      } else {
        goNamed(name);
      }
    } catch (e) {
      go('/home');
    }
  }
}

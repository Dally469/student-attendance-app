import 'package:attendance/models/parent.lookup.model.dart';
import 'package:attendance/routes/routes.names.dart';
import 'package:attendance/screens/add.card.dart';
import 'package:attendance/screens/assign.card.screen.dart';
import 'package:attendance/screens/create_attendance_screen.dart';
import 'package:attendance/screens/home.screen.dart';
import 'package:attendance/screens/login.dart';
import 'package:attendance/screens/make.attendance.screen.dart';
import 'package:attendance/screens/parent.communication.screen.dart';
import 'package:attendance/screens/parent.student.view.dart';
import 'package:attendance/screens/school.fees.history.screen.dart';
import 'package:attendance/screens/splash.screen.dart';
import 'package:get/get.dart';

import '../screens/schools.dart';
import '../screens/sms.screen.dart';

class AppNavigation {
  AppNavigation._();

  static const initial = "/splash";

  // Define GetX routes
  static final getPages = [
    GetPage(
      name: splash,
      page: () => Splash(),
    ),
    GetPage(
      name: login,
      page: () => LoginPage(),
    ),
    GetPage(
      name: home,
      page: () => Home(),
    ),
    GetPage(
      name: assignCard,
      page: () {
        final params = Get.parameters;
        return AssignStudentCard(
          classroomId: params['classroomId'],
          classroom: params['classroom'],
        );
      },
    ),
    GetPage(
      name: parentCommunication,
      page: () {
        final params = Get.parameters;
        return ParentCommunication(
          classroomId: params['classroomId'],
          classroom: params['classroom'],
        );
      },
    ),
    GetPage(
      name: feeHistory,
      page: () {
        final params = Get.parameters;
        return FeeHistory(
          classroomId: params['classroomId'],
          classroom: params['classroom'],
        );
      },
    ),
    GetPage(
      name: makeAttendance,
      page: () {
        final params = Get.parameters;
        return AttendancePage(
          classroomId: params['classroomId'] ?? '',
          classroom: params['classroom'] ?? '',
          attendanceId: params['attendanceId'] ?? '',
        );
      },
    ),
    GetPage(
      name: createAttendance,
      page: () {
        final params = Get.parameters;
        return CreateAttendanceScreen(
          classroomId: params['classroomId'],
        );
      },
    ),
    GetPage(
      name: smsHistory,
      page: () {
        return SMSTopUpScreen();
      },
    ),
    GetPage(
      name: addCard,
      page: () {
        final params = Get.parameters;
        return AssignCardPage(
          studentId: params['studentId'],
          studentCode: params['studentCode'],
          studentName: params['studentName'],
          classroom: params['classroom'],
          profileImage: params['profileImage'],
        );
      },
    ),
    GetPage(
      name: schoolsRoute,
      page: () => SchoolManagement(),
    ),
    GetPage(
      name: parentStudentView,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        if (args != null && args['studentsWithFees'] != null) {
          final studentsList = args['studentsWithFees'] as List;
          return ParentStudentView(
            studentsWithFees:
                studentsList.map((e) => e as StudentWithFees).toList(),
            query: args['query'] as String? ?? '',
            token: args['token'] as String?,
            expiresIn: args['expiresIn'] as String?,
          );
        }
        return const ParentStudentView(
          studentsWithFees: [],
          query: '',
        );
      },
    ),
  ];

  // Navigation helper methods
  static void navigateToProfile(String clientId) {
    Get.toNamed('$clientProfile?clientId=$clientId');
  }

  static void navigateToRefreshRequest() {
    Get.toNamed(myRequests, parameters: {
      'refresh': DateTime.now().millisecondsSinceEpoch.toString()
    });
  }

  static void navigateToRefreshHome() {
    Get.toNamed(home, parameters: {
      'refresh': DateTime.now().millisecondsSinceEpoch.toString()
    });
  }

  static void navigateBack() {
    Get.back();
  }

  static Future<bool> handleWillPop() async {
    // Check the current route name
    final currentRoute = Get.currentRoute;

    if (currentRoute == home) {
      // Disable back press if the route is '/home'
      return false;
    }

    return true;
  }
}

import 'dart:io';

// Controllers
import 'package:attendance/controllers/assign_student_card_controller.dart';
import 'package:attendance/controllers/attendance_controller.dart';
import 'package:attendance/controllers/classroom_student_controller.dart';
import 'package:attendance/controllers/school_classroom_controller.dart';
import 'package:attendance/controllers/user_login_controller.dart';
import 'package:attendance/screens/splash.screen.dart';
import 'package:attendance/utils/colors.dart';
// Firebase removed - will use another solution later
// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controllers/parent_communication_controller.dart';
import 'controllers/school_fees_controller.dart';
import 'controllers/sms.controller.dart';
import 'routes/routes.names.dart'; // Route names
import 'routes/routes.provider.dart'; // Updated routes provider for GetX

Future<void> main() async {
  // Load environment variables based on build mode
  if (kReleaseMode || kDebugMode || kProfileMode) {
    await dotenv.load(fileName: '.env');
  }

  WidgetsFlutterBinding.ensureInitialized();
  // Firebase removed - will use another solution later
  // try {
  //   await Firebase.initializeApp();
  //
  // } catch (e) {
  //   print('Firebase initialization error: $e');
  // }
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  final showHome = prefs.getBool('showHome') ?? false;

  // Override HTTP for handling certificates
  HttpOverrides.global = MyHttpOverrides();

  // Initialize GetX
  Get.config(enableLog: true, defaultTransition: Transition.fade);

  // Enable test mode to suppress contextless navigation warnings
  Get.testMode = true;

  // Initialize GetX controllers
  _initializeGetXControllers();

  runApp(MyApp(showHome: showHome));
}

class MyApp extends StatelessWidget {
  final bool showHome;
  const MyApp({Key? key, required this.showHome}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: primaryColor,
      statusBarIconBrightness: Brightness.light, // For Android (dark icons)
      statusBarBrightness: Brightness.light,
    ));

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        primaryColor: Color.fromARGB(255, 0, 179, 250),
      ),
      initialRoute: showHome ? home : splash,
      getPages: AppNavigation.getPages, // Use GetX routes
      home: Splash(),
    );
  }
}

// Initialize all GetX controllers
void _initializeGetXControllers() {
  // Put all controllers using Get.put with permanent: true to keep them alive throughout the app
  Get.put(UserLoginController(), permanent: true);
  Get.put(SchoolClassroomController(), permanent: true);
  Get.put(ClassroomStudentController(), permanent: true);
  Get.put(AssignStudentCardController(), permanent: true);
  Get.put(AttendanceController(), permanent: true);
  Get.put(ParentCommunicationController(), permanent: true);
  Get.put(SchoolFeesController(), permanent: true);
  Get.put(SMSController(), permanent: true);
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

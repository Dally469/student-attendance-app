import 'dart:io';

// Controllers
import 'package:attendance/controllers/assign_student_card_controller.dart';
import 'package:attendance/controllers/attendance_controller.dart';
import 'package:attendance/controllers/classroom_student_controller.dart';
import 'package:attendance/controllers/school_classroom_controller.dart';
import 'package:attendance/controllers/user_login_controller.dart';
import 'package:attendance/routes/routes.provider.dart';
import 'package:attendance/utils/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  // Load environment variables based on build mode
  if (kReleaseMode || kDebugMode || kProfileMode) {
    await dotenv.load(fileName: '.env');
  }
  
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  final showHome = prefs.getBool('showHome') ?? false;

  // Override HTTP for handling certificates
  HttpOverrides.global = MyHttpOverrides();
  
  // Initialize GetX controllers
  _initializeGetXControllers();
  
  runApp(MyApp(showHome: showHome));
}

class MyApp extends StatefulWidget {
  final bool showHome;
  const MyApp({Key? key, required this.showHome}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: primaryColor,
        statusBarIconBrightness: Brightness.light, // For Android (dark icons)
        statusBarBrightness: Brightness.light));
    
    // Using GetMaterialApp with go_router
    return MaterialApp.router(
      routerConfig: AppNavigation.router,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        primaryColor: const Color.fromARGB(255, 18, 170, 112),
      ),
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
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

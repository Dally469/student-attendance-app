import 'dart:io';

import 'package:attendance/api/auth.service.dart';
import 'package:attendance/routes/routes.provider.dart';
import 'package:attendance/screens/login.dart';
import 'package:attendance/screens/splash.screen.dart';
import 'package:attendance/states/assign.student.card/assign_student_card_bloc.dart';
import 'package:attendance/states/classroom.student/classroom_student_bloc.dart';
import 'package:attendance/states/school.classroom/school_classroom_bloc.dart';
import 'package:attendance/utils/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'states/user.login/user_login_bloc.dart';

Future<void> main() async {
  if (kReleaseMode) {
    await dotenv.load(fileName: '.env');
  }
  if (kDebugMode) {
    await dotenv.load(fileName: '.env');
  }
  if (kProfileMode) {
    await dotenv.load(fileName: '.env');
  }
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  final showHome = prefs.getBool('showHome') ?? false;

  HttpOverrides.global = MyHttpOverrides();
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
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserLoginBloc>(
            create: (_) => UserLoginBloc(UserLoginInitial(), AuthService())),
        BlocProvider<SchoolClassroomBloc>(
            create: (_) =>
                SchoolClassroomBloc(SchoolClassroomInitial(), AuthService())),
        BlocProvider<ClassroomStudentBloc>(
            create: (_) =>
                ClassroomStudentBloc(ClassroomStudentInitial(), AuthService())),
        BlocProvider<AssignStudentCardBloc>(
            create: (_) => AssignStudentCardBloc(
                AssignStudentCardInitial(), AuthService())),
      ],
      child: MaterialApp.router(
        routerConfig: AppNavigation.router,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          visualDensity: VisualDensity.adaptivePlatformDensity,
          primaryColor: Color.fromARGB(255, 18, 170, 112),
        ),
      ),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

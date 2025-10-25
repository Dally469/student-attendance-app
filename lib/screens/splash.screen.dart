import 'dart:async';
import 'dart:convert';
import 'package:attendance/routes/routes.names.dart';
import 'package:attendance/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserData {
  UserData();
  factory UserData.fromJson(Map<String, dynamic> json) => UserData();
}

class Strings {
  static const String appName = 'SCHOOL';
}

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _notifyController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late List<Animation<Offset>> _letterAnimations;
  late List<Animation<double>> _letterOpacities;
  late Animation<double> _notifyOpacity;
  late Animation<Offset> _notifySlide;
  late UserData user;
  String? jsonCheck, json, jsonToken, jsonRole;

  @override
  void initState() {
    super.initState();
    user = UserData();

    // Logo animation controller
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Text animation controller
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Notify animation controller
    _notifyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Logo animations
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeIn,
      ),
    );

    // Text letter animations
    _letterAnimations = List.generate(
      Strings.appName.length,
      (index) => Tween<Offset>(
        begin: const Offset(0, 50),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _textController,
          curve: Interval(
            index * 0.1,
            (index + 1) * 0.1 + 0.4,
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _letterOpacities = List.generate(
      Strings.appName.length,
      (index) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _textController,
          curve: Interval(
            index * 0.1,
            (index + 1) * 0.1 + 0.4,
            curve: Curves.easeIn,
          ),
        ),
      ),
    );

    // Notify animations
    _notifyOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _notifyController,
        curve: Curves.easeIn,
      ),
    );

    _notifySlide = Tween<Offset>(
      begin: const Offset(0, 20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _notifyController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start animations
    _logoController.forward().then((_) {
      _textController.forward().whenComplete(() {
        _notifyController.forward().whenComplete(() {
          startTime();
        });
      });
    });
  }

  Future<Timer> startTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get all necessary data
      json = prefs.getString('currentUser');
      jsonToken = prefs.getString('token');
      jsonRole = prefs.getString('role');

      debugPrint('Stored user data: $json');
      debugPrint('Stored token: $jsonToken');
      debugPrint('Stored role: $jsonRole');

      var duration =
          const Duration(milliseconds: 2000); // Give consistent delay

      // Check if user is logged in (has both user data and token)
      if (json == null ||
          json == 'no' ||
          jsonToken == null ||
          jsonToken == 'no') {
        debugPrint('User not logged in - redirecting to login');
        jsonCheck = 'no';
      } else {
        debugPrint('User is logged in - checking role');
        jsonCheck = 'yes';

        // Parse user data
        try {
          Map<String, dynamic> map = jsonDecode(json!);
          user = UserData.fromJson(map);

          // If role is not stored separately, try to get it from user data
          if (jsonRole == null || jsonRole == 'no') {
            jsonRole = map['role'] ?? map['userRole'] ?? map['user_role'];
            debugPrint('Role extracted from user data: $jsonRole');
          }
        } catch (e) {
          debugPrint('Error parsing user data: $e');
          jsonCheck = 'no'; // Treat as not logged in if data is corrupted
        }
      }

      return Timer(duration, navigationPage);
    } catch (e) {
      debugPrint('Error in startTime: $e');
      jsonCheck = 'no';
      return Timer(const Duration(milliseconds: 2000), navigationPage);
    }
  }

  void navigationPage() {
    try {
      debugPrint('Navigating... jsonCheck: $jsonCheck, jsonRole: $jsonRole');

      if (jsonCheck == 'no') {
        debugPrint('Navigating to login');
        Get.offAllNamed('/login'); // Use offAllNamed to clear navigation stack
      } else {
        // User is logged in, check role
        if (jsonRole != null) {
          String role = jsonRole!.toUpperCase(); // Ensure consistent case
          String newRole = role.replaceAll('"', '');
          debugPrint('User role (normalized): $newRole');

          switch (newRole) {
            case "ADMIN":
              debugPrint('Navigating to schools (admin)');
              Get.offAllNamed('/schools');
              break;
            case "TEACHER":
            case "STUDENT":
            case "USER":
            default:
              debugPrint('Navigating to home (non-admin user)');
              Get.offAllNamed('/home');
              break;
          }
        } else {
          debugPrint('No role found, navigating to home');
          Get.offAllNamed('/home'); // Default to home if no role is specified
        }
      }
    } catch (e) {
      debugPrint('Error in navigationPage: $e');
      // Fallback navigation
      Get.offAllNamed('/login');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _notifyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor,
              primaryColor.withOpacity(0.8),
              accentColor.withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) => Transform.scale(
                        scale: _logoScale.value,
                        child: Opacity(
                          opacity: _logoOpacity.value,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromARGB(255, 6, 145, 210)
                                      .withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo_school.png',
                              width: 80,
                              height: 80,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Animated Text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        Strings.appName.length,
                        (index) => AnimatedBuilder(
                          animation: _textController,
                          builder: (context, child) => Transform.translate(
                            offset: _letterAnimations[index].value,
                            child: Opacity(
                              opacity: _letterOpacities[index].value,
                              child: Text(
                                Strings.appName[index],
                                style: GoogleFonts.poppins(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  color: whiteColor,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 0),
                    // "NOTIFY" Text
                    AnimatedBuilder(
                      animation: _notifyController,
                      builder: (context, child) => Transform.translate(
                        offset: _notifySlide.value,
                        child: Opacity(
                          opacity: _notifyOpacity.value,
                          child: Text(
                            "Notify",
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.yellow,
                              letterSpacing: 4,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Loading Indicator
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(whiteColor),
                      strokeWidth: 3,
                    ),
                  ],
                ),
              ),
              // Bottom Branding
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "Powered by Besoft & BePay Ltd",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: whiteColor.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

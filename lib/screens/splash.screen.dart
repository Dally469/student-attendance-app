import 'dart:async';
import 'dart:convert';
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
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late List<Animation<Offset>> _letterAnimations;
  late List<Animation<double>> _letterOpacities;
  late UserData user;
  String? jsonCheck, json, jsonToken;

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

    // Start animations
    _logoController.forward().then((_) {
      _textController.forward().whenComplete(() {
        startTime();
      });
    });
  }

  Future<Timer> startTime() async {
    final prefs = await SharedPreferences.getInstance();
    json = prefs.getString('currentUser') ?? 'no';
    jsonToken = prefs.getString('token') ?? 'no';
    jsonCheck = prefs.getString('currentUser') ?? 'no';

    var duration = const Duration(milliseconds: 100);

    if (jsonCheck == 'no') {
      return Timer(duration, navigationPage);
    } else {
      Map<String, dynamic> map = jsonDecode(json!);
      user = UserData.fromJson(map);
      duration = const Duration(seconds: 2);
      return Timer(duration, navigationPage);
    }
  }

  void navigationPage() {
    if (jsonCheck == 'no') {
      Get.toNamed('/login');
    } else {
      Get.toNamed('/home');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
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
                              color: whiteColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromARGB(255, 2, 63, 59).withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logo-school.png',
                              width: 80,
                              height: 80,
                              color: whiteColor,
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
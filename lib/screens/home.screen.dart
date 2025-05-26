// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:attendance/controllers/attendance_controller.dart';
import 'package:attendance/controllers/classroom_student_controller.dart';
import 'package:attendance/controllers/school_classroom_controller.dart';
import 'package:attendance/models/classroom.model.dart';
import 'package:attendance/routes/routes.names.dart';
import 'package:attendance/routes/routes.provider.dart';
import 'package:attendance/utils/colors.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? userFullNames, schoolName, schoolLogo;
  RxString selectedService = "".obs;
  RxBool isCreatingAttendance = false.obs;
  RxBool isConnected = true.obs;

  // Use GetX controllers
  final SchoolClassroomController _schoolClassroomController =
      Get.find<SchoolClassroomController>();
  final ClassroomStudentController _classroomStudentController =
      Get.find<ClassroomStudentController>();
  final AttendanceController _attendanceController =
      Get.find<AttendanceController>();

  @override
  void initState() {
    super.initState();
    getCurrentUserInfo();

    // Load classrooms with GetX controller
    _schoolClassroomController.getSchoolClassrooms();
  }

  Future<void> getCurrentUserInfo() async {
    try {
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      String? userJson = sharedPreferences.getString("currentUser");
      String? schoolJson = sharedPreferences.getString("currentSchool");

      if (userJson != null) {
        Map<String, dynamic> userMap = jsonDecode(userJson);
        Map<String, dynamic> schoolMap = jsonDecode(schoolJson!);

        setState(() {
          userFullNames =
              '${userMap['firstName'] ?? '---'} ${userMap['lastName'] ?? '---'}';

          if (kDebugMode) {
            print(schoolMap['name']);
          }

          // Extract school name from user data
          if (userMap.containsKey('school') && userMap['school'] != null) {
            schoolName = userMap['school']['name'];
            schoolLogo = userMap['school']['logo'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error getting user info: $e');
    }
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: primaryColor,
      elevation: 0,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: primaryColor,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                userFullNames?.isNotEmpty == true
                    ? userFullNames![0].toUpperCase()
                    : "U",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            accountName: Text(
              userFullNames ?? '---',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            accountEmail: Text(
              schoolName ?? '---',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(
              Icons.dashboard,
              color: Colors.white,
            ),
            title: const Text(
              'Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w300,
                fontSize: 18,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.history,
              color: Colors.white,
            ),
            title: const Text(
              'Student History',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w300,
                fontSize: 18,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              context.safeGoNamed(myRequests);
            },
          ),
          const Divider(color: Colors.white30),
          ListTile(
            leading: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
            title: const Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w300,
                fontSize: 18,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              // Add navigation to settings
            },
          ),
          const Spacer(),
          const Divider(color: Colors.white30),
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            onTap: _handleLogout,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (mounted) {
                  context.safeGoNamed(splash);
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }

  Future<bool> _onWillPop() async {
    return false;
  }

  void _showClassroomBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      elevation: 10,
      enableDrag: true,
      transitionAnimationController: AnimationController(
        vsync: Navigator.of(context),
        duration: const Duration(milliseconds: 400),
        reverseDuration: const Duration(milliseconds: 300),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 20),
                          child: child,
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Obx(() => Icon(
                                selectedService.value == "card"
                                    ? Icons.credit_card_rounded
                                    : Icons.checklist_rounded,
                                color: primaryColor,
                                size: 24,
                              )),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Obx(() => Text(
                                selectedService.value == "card"
                                    ? "Select a Class to Assign Cards"
                                    : "Select a Class for Attendance",
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: blackColor,
                                  height: 1.3,
                                  letterSpacing: 0.2,
                                ),
                              )),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _buildClassroomList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildClassroomList() {
    return Obx(() {
      if (_schoolClassroomController.isLoading.value) {
        return _buildLoadingState();
      }

      if (_schoolClassroomController.errorMessage.value.isNotEmpty) {
        Get.snackbar(
          'Error',
          _schoolClassroomController.errorMessage.value,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }

      if (_schoolClassroomController.classrooms.isNotEmpty) {
        return _buildClassroomListContent();
      } else if (!_schoolClassroomController.isLoading.value) {
        return _buildEmptyState();
      }

      return const Center(
        child: Text("An error occurred. Please try again."),
      );
    });
  }

  Widget _buildLoadingState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SpinKitDoubleBounce(
              color: primaryColor,
              size: 40,
            ),
            const SizedBox(height: 20),
            Text(
              'Loading classrooms...',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No classrooms found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'You don\'t have any classrooms assigned to your school yet.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassroomListContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Choose a Classroom",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() => GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: _schoolClassroomController.classrooms.length,
                  itemBuilder: (context, index) {
                    return _buildClassroomCard(
                        _schoolClassroomController.classrooms[index]);
                  },
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomCard(Classroom classroom) {
    return InkWell(
      onTap: () => _handleClassroomSelection(classroom),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        classroom.name?.substring(0, 1) ?? 'C',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Text(
                      classroom.name ?? 'Unknown',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleClassroomSelection(Classroom classroomData) {
    Navigator.pop(context); // Close the bottom sheet

    if (selectedService.value == "card") {
      // Go to assign card screen with GetX
      context.safeGoNamed(assignCard, params: {
        'classroom': classroomData.name.toString(),
        'classroomId': classroomData.id.toString(),
      });
    } else if (selectedService.value == "attendance") {
      isCreatingAttendance.value = true;

      // Use GetX controller
      _attendanceController.createAttendance(
        classroomData.id.toString(),
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          // Setup listener for attendance creation
          ever(_attendanceController.currentAttendance, (attendance) {
            if (attendance != null && attendance.data != null) {
              isCreatingAttendance.value = false;
              
              // Use GetX navigation which doesn't depend on context
              if (Get.isDialogOpen ?? false) {
                Get.back(); // Close dialog safely
              }

              // Get the attendance ID from the nested data object
              String attendanceId = '';
              
              if (attendance.data?.id != null) {
                attendanceId = attendance.data!.id!;
              } else if (_attendanceController.attendanceId.value.isNotEmpty) {
                attendanceId = _attendanceController.attendanceId.value;
              }
              
              if (attendanceId.isNotEmpty) {
                // Navigate with GetX
                Get.toNamed(
                  makeAttendance, 
                  parameters: {
                    'classroomId': classroomData.id.toString(),
                    'classroom': classroomData.name.toString(),
                    'attendanceId': attendanceId,
                  }
                );
              } else {
                // Show error if attendance ID is missing
                Get.snackbar(
                  'Error',
                  'Failed to get attendance ID. Please try again.',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            }
          });

          // Setup listener for errors
          ever(_attendanceController.errorMessage, (errorMessage) {
            if (errorMessage.isNotEmpty) {
              isCreatingAttendance.value = false;
              
              // Just close the dialog - don't show snackbar here
              if (Get.isDialogOpen ?? false) {
                Get.back();
              }
              
              // No snackbar here to avoid null check errors
              // We'll let the controller handle error display
            }
          });
          
          // Setup listener for success messages
          ever(_attendanceController.successMessage, (successMessage) {
            if (successMessage.isNotEmpty) {
              isCreatingAttendance.value = false;
              
              // Just close the dialog - don't show snackbar here
              if (Get.isDialogOpen ?? false) {
                Get.back();
              }
              
              // The attendance controller will handle the navigation
              // No snackbar here to avoid null check errors
            }
          });

          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const CircularProgressIndicator(color: primaryColor),
                const SizedBox(height: 24),
                Text(
                  'Creating Attendance Record',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait...',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildServiceCard(String title, String image, String service) {
    return Hero(
      tag: 'service_card_$service',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        child: Card(
          elevation: 8,
          shadowColor: primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            splashColor: primaryColor.withOpacity(0.1),
            highlightColor: primaryColor.withOpacity(0.05),
            onTap: () {
              // Add tap animation
              HapticFeedback.lightImpact();
              selectedService.value = service;
              _showClassroomBottomSheet(context);
              _schoolClassroomController.getSchoolClassrooms();
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left side - icon
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Image.asset(
                      image,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Middle - text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: blackColor,
                            height: 1.2,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          service == "card"
                              ? "Assign RFID cards to students"
                              : "Record student attendance",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[700],
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right side - button
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 4,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          title: Row(
            children: [
              schoolLogo != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        schoolLogo!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey[200],
                            child:
                                const Icon(Icons.school, color: primaryColor),
                          );
                        },
                      ),
                    )
                  : Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.school, color: primaryColor),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  schoolName ?? 'School App',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('No new notifications'),
                    duration: const Duration(seconds: 1),
                    backgroundColor: primaryColor,
                  ),
                );
              },
            ),
          ],
        ),
        drawer: _buildDrawer(context),
        body: RefreshIndicator(
          onRefresh: () async {
            return _schoolClassroomController.getSchoolClassrooms();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting section
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${userFullNames?.split(' ').first ?? 'Teacher'}!',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            StreamBuilder<ConnectivityResult>(
                              stream: Connectivity().onConnectivityChanged,
                              builder: (context, snapshot) {
                                final isOnline =
                                    snapshot.data != ConnectivityResult.none;
                                isConnected.value = isOnline;

                                return Row(
                                  children: [
                                    Icon(
                                      isOnline ? Icons.wifi : Icons.wifi_off,
                                      color: isOnline
                                          ? primaryColor
                                          : Colors.orange,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isOnline ? 'Online' : 'Offline',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: isOnline
                                            ? primaryColor
                                            : Colors.orange,
                                      ),
                                    ),
                                  ],
                                );
                              },
                              initialData: ConnectivityResult.none,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Title
                  Text(
                    'What would you like to do?',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      letterSpacing: 0.3,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Services grid
                  _buildServiceCard(
                    'Assign Student Card',
                    'assets/images/nfc.png',
                    'card',
                  ),
                  const SizedBox(height: 16),
                  _buildServiceCard(
                    'Record Attendance',
                    'assets/images/attendance.png',
                    'attendance',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

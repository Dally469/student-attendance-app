// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:attendance/models/classroom.model.dart';
import 'package:attendance/routes/routes.names.dart';
import 'package:attendance/routes/routes.provider.dart';
import 'package:attendance/states/attendance/attendance_event.dart';
import 'package:attendance/states/classroom.student/classroom_student_bloc.dart';
import 'package:attendance/states/school.classroom/school_classroom_bloc.dart';
import 'package:attendance/utils/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../states/attendance/attendance_bloc.dart';
import '../states/attendance/attendance_state.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? userFullNames, schoolToken, schoolName, schoolLogo;
  String? selectedService;
  String? obtainedClassroomId;
  String? obtainedClassroom;
  bool isCreatingAttendance = false;

  late final SchoolClassroomBloc schoolClassroomBloc;
  late final ClassroomStudentBloc classroomStudentBloc;
  late final CreateAttendanceBloc attendanceBloc;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    getCurrentUserInfo();
  }

  void _initializeBlocs() {
    schoolClassroomBloc = BlocProvider.of<SchoolClassroomBloc>(context);
    classroomStudentBloc = BlocProvider.of<ClassroomStudentBloc>(context);
    attendanceBloc = BlocProvider.of<CreateAttendanceBloc>(context);
  }

  Future<void> getCurrentUserInfo() async {
    try {
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      String? userJson = sharedPreferences.getString("currentUser");
      String? schoolJson = sharedPreferences.getString("currentSchool");
      String? tokenJson = sharedPreferences.getString("token");
      if (userJson != null) {
        Map<String, dynamic> userMap = jsonDecode(userJson);
        Map<String, dynamic> schoolMap = jsonDecode(schoolJson!);
        setState(() {
          userFullNames =
              '${userMap['firstName'] ?? '---'} ${userMap['lastName'] ?? '---'}';
          schoolToken = tokenJson;
          print(schoolMap['name']);

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
                  // Navigator.pop(context);
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
            color: whiteColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Select Classroom for ${selectedService == "card" ? "Card Assignment" : "Attendance"}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: blackColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              _buildClassroomList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClassroomList() {
    return BlocConsumer<SchoolClassroomBloc, SchoolClassroomState>(
      listener: (context, state) {
        if (state is SchoolClassroomError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is SchoolClassroomLoading) {
          return _buildLoadingState();
        }
        if (state is SchoolClassroomSuccess) {
          if (state.schoolClassroomModel.data?.isEmpty ?? true) {
            return _buildEmptyState();
          }
          return _buildClassroomListContent(state);
        }
        return const Center(
          child: Text("An error occurred. Please try again."),
        );
      },
    );
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
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 2),
              ),
              padding: const EdgeInsets.all(20),
              child: const Icon(
                Icons.category_outlined,
                size: 48,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Classrooms Found',
              style: GoogleFonts.poppins(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Please contact your administrator to add classrooms',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassroomListContent(SchoolClassroomSuccess state) {
    return Expanded(
      child: ListView.builder(
        itemCount: state.schoolClassroomModel.data!.length,
        itemBuilder: (context, index) {
          final classroom = state.schoolClassroomModel.data![index];
          return _buildClassroomCard(classroom);
        },
      ),
    );
  }

  void _handleAttendanceStateChange(
      BuildContext context, AttendanceState state) {
    if (state is AttendanceSuccess) {
      // Store the new attendance ID
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('active_attendance_$obtainedClassroomId',
            state.attendanceModel.id.toString());
      });

      // Navigate to attendance screen
      Navigator.pop(context); // Close the bottom sheet
      context.safeGoNamed(
        makeAttendance,
        params: {
          'classroom': obtainedClassroom ?? '',
          'classroomId': obtainedClassroomId ?? '',
          'attendanceId': state.attendanceModel.id.toString(),
        },
      );
    } else if (state is AttendanceError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildClassroomCard(Classroom classroom) {
    return BlocConsumer<CreateAttendanceBloc, AttendanceState>(
      listener: _handleAttendanceStateChange,
      builder: (context, state) {
        bool isLoading =
            state is AttendanceLoading && obtainedClassroomId == classroom.id;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  classroom.name?.substring(0, 1) ?? 'C',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ),
            title: Text(
              classroom.name ?? 'Unknown Class',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: blackColor,
              ),
            ),
            subtitle: Text(
              classroom.school?.name ?? 'Unknown School',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: Colors.grey,
              ),
            ),
            trailing: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  )
                : const Icon(
                    Icons.chevron_right,
                    color: primaryColor,
                  ),
            onTap: isLoading
                ? null
                : () {
                    if (selectedService == "card") {
                      _handleCardAssignment(classroom);
                    } else {
                      _handleAttendanceCreation(classroom);
                    }
                  },
          ),
        );
      },
    );
  }

  Future<void> _handleAttendanceCreation(Classroom classroom) async {
    if (isCreatingAttendance) return;

    final classroomId = classroom.id;
    final className = classroom.name;

    if (classroomId == null || className == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid classroom data'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isCreatingAttendance = true;
      obtainedClassroomId = classroomId;
      obtainedClassroom = className;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final existingAttendanceId =
          prefs.getString('active_attendance_$classroomId');

      if (existingAttendanceId != null) {
        Navigator.pop(context); // Close the bottom sheet
        if (mounted) {
          context.safeGoNamed(
            makeAttendance,
            params: {
              'classroom': className,
              'classroomId': classroomId,
              'attendanceId': existingAttendanceId,
            },
          );
        }
      } else {
        // Create new attendance record
        context.read<CreateAttendanceBloc>().add(
              CreateAttendanceEvent(classroomId: classroomId),
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating attendance: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isCreatingAttendance = false;
      });
    }
  }

  void _handleCardAssignment(Classroom classroom) {
    Navigator.pop(context); // Close the bottom sheet
    context.safeGoNamed(
      assignCard,
      params: {
        'classroom': classroom.name ?? '',
        'classroomId': classroom.id ?? '',
      },
    );
  }

  Widget _buildServiceCard(String title, String image, String service) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            selectedService = service;
          });
          _showClassroomBottomSheet(context);
          schoolClassroomBloc
              .add(FetchSchoolClassroomEvent(token: schoolToken!));
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                image,
                width: 60,
                height: 60,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: blackColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                service == "card"
                    ? "Assign RFID cards to students"
                    : "Record student attendance",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Start",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
          elevation: 0,
          title: const Text("STUDENT ATTENDANCE"),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Refresh data if needed
                getCurrentUserInfo();
              },
            ),
          ],
        ),
        drawer: _buildDrawer(context),
        body: SafeArea(
          child: Column(
            children: [
              // School info header
              // School info header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Use school logo if available, otherwise use school icon
                        schoolLogo != null && schoolLogo!.isNotEmpty
                            ? Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(schoolLogo!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.school,
                                  color: primaryColor,
                                  size: 24,
                                ),
                              ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                schoolName ?? 'School Name',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Welcome, ${userFullNames ?? "User"}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Main content
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Services',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: blackColor,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Service cards
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          children: [
                            _buildServiceCard(
                              "Assign Card",
                              "assets/images/assign-card.png",
                              "card",
                            ),
                            _buildServiceCard(
                              "Mark Attendance",
                              "assets/images/attended.png",
                              "attendance",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomSheet: Container(
          color: whiteColor,
          height: 40,
          child: Center(
            child: Text(
              "Powered by Besoft & BePay ltd",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: blackColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up any resources or subscriptions
    super.dispose();
  }
}

// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:attendance/api/auth.service.dart';
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
import 'package:go_router/go_router.dart';
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
  String? userFullNames;
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
      if (userJson != null) {
        Map<String, dynamic> userMap = jsonDecode(userJson);
        setState(() {
          userFullNames =
              '${userMap['firstName'] ?? '---'} ${userMap['lastName'] ?? '---'}';
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
          DrawerHeader(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(width: 10),
                  Container(
                    margin: const EdgeInsets.only(top: 40),
                    width: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome,',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 3,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(
                          height: 50,
                          child: Text(
                            userFullNames ?? '---',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.request_page,
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
          const Spacer(),
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pop(context);
        context.safeGoNamed(splash);
      }
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
              Container(
                margin: const EdgeInsets.only(left: 16.0),
                child: Text(
                  'Select Classroom for $selectedService',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: blackColor,
                  ),
                ),
              ),
              const SizedBox(height: 20),
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
            SnackBar(content: Text(state.message)),
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
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70.0),
      child: Column(
        children: [
          Text(
            'Loading classrooms...',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),
          const SpinKitDoubleBounce(
            color: primaryColor,
            size: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 70.0),
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
                Icons.inbox,
                size: 48,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Classrooms Found',
              style: GoogleFonts.poppins(fontSize: 18),
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
        prefs.setString(
            'active_attendance_$obtainedClassroomId', state.attendanceModel.id.toString());
      });

      // Navigate to attendance screen
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
        SnackBar(content: Text(state.message)),
      );
    }
  }
  Widget _buildClassroomCard(Data classroom) {
    return BlocConsumer<CreateAttendanceBloc, AttendanceState>(
      listener: _handleAttendanceStateChange, // Add it here
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: whiteColor1, width: 2),
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
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classroom.name ?? 'Unknown Class',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: greenColor,
                        ),
                      ),
                      Text(
                        classroom.school?.name ?? 'Unknown School',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {
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

  Future<void> _handleAttendanceCreation(Data classroom) async {
    if (isCreatingAttendance) return;

    final classroomId = classroom.id;
    final className = classroom.name;

    if (classroomId == null || className == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid classroom data')),
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

          print(existingAttendanceId);

      if (existingAttendanceId != null) {
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
          SnackBar(content: Text('Error creating attendance: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        isCreatingAttendance = false;
      });
    }
  }


  // OLD



  void _handleCardAssignment(Data classroom) {
    context.safeGoNamed(
      assignCard,
      params: {
        'classroom': classroom.name ?? '',
        'classroomId': classroom.id ?? '',
      },
    );
  }

  Widget _buildServiceRow(
      BuildContext context, List<Map<String, String>> services) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: services.map((service) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          width: MediaQuery.of(context).size.width,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
                side: const BorderSide(color: Colors.grey, width: 2),
              ),
              fixedSize: const Size(double.infinity, 150),
            ),
            onPressed: () {
              setState(() {
                selectedService = service['service'];
              });
              _showClassroomBottomSheet(context);
              schoolClassroomBloc.add(FetchSchoolClassroomEvent(token: 'we'));
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Image.asset(
                  service['image']!,
                  width: 80,
                  height: 80,
                ),
                const SizedBox(width: 15),
                SizedBox(
                  width: 200,
                  child: Text(
                    service['title']!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
        ),
        drawer: _buildDrawer(context),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                "assets/images/backparttern.png",
                color: Colors.black.withOpacity(0.3),
                colorBlendMode: BlendMode.srcATop,
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(
                color: whiteColor,
              ),
            ),
            SingleChildScrollView(
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      margin: const EdgeInsets.only(left: 20.0),
                      child: Text(
                        'Welcome ${userFullNames ?? ""}',
                        style: const TextStyle(
                          fontSize: 20,
                          color: blackColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildServiceRow(
                          context,
                          [
                            {
                              "title": "Assign Student Card",
                              "image": "assets/images/assign-card.png",
                              "service": "card",
                            },
                            {
                              "title": "Make Student Attendance",
                              "image": "assets/images/attended.png",
                              "service": "attendance",
                            },
                          ],
                        ),
                        const SizedBox(height: 60),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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

import 'dart:convert';

import 'package:attendance/api/auth.service.dart';
import 'package:attendance/models/classroom.model.dart';
import 'package:attendance/routes/routes.names.dart';
import 'package:attendance/routes/routes.provider.dart';
import 'package:attendance/states/school.classroom/school_classroom_bloc.dart';
import 'package:attendance/utils/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? userFullNames, selectedService;

  getCurrentUserInfo() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    String? userJson = sharedPreferences.getString("currentUser");
    Map<String, dynamic> userMap = jsonDecode(userJson!);
    setState(() {
      userFullNames =
          '${userMap['firstName'] ?? '-------'} ${userMap['lastName'] ?? '-------'}';
    });
  }

  SchoolClassroomBloc schoolClassroomBloc =
      SchoolClassroomBloc(SchoolClassroomInitial(), AuthService());

  @override
  void initState() {
    super.initState();
    getCurrentUserInfo();
    schoolClassroomBloc = BlocProvider.of<SchoolClassroomBloc>(context);
  }

  // Function to build the Drawer
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
                  const SizedBox(width: 10), // Space between avatar and text
                  // Welcome Text and Name
                  Container(
                    margin: const EdgeInsets.only(top: 40),
                    width: 150,
                    decoration: const BoxDecoration(),
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
                            '$userFullNames',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3, // Display the user's name
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
              Navigator.pop(context); // Close drawer
              context.safeGoNamed(myRequests);
            },
          ),
          const Spacer(), // Pushes the logout button to the bottom
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
            onTap: () async {
              // Close drawer
              Navigator.pop(context);

              // Clear all shared preferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              // Navigate to the login or desired screen after clearing preferences
              context.safeGoNamed(
                  splash); // Replace 'login' with your login route name
            },
          ),
          const SizedBox(height: 20), // Adds some space at the bottom
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    return false;
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
        drawer: _buildDrawer(context), // Add the Drawer here
        body: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                "assets/images/backparttern.png",
                color: Colors.black.withOpacity(0.3), // Adjust opacity here
                colorBlendMode: BlendMode.srcATop,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              child: Container(
                color: whiteColor,
              ),
            ),
            // Main Content
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
                        'Welcome $userFullNames',
                        style: const TextStyle(
                          fontSize: 20,
                          color: blackColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const SizedBox(height: 20),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildServiceRow(context, [
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
                        ]),
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
              "Powerd by Besoft & BePay ltd",
              style: GoogleFonts.poppins(fontSize: 12, color: blackColor),
            ),
          ),
        ),
      ),
    );
  }

  void _showMotorbikersBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: const BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(left: 16.0),
                child: Text(
                  'Select Classroom for $selectedService ',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: primaryColor),
                ),
              ),
              const SizedBox(height: 20),
              BlocConsumer<SchoolClassroomBloc, SchoolClassroomState>(
                listener: (context, state) {
                  // TODO: implement listener
                },
                builder: (context, state) {
                  if (state is SchoolClassroomLoading) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 70.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 20),
                                Text(
                                  'Loading classroom for $selectedService',
                                  style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black),
                                ),
                                const SizedBox(height: 20),
                                const SpinKitDoubleBounce(
                                  color: primaryColor,
                                  size: 40,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is SchoolClassroomSuccess) {
                    if (state.schoolClassroomModel.data!.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 70.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.grey, width: 2),
                                ),
                                padding: const EdgeInsets.all(
                                    20), // adjust padding for icon size
                                child: const Icon(
                                  Icons.inbox, // use any icon you prefer
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(
                                  height: 16), // space between icon and text
                              Text(
                                'No Classroom found',
                                style: GoogleFonts.poppins(fontSize: 18),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Expanded(
                      child: ListView.builder(
                        itemCount: state.schoolClassroomModel.data!.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: whiteColor1,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color.fromARGB(255, 188, 188, 188)
                                          .withOpacity(0.1),
                                  spreadRadius: 2,
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${state.schoolClassroomModel.data![index].name}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w500,
                                          color: primaryColor,
                                        ),
                                      ),
                                      Text(
                                        'School: \n${state.schoolClassroomModel.data![index].school!.name}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ],
          ),
        );
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
                selectedService = service['service']!;
              });
              _showMotorbikersBottomSheet(context);
              schoolClassroomBloc.add(FetchSchoolClassroomEvent(token: "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhZG1pbkBzdHVkZW50LmNvbSIsImlhdCI6MTczNzgxMzA5MSwiZXhwIjoxNzM3ODQ5MDkxfQ.SkSR8wVjLIKNQtNTGEnNG6881pOno_CSDpIfyxCRc70"));
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
                        fontSize: 23, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // For navigation
  void onBackPress() {
    context.safePop(); // Uses the extension
  }
}

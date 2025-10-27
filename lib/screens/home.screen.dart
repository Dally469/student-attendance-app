import 'dart:async';
import 'dart:convert';
import 'package:attendance/controllers/attendance_controller.dart';
import 'package:attendance/controllers/school_classroom_controller.dart';
import 'package:attendance/controllers/school_fees_controller.dart';
import 'package:attendance/controllers/sms.controller.dart';
import 'package:attendance/models/classroom.model.dart';
import 'package:attendance/models/school.fee.type.dart';
import 'package:attendance/models/student.model.dart';
import 'package:attendance/routes/routes.names.dart';
import 'package:attendance/screens/create.attendance.bottomsheet.dart';
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

class _HomeState extends State<Home> with TickerProviderStateMixin {
  String? userFullNames, schoolName, schoolLogo, schoolId;
  RxString selectedService = "".obs;
  RxBool isCreatingAttendance = false.obs;
  RxBool isConnected = true.obs;

  final SchoolClassroomController _schoolClassroomController =
      Get.find<SchoolClassroomController>();
  final AttendanceController _attendanceController =
      Get.find<AttendanceController>();
  final SchoolFeesController _schoolFeesController =
      Get.find<SchoolFeesController>();
  final SMSController _smsController = Get.find<SMSController>();

  @override
  void initState() {
    super.initState();
    getCurrentUserInfo();
    _schoolClassroomController.getSchoolClassrooms();
  }

  Future<void> getCurrentUserInfo() async {
    try {
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      String? userJson = sharedPreferences.getString("currentUser");
      String? schoolJson = sharedPreferences.getString("currentSchool");

      debugPrint("User JSON: $userJson");
      debugPrint("School JSON: $schoolJson");

      if (userJson != null && userJson != 'no') {
        Map<String, dynamic> userMap = jsonDecode(userJson);

        setState(() {
          // Set user full names
          userFullNames =
              '${userMap['firstName'] ?? '---'} ${userMap['lastName'] ?? '---'}';
        });

        // Handle school information - check multiple sources
        Map<String, dynamic>? schoolMap;

        // First, try to get school info from separate schoolJson
        if (schoolJson != null && schoolJson != 'no' && schoolJson.isNotEmpty) {
          try {
            schoolMap = jsonDecode(schoolJson);
            debugPrint("School info found in separate storage");
          } catch (e) {
            debugPrint("Error parsing school JSON: $e");
            schoolMap = null;
          }
        }

        // If no separate school info, check if it's embedded in user data
        if (schoolMap == null &&
            userMap.containsKey('school') &&
            userMap['school'] != null) {
          schoolMap = userMap['school'] as Map<String, dynamic>;
          debugPrint("School info found in user data");
        }

        // Update state with school information
        setState(() {
          if (schoolMap != null) {
            schoolName = schoolMap['name'] ?? 'Unknown School';
            schoolLogo = schoolMap['logo'];
            schoolId = schoolMap['id'];
            _smsController.schoolId = schoolMap['id'];

            if (kDebugMode) {
              print("School Name: ${schoolMap['name']}");
            }
          } else {
            debugPrint("No school information found");
            schoolName = 'No School Assigned';
            schoolLogo = null;
            schoolId = null;
          }
        });

        debugPrint("School ID: $schoolId");
        debugPrint("School Name: $schoolName");

        // Only call these functions if schoolId is available
        if (schoolId != null) {
          _schoolFeesController.fetchFeeTypes(schoolId!);
          _smsController.getSMSBalance();
        } else {
          debugPrint(
              "Warning: School ID is null, skipping fee types and SMS balance fetch");
        }
      } else {
        debugPrint("No user data found in SharedPreferences");
        setState(() {
          userFullNames = '--- ---';
          schoolName = 'No School';
          schoolLogo = null;
          schoolId = null;
        });
      }
    } catch (e) {
      debugPrint('Error getting user info: $e');

      // Set default values in case of error
      setState(() {
        userFullNames = 'Error Loading User';
        schoolName = 'Error Loading School';
        schoolLogo = null;
        schoolId = null;
      });
    }
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: primaryColor,
      elevation: 0,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: primaryColor),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: Text(
                userFullNames?.isNotEmpty == true
                    ? userFullNames![0].toUpperCase()
                    : "U",
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor),
                semanticsLabel: 'User initial',
              ),
            ),
            accountName: Text(
              userFullNames ?? '---',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 16),
            ),
            accountEmail: Text(
              schoolName ?? '---',
              style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                  fontWeight: FontWeight.w300),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.dashboard,
                color: Theme.of(context).colorScheme.onPrimary,
                semanticLabel: 'Dashboard'),
            title: Text('Dashboard',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w300,
                    fontSize: 16)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.history,
                color: Theme.of(context).colorScheme.onPrimary,
                semanticLabel: 'Student History'),
            title: Text('Student History',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w300,
                    fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              Get.toNamed(myRequests);
            },
          ),
          // ListTile(
          //   leading: Icon(Icons.school,
          //       color: Theme.of(context).colorScheme.onPrimary,
          //       semanticLabel: 'School'),
          //   title: Text('Schools',
          //       style: TextStyle(
          //           color: Theme.of(context).colorScheme.onPrimary,
          //           fontWeight: FontWeight.w300,
          //           fontSize: 16)),
          //   onTap: () {
          //     Navigator.pop(context);
          //     Get.toNamed(schools);
          //   },
          // ),
          const Spacer(),
          Divider(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.3)),
          ListTile(
            leading: Icon(Icons.logout,
                color: Theme.of(context).colorScheme.onPrimary,
                semanticLabel: 'Logout'),
            title: Text('Logout',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            onTap: _handleLogout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Logout',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
          content: Text('Are you sure you want to logout?',
              style: GoogleFonts.poppins(fontSize: 14)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface))),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (mounted) {
                  Get.toNamed(splash);
                }
              },
              child: Text('Logout',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }

  Future<bool> _onWillPop() async => false;

  void _showClassroomBottomSheet(BuildContext context,
      {FeesData? selectedFeeType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      elevation: 10,
      enableDrag: true,
      builder: (context) => _ClassroomBottomSheet(
        selectedService: selectedService,
        schoolClassroomController: _schoolClassroomController,
        onClassroomSelected: (classroom) => _handleClassroomSelection(classroom,
            selectedFeeType: selectedFeeType),
      ),
    );
  }

  void _showSingleStudentBottomSheet(BuildContext context,
      {FeesData? selectedFeeType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      elevation: 10,
      enableDrag: true,
      builder: (context) => SingleStudentBottomSheet(
        selectedService: selectedService,
        schoolClassroomController: _schoolClassroomController,
        selectedFeeType: selectedFeeType,
        onStudentSelected: (student, {selectedFeeType}) =>
            _handleStudentSelection(student, selectedFeeType: selectedFeeType),
      ),
    );
  }

  void _showFeeConfirmationDialog(FeesData feeType,
      VoidCallback onSingleStudent, VoidCallback onConfirmClassroom) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    color: primaryColor, size: 24, semanticLabel: 'Fee icon'),
                const SizedBox(width: 8),
                Text('Apply Fee',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, fontSize: 18)),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close,
                  color: redColor, size: 24, semanticLabel: 'Close'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: Text(
          'You have selected "${feeType.name ?? 'Unknown'}" (\$${feeType.amount?.toStringAsFixed(2) ?? '0.00'}). '
          'Please select a class or student to apply this fee.',
          style: GoogleFonts.poppins(
              fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          Semantics(
            button: true,
            label: 'Continue to select student',
            child: ElevatedButton(
              onPressed: () {
                Get.back();
                onSingleStudent();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: orangeColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                elevation: 2,
                shadowColor: orangeColor.withOpacity(0.3),
              ),
              child: Text('Single Student',
                  style: GoogleFonts.poppins(fontSize: 14)),
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: 'Continue to select class',
            child: ElevatedButton(
              onPressed: () {
                Get.back();
                onConfirmClassroom();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                elevation: 2,
                shadowColor: primaryColor.withOpacity(0.3),
              ),
              child:
                  Text('Classroom', style: GoogleFonts.poppins(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttendanceConfigBottomSheet(
      BuildContext context, Classrooms classroomData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => AttendanceConfigBottomSheet(
        classroom: classroomData,
        onAttendanceReady: (String attendanceId) {
          // Navigate to attendance screen with the attendance ID
          Get.toNamed(makeAttendance, parameters: {
            'classroomId': classroomData.id.toString(),
            'classroom': classroomData.name.toString(),
            'attendanceId': attendanceId,
          });
        },
      ),
    );
  }


  void _handleClassroomSelection(Classrooms classroomData,
      {FeesData? selectedFeeType}) {
    if (selectedService.value == 'fees' && selectedFeeType != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.school_rounded,
                  color: primaryColor,
                  size: 24,
                  semanticLabel: 'Classroom icon'),
              const SizedBox(width: 8),
              Text('Confirm Fee Application',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 18)),
            ],
          ),
          content: Text(
            'Apply "${selectedFeeType.name ?? 'Unknown'}" (\$${selectedFeeType.amount?.toStringAsFixed(2) ?? '0.00'}) '
            'to class "${classroomData.name ?? 'Unknown'}"?',
            style: GoogleFonts.poppins(
                fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
          ),
          actions: [
            Semantics(
              button: true,
              label: 'Cancel fee application',
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.1),
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  elevation: 0,
                ),
                child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 14)),
              ),
            ),
            Semantics(
              button: true,
              label: 'Apply fee to class',
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Close dialog
                  await _applyFeeToClass(classroomData, selectedFeeType);
                  Navigator.pop(context); // Close bottom sheet
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  elevation: 2,
                  shadowColor: primaryColor.withOpacity(0.3),
                ),
                child: Obx(() => _schoolFeesController.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text('Apply Fee',
                        style: GoogleFonts.poppins(fontSize: 14))),
              ),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context); // Close bottom sheet
      switch (selectedService.value) {
        case 'card':
          Get.toNamed(assignCard, parameters: {
            'classroom': classroomData.name.toString(),
            'classroomId': classroomData.id.toString(),
          });
          break;
        case 'attendance':
          _showAttendanceConfigBottomSheet(context, classroomData);
          break;
        case 'communication':
          Get.toNamed(parentCommunication, parameters: {
            'classroom': classroomData.name.toString(),
            'classroomId': classroomData.id.toString(),
          });
          break;
        case 'sms':
          Get.toNamed('/sms-topup'); // Add this route to your routes
          break;
        case 'fees':
          // Handled in the dialog above
          break;
      }
    }
  }

  void _handleStudentSelection(StudentData student,
      {FeesData? selectedFeeType}) {
    if (selectedService.value == 'fees' && selectedFeeType != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: primaryColor, size: 24, semanticLabel: 'Fee icon'),
              const SizedBox(width: 8),
              Text('Confirm Fee Application',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 18)),
            ],
          ),
          content: Text(
            'Apply "${selectedFeeType.name ?? 'Unknown'}" (\$${selectedFeeType.amount?.toStringAsFixed(2) ?? '0.00'}) '
            'to student "${student.name ?? 'Unknown'}"?',
            style: GoogleFonts.poppins(
                fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
          ),
          actions: [
            Semantics(
              button: true,
              label: 'Cancel fee application',
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.1),
                  foregroundColor: Theme.of(context).colorScheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  elevation: 0,
                ),
                child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 14)),
              ),
            ),
            Semantics(
              button: true,
              label: 'Apply fee to student',
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context); // Close dialog
                  await _applyFeeToStudent(student, selectedFeeType);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  elevation: 2,
                  shadowColor: primaryColor.withOpacity(0.3),
                ),
                child: Obx(() => _schoolFeesController.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text('Apply Fee',
                        style: GoogleFonts.poppins(fontSize: 14))),
              ),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context); // Close bottom sheet
      switch (selectedService.value) {
        case 'card':
          Get.toNamed(assignCard, parameters: {
            'studentId': student.id.toString(),
            'studentName': student.name.toString(),
          });
          break;
        case 'attendance':
          isCreatingAttendance.value = true;
          // _attendanceController.createAttendanceForStudent(student.id.toString());
          late StreamSubscription successSubscription;
          successSubscription =
              _attendanceController.successMessage.listen((message) {
            if (message.isNotEmpty) {
              Future.delayed(const Duration(milliseconds: 300), () {
                String attendanceId =
                    _attendanceController.currentAttendance.value?.data?.id ??
                        _attendanceController.attendanceId.value;
                isCreatingAttendance.value = false;
                successSubscription.cancel();
                if (attendanceId.isNotEmpty && context.mounted) {
                  Get.toNamed(makeAttendance, parameters: {
                    'studentId': student.id.toString(),
                    'studentName': student.name.toString(),
                    'attendanceId': attendanceId,
                  });
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Failed to get attendance ID. Please try again.'),
                        backgroundColor: Colors.red),
                  );
                }
              });
            }
          });
          late StreamSubscription errorSubscription;
          errorSubscription =
              _attendanceController.errorMessage.listen((errorMessage) {
            if (errorMessage.isNotEmpty) {
              Future.delayed(const Duration(milliseconds: 300), () {
                isCreatingAttendance.value = false;
                errorSubscription.cancel();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(errorMessage),
                        backgroundColor: Colors.red),
                  );
                }
              });
            }
          });
          break;
        case 'communication':
          Get.toNamed(parentCommunication, parameters: {
            'studentId': student.id.toString(),
            'studentName': student.name.toString(),
          });
          break;
        case 'fees':
          // Handled in the dialog above
          break;
      }
    }
  }

  Future<void> _applyFeeToClass(Classrooms classroom, FeesData feeType) async {
    try {
      await _schoolFeesController.applyFee(
        classroomId: classroom.id.toString(),
        feeTypeId: feeType.id ?? '',
        amount: feeType.amount ?? 0.0,
        dueDate: DateTime.now().toIso8601String(),
        academicYear: feeType.academicYear ?? '',
        term: feeType.term ?? '',
        isClassLevel: true,
      );

      late StreamSubscription successSubscription;
      late StreamSubscription errorSubscription;

      successSubscription =
          _schoolFeesController.successMessage.listen((message) {
        if (message.isNotEmpty && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
              backgroundColor: primaryColor,
              duration: const Duration(seconds: 3),
            ),
          );
          successSubscription.cancel();
        }
      });

      errorSubscription =
          _schoolFeesController.errorMessage.listen((errorMessage) {
        if (errorMessage.isNotEmpty && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(errorMessage, style: GoogleFonts.poppins(fontSize: 14)),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
          errorSubscription.cancel();
        }
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error applying fee: $e',
                style: GoogleFonts.poppins(fontSize: 14)),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _applyFeeToStudent(StudentData student, FeesData feeType) async {
    try {
      await _schoolFeesController.applyFee(
        classroomId: '',
        feeTypeId: feeType.id ?? '',
        amount: feeType.amount ?? 0.0,
        dueDate: DateTime.now().toIso8601String(),
        academicYear: feeType.academicYear ?? '',
        term: feeType.term ?? '',
        isClassLevel: false,
        singleStudentId: student.id.toString(),
      );

      late StreamSubscription successSubscription;
      late StreamSubscription errorSubscription;

      successSubscription =
          _schoolFeesController.successMessage.listen((message) {
        if (message.isNotEmpty && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
              backgroundColor: primaryColor,
              duration: const Duration(seconds: 3),
            ),
          );
          successSubscription.cancel();
        }
      });

      errorSubscription =
          _schoolFeesController.errorMessage.listen((errorMessage) {
        if (errorMessage.isNotEmpty && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(errorMessage, style: GoogleFonts.poppins(fontSize: 14)),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
          errorSubscription.cancel();
        }
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error applying fee: $e',
                style: GoogleFonts.poppins(fontSize: 14)),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildServiceCard(String title, String image, String service,
      {bool hasHistory = false, String? historyRoute}) {
    return Hero(
      tag: 'service_card_$service',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final iconSize = constraints.maxWidth * 0.14;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: double.infinity,
            child: Card(
              elevation: 8,
              shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                splashColor: Theme.of(context).primaryColor.withOpacity(0.3),
                highlightColor: Theme.of(context).primaryColor.withOpacity(0.1),
                onTap: () {
                  HapticFeedback.lightImpact();
                  selectedService.value = service;

                  if (service == 'fees') {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _buildFeeTypesBottomSheet(),
                    );
                  } else if (service == 'sms') {
                    debugPrint('SMS');
                  } else {
                    _showClassroomBottomSheet(context);
                    _schoolClassroomController.getSchoolClassrooms();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Image.asset(
                          image,
                          color: Theme.of(context).primaryColor,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.error,
                            color: Colors.red,
                            semanticLabel: 'Error loading image',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _getServiceDescription(service),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w300,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          if (hasHistory && historyRoute != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Get.toNamed(smsHistory);
                                },
                                child: Text(
                                  'Show',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  semanticsLabel: 'Show history',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.3),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 18,
                              semanticLabel: 'Proceed',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeeTypesBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton(
                      icon: Icon(Icons.close,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          semanticLabel: 'Close'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: primaryColor,
                          size: 24,
                          semanticLabel: 'Fee type icon'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Select a Fee Type',
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (_schoolFeesController.isLoading.value) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SpinKitDoubleBounce(
                              color: primaryColor, size: 40),
                          const SizedBox(height: 16),
                          Text(
                            'Loading fee types...',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                          ),
                        ],
                      ),
                    );
                  }
                  if (_schoolFeesController.errorMessage.value.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              semanticLabel: 'Error'),
                          const SizedBox(height: 16),
                          Text(
                            _schoolFeesController.errorMessage.value,
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                _schoolFeesController.fetchFeeTypes(schoolId!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Retry',
                                style: GoogleFonts.poppins(fontSize: 14)),
                          ),
                        ],
                      ),
                    );
                  }
                  if (_schoolFeesController.feeTypes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              semanticLabel: 'No fee types'),
                          const SizedBox(height: 16),
                          Text(
                            'No fee types available',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No fee types have been set up for this school.',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _schoolFeesController.feeTypes.length,
                    itemBuilder: (context, index) {
                      final feeType = _schoolFeesController.feeTypes[index];
                      return _buildFeeTypeCard(feeType);
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeeTypeCard(FeesData feeType) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () {
          _showFeeConfirmationDialog(
            feeType,
            () {
              Future.delayed(const Duration(milliseconds: 300), () {
                _showSingleStudentBottomSheet(context,
                    selectedFeeType: feeType);
                _schoolClassroomController.getSchoolClassrooms();
              });
            },
            () {
              Future.delayed(const Duration(milliseconds: 300), () {
                _showClassroomBottomSheet(context, selectedFeeType: feeType);
                _schoolClassroomController.getSchoolClassrooms();
              });
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.account_balance_wallet_rounded,
                      color: primaryColor, size: 24, semanticLabel: 'Fee type'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feeType.name ?? 'Unknown',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${feeType.amount?.toStringAsFixed(2) ?? '0.00'}',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: primaryColor),
                      ),
                      if (feeType.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          feeType.description!,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_forward,
                      size: 20,
                      color: primaryColor,
                      semanticLabel: 'Select fee'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getServiceDescription(String service) {
    switch (service) {
      case 'card':
        return 'Assign RFID cards to students';
      case 'attendance':
        return 'Record student attendance';
      case 'communication':
        return 'Communicate with parents or students';
      case 'fees':
        return 'Manage school fees for students';
      case 'sms':
        return 'Manage SMS credits and view balance';

      case 'facial':
        return 'Manage facial recognition for students';
      default:
        return '';
    }
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
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20))),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.school,
                    color: primaryColor, semanticLabel: 'School icon'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  schoolName ?? 'School App',
                  style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  semanticLabel: 'Notifications'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('No new notifications',
                        style: GoogleFonts.poppins(fontSize: 14)),
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
          onRefresh: () async =>
              _schoolClassroomController.getSchoolClassrooms(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                  color:
                                      Theme.of(context).colorScheme.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // StreamBuilder<ConnectivityResult>(
                            //   stream: Connectivity().onConnectivityChanged,
                            //   builder: (context, snapshot) {
                            //     final isOnline =
                            //         snapshot.data != ConnectivityResult.none;
                            //     isConnected.value = isOnline;
                            //     return Row(
                            //       children: [
                            //         Icon(
                            //           isOnline ? Icons.wifi : Icons.wifi_off,
                            //           color: isOnline
                            //               ? primaryColor
                            //               : Colors.orange,
                            //           size: 16,
                            //           semanticLabel:
                            //               isOnline ? 'Online' : 'Offline',
                            //         ),
                            //         const SizedBox(width: 8),
                            //         Text(
                            //           isOnline ? 'Online' : 'Offline',
                            //           style: GoogleFonts.poppins(
                            //               fontSize: 14,
                            //               color: isOnline
                            //                   ? primaryColor
                            //                   : Colors.orange),
                            //         ),
                            //       ],
                            //     );
                            //   },
                            //   initialData: ConnectivityResult.none,
                            // ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: primaryColorOverlay.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.person,
                            color: primaryColor,
                            size: 24,
                            semanticLabel: 'User avatar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'What would you like to do?',
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: 0.3,
                        height: 1.2),
                  ),
                  const SizedBox(height: 24),
                  _buildServiceCard(
                      'Assign Student Card', 'assets/images/nfc.png', 'card'),
                  const SizedBox(height: 16),
                  _buildServiceCard('Record Attendance',
                      'assets/images/attendance.png', 'attendance'),
                  const SizedBox(height: 16),
                  _buildServiceCard('Parent Communication',
                      'assets/images/chat.png', 'communication'),
                  const SizedBox(height: 16),
                  // _buildServiceCard('Manage School Fees',
                  //     'assets/images/tuition-fees.png', 'fees',
                  //     hasHistory: true, historyRoute: feeHistory),
                  const SizedBox(height: 16),
                  _buildServiceCard(
                      'SMS Top-up & Balance', 'assets/images/sms.png', 'sms',
                      hasHistory: true, historyRoute: smsHistory),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassroomBottomSheet extends StatefulWidget {
  final RxString selectedService;
  final SchoolClassroomController schoolClassroomController;
  final void Function(Classrooms) onClassroomSelected;

  const _ClassroomBottomSheet({
    required this.selectedService,
    required this.schoolClassroomController,
    required this.onClassroomSelected,
  });

  @override
  _ClassroomBottomSheetState createState() => _ClassroomBottomSheetState();
}

class _ClassroomBottomSheetState extends State<_ClassroomBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();

    // Initialize search controller with current search query
    _searchController.text = widget.schoolClassroomController.searchQuery.value;

    // Listen to controller's search query changes
    ever(widget.schoolClassroomController.searchQuery, (query) {
      if (_searchController.text != query) {
        _searchController.text = query;
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    // Clear search when bottom sheet closes
    widget.schoolClassroomController.clearSearch();
    super.dispose();
  }

  Widget _buildClassroomList() {
    return Obx(() {
      if (widget.schoolClassroomController.isLoading.value) {
        return _buildLoadingState();
      }
      if (widget.schoolClassroomController.errorMessage.value.isNotEmpty) {
        return _buildEmptyState();
      }

      // Use filtered classrooms instead of all classrooms
      if (widget.schoolClassroomController.filteredClassrooms.isNotEmpty) {
        return _buildClassroomListContent();
      }

      // Show different empty state based on whether user is searching
      if (widget.schoolClassroomController.searchQuery.value.isNotEmpty) {
        return _buildNoSearchResultsState();
      }

      return _buildEmptyState();
    });
  }

  Widget _buildLoadingState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SpinKitDoubleBounce(color: primaryColor, size: 40),
            const SizedBox(height: 16),
            Text(
              'Loading classrooms...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              semanticLabel: 'No classrooms',
            ),
            const SizedBox(height: 16),
            Text(
              'No classrooms found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'You don\'t have any classrooms assigned to your school yet.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => widget.schoolClassroomController
                  .getSchoolClassrooms(forceRefresh: true),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text('Retry', style: GoogleFonts.poppins(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              semanticLabel: 'No search results',
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Obx(() => Text(
                    'No classrooms match "${widget.schoolClassroomController.searchQuery.value}"',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  )),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                widget.schoolClassroomController.clearSearch();
                _searchController.clear();
                _searchFocusNode.unfocus();
              },
              icon: const Icon(Icons.clear, size: 18),
              label: Text('Clear search',
                  style: GoogleFonts.poppins(fontSize: 14)),
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassroomListContent() {
    return Expanded(
      child: Column(
        children: [
          // Show result count
          Obx(() {
            final filteredCount =
                widget.schoolClassroomController.filteredClassrooms.length;
            final totalCount =
                widget.schoolClassroomController.classrooms.length;
            final isSearching =
                widget.schoolClassroomController.searchQuery.value.isNotEmpty;

            if (!isSearching) return const SizedBox.shrink();

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Text(
                    'Found $filteredCount of $totalCount classroom${totalCount != 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Classroom list
          Expanded(
            child: Obx(() => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: widget
                      .schoolClassroomController.filteredClassrooms.length,
                  itemBuilder: (context, index) => _buildClassroomCard(
                    widget.schoolClassroomController.filteredClassrooms[index],
                    widget.selectedService.value,
                  ),
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Obx(() => TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onChanged: (value) =>
                widget.schoolClassroomController.searchClassrooms(value),
            decoration: InputDecoration(
              hintText: 'Search classrooms...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withOpacity(0.6),
              ),
              prefixIcon:
                  const Icon(Icons.search, color: primaryColor, size: 20),
              suffixIcon:
                  widget.schoolClassroomController.searchQuery.value.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            widget.schoolClassroomController.clearSearch();
                            _searchController.clear();
                            _searchFocusNode.unfocus();
                          },
                          tooltip: 'Clear search',
                        )
                      : null,
              filled: true,
              fillColor:
                  Theme.of(context).colorScheme.background.withOpacity(0.3),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryColor, width: 2),
              ),
            ),
            style: GoogleFonts.poppins(fontSize: 14),
          )),
    );
  }

  Widget _buildClassroomCard(Classrooms classroom, String service) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          widget.onClassroomSelected(classroom);
          // Clear search and close keyboard on selection
          widget.schoolClassroomController.clearSearch();
          _searchFocusNode.unfocus();
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: primaryColor.withOpacity(0.3),
        highlightColor: primaryColor.withOpacity(0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      classroom.name?.substring(0, 1).toUpperCase() ?? 'C',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                      semanticsLabel:
                          'Classroom ${classroom.name ?? 'Unknown'} initial',
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classroom.name ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Text(
                                '${classroom.statistics?.maleCount} Male',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: orangeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Text(
                                '${classroom.statistics?.femaleCount} Female',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withOpacity(0.7),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 60),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: primaryColor,
                    semanticLabel: 'Select classroom',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getServiceIcon(String service) {
    switch (service) {
      case 'card':
        return Icons.credit_card_rounded;
      case 'attendance':
        return Icons.checklist_rounded;
      case 'communication':
        return Icons.message_rounded;
      case 'fees':
        return Icons.account_balance_wallet_rounded;
      case 'facial':
        return Icons.face_rounded;
      default:
        return Icons.checklist_rounded;
    }
  }

  String _getBottomSheetTitle(String service) {
    switch (service) {
      case 'card':
        return 'Select a Class to Assign Cards';
      case 'attendance':
        return 'Select a Class for Attendance';
      case 'communication':
        return 'Select a Class for Parent Communication';
      case 'fees':
        return 'Select a Class to Manage Fees';
      case 'facial':
        return 'Select a Class to Assign Facial Data';
      default:
        return 'Select a Class';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 5,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle and close button
              Stack(
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        semanticLabel: 'Close',
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title with icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Obx(() => Icon(
                            _getServiceIcon(widget.selectedService.value),
                            color: primaryColor,
                            size: 24,
                            semanticLabel: 'Service icon',
                          )),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Obx(() => Text(
                            _getBottomSheetTitle(widget.selectedService.value),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.3,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          )),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search field - only show if there are classrooms
              Obx(() {
                if (widget.schoolClassroomController.classrooms.isEmpty &&
                    !widget.schoolClassroomController.isLoading.value) {
                  return const SizedBox.shrink();
                }
                return _buildSearchField();
              }),

              const SizedBox(height: 8),

              // Classroom list
              _buildClassroomList(),
            ],
          ),
        );
      },
    );
  }
}

class SingleStudentBottomSheet extends StatefulWidget {
  final RxString selectedService;
  final SchoolClassroomController schoolClassroomController;
  final FeesData? selectedFeeType;
  final void Function(StudentData, {FeesData? selectedFeeType})
      onStudentSelected;

  const SingleStudentBottomSheet({
    Key? key,
    required this.selectedService,
    required this.schoolClassroomController,
    this.selectedFeeType,
    required this.onStudentSelected,
  }) : super(key: key);

  @override
  _SingleStudentBottomSheetState createState() =>
      _SingleStudentBottomSheetState();
}

class _SingleStudentBottomSheetState extends State<SingleStudentBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final TextEditingController _searchController = TextEditingController();
  final SchoolFeesController _schoolFeesController =
      Get.find<SchoolFeesController>();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _schoolFeesController.searchStudents(_searchController.text);
      } else {
        _schoolFeesController.students.clear();
        _schoolFeesController.errorMessage.value = '';
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildSearchField(context),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Obx(() => Text(
                        'Total Results: ${_schoolFeesController.students.length}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      )),
                ),
                Expanded(
                  child: Obx(() {
                    if (_schoolFeesController.isLoading.value) {
                      return _buildLoadingState(context);
                    }
                    if (_schoolFeesController.errorMessage.value.isNotEmpty) {
                      return _buildErrorState(context);
                    }
                    if (_schoolFeesController.students.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _schoolFeesController.students.length,
                      itemBuilder: (context, index) => SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.2, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: _animationController,
                            curve: Interval(index * 0.1, 1.0,
                                curve: Curves.easeOut),
                          ),
                        ),
                        child: _buildStudentCard(
                            context, _schoolFeesController.students[index]),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: IconButton(
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              semanticLabel: 'Close bottom sheet',
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  color: primaryColor,
                  size: 24,
                  semanticLabel: 'Search student',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search Student',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Enter student code or name',
          hintStyle: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(Icons.search,
              color: primaryColor, semanticLabel: 'Search'),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      semanticLabel: 'Clear search'),
                  onPressed: () {
                    _searchController.clear();
                    _schoolFeesController.students.clear();
                    _schoolFeesController.errorMessage.value = '';
                  },
                )
              : const SizedBox.shrink(),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor:
              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        style: GoogleFonts.poppins(fontSize: 14),
        textInputAction: TextInputAction.search,
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            _schoolFeesController.searchStudents(value);
          }
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SpinKitDoubleBounce(color: primaryColor, size: 40),
          const SizedBox(height: 16),
          Text(
            'Searching students...',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
            semanticLabel: 'Error',
          ),
          const SizedBox(height: 16),
          Text(
            _schoolFeesController.errorMessage.value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              if (_searchController.text.isNotEmpty) {
                _schoolFeesController.searchStudents(_searchController.text);
              }
            },
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            semanticLabel: 'No students found',
          ),
          const SizedBox(height: 16),
          Text(
            'No students found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with a different code or name',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, StudentData student) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        onTap: () => widget.onStudentSelected(student,
            selectedFeeType: widget.selectedFeeType),
        borderRadius: BorderRadius.circular(12),
        splashColor: primaryColor.withOpacity(0.3),
        highlightColor: primaryColor.withOpacity(0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Text(
                    student.name?.substring(0, 1).toUpperCase() ?? 'S',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    semanticsLabel:
                        'Student ${student.name ?? 'Unknown'} initial',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name ?? 'Unknown',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        student.code ?? 'No code',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (student.classroom != null)
                        Text(
                          student.classroom!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                                .withOpacity(0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: primaryColor,
                    semanticLabel:
                        'Select student ${student.name ?? 'Unknown'}',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

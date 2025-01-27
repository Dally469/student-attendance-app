import 'dart:convert';
import 'dart:io';

import 'package:attendance/api/auth.service.dart';
import 'package:attendance/states/classroom.student/classroom_student_bloc.dart';
import 'package:attendance/states/make.attendance/make_attendance_bloc.dart';
import 'package:attendance/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'package:connectivity_plus/connectivity_plus.dart';

class AttendancePage extends StatefulWidget {
  final String? classroomId;
  final String? classroom;
  final String? attendanceId;

  const AttendancePage({
    Key? key,
    this.classroomId,
    this.classroom,
    this.attendanceId,
  }) : super(key: key);

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  bool isReading = false;
  bool isNfcAvailable = false;
  late AttendanceBloc attendanceBloc;
  ClassroomStudentBloc classroomStudentBloc =
      ClassroomStudentBloc(ClassroomStudentInitial(), AuthService());

  @override
  void initState() {
    super.initState();
    attendanceBloc = BlocProvider.of<AttendanceBloc>(context);
    classroomStudentBloc = BlocProvider.of<ClassroomStudentBloc>(context);

    checkNfcAvailability();
  }

  Future<void> checkNfcAvailability() async {
    try {
      isNfcAvailable = await NfcManager.instance.isAvailable();
      setState(() {});
      if (isNfcAvailable) {
        startNfcSession();
      }
    } catch (e) {
      debugPrint('NFC Availability Error: $e');
      setState(() {
        isNfcAvailable = false;
      });
    }
  }

  Future<void> startNfcSession() async {
    if (!isNfcAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC is not available on this device')),
      );
      return;
    }

    setState(() {
      isReading = true;
    });

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final tagId = tag.data['nfca']?['identifier'] ??
                tag.data['isodep']?['identifier'] ??
                tag.data['mifareclassic']?['identifier'] ??
                tag.data['mifareultralight']?['identifier'];

            if (tagId != null) {
              final cardId = tagId
                  .map((e) => e.toRadixString(16).padLeft(2, '0'))
                  .join('');

              // Get student ID from card ID using your card mapping service
              // For now, we'll assume you have a method to get this
              final studentId = await getStudentIdFromCard(
                  widget.classroom.toString(), cardId);

              if (studentId != null) {
                attendanceBloc.add(CheckInEvent(
                  studentId: studentId,
                  classroomId: widget.classroomId.toString(),
                  attendanceId: widget.attendanceId.toString(),
                ));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Card not registered to any student'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          } catch (e) {
            debugPrint('Error processing NFC tag: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error processing card: $e')),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('NFC Session Error: $e');
      setState(() {
        isReading = false;
      });
    }
  }

  Future<String?> getStudentIdFromCard(String classroom, String cardId) async {
    try {
      // Get the app's document directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$classroom.json';

      // Read the file
      File file = File(filePath);
      if (await file.exists()) {
        String fileContent = await file.readAsString();

        // Decode the JSON data
        Map<String, dynamic> data = jsonDecode(fileContent);

        // Search for the student with the specified card ID
        if (data.containsKey('data')) {
          List students = data['data'];
          for (var student in students) {
            if (student['cardId'] == cardId) {
              return student['id'];
            }
          }
        }
      } else {
        print('File does not exist: $filePath');
      }
    } catch (e) {
      print('Error reading data from file: $e');
    }

    return null; // Return null if the student ID is not found
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
          toolbarHeight: 100, // Set the height of the AppBar
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "${widget.classroom.toString()}",
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            StreamBuilder<ConnectivityResult>(
              stream: Connectivity().onConnectivityChanged,
              builder: (context, snapshot) {
                bool isOnline = snapshot.data != ConnectivityResult.none;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        isOnline ? Icons.wifi : Icons.wifi_off,
                        color: isOnline ? Colors.white : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 24,
                          color: isOnline ? Colors.white : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<AttendanceBloc, AttendanceState>(
          listener: (context, state) {
            if (state is AttendanceSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.isOffline
                            ? 'Attendance marked offline'
                            : 'Welcome ${state.checkInModel.data?.studentId ?? ""}!',
                      ),
                      if (!state.isOffline && state.checkInModel.data != null)
                        Text(
                          'Check-in time: ${state.checkInModel.data!.checkInTime}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  backgroundColor: state.isOffline ? Colors.orange : Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else if (state is AttendanceError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!isNfcAvailable)
                            const Column(
                              children: [
                                Icon(
                                  Icons.nfc,
                                  size: 64,
                                  color: Colors.red,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'NFC is not available on this device',
                                  style:
                                      TextStyle(color: Colors.red, fontSize: 18),
                                ),
                              ],
                            )
                          else ...[
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.withOpacity(0.1),
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.nfc,
                                  size: 64,
                                  color: state is AttendanceLoading
                                      ? Colors.grey
                                      : Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              state is AttendanceLoading
                                  ? 'Processing...'
                                  : 'Tap your card to mark attendance',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // Recent activity section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Recent Activity',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: BlocBuilder<AttendanceBloc, AttendanceState>(
                          builder: (context, state) {
                            if (state is AttendanceSuccess) {
                              return ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                                title: Text(
                                  state.checkInModel.data?.studentId ?? 'Unknown',
                                ),
                                subtitle: Text(
                                  'Status: ${state.checkInModel.data?.status ?? "Unknown"}',
                                ),
                                trailing: Text(
                                  state.checkInModel.data?.checkInTime ?? '',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              );
                            }
                            return const Center(
                              child: Text('No recent activity'),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }
}

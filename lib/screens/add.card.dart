import 'package:attendance/routes/routes.names.dart';
import 'package:attendance/routes/routes.provider.dart';
import 'package:attendance/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../states/assign.student.card/assign_student_card_bloc.dart';

class AssignCardPage extends StatefulWidget {
  final String? studentName;
  final String? studentId;
  final String? studentCode;
  final String? classroom;
  final String? profileImage;

  const AssignCardPage({
    Key? key,
    this.studentName,
    this.studentId,
    this.studentCode,
    this.classroom,
    this.profileImage,
  }) : super(key: key);

  @override
  _AssignCardPageState createState() => _AssignCardPageState();
}

class _AssignCardPageState extends State<AssignCardPage> {
  bool isReading = false;
  String? nfcId;
  late AssignStudentCardBloc studentBloc;
  bool isNfcAvailable = false;

  @override
  void initState() {
    super.initState();
    studentBloc = BlocProvider.of<AssignStudentCardBloc>(context);
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    try {
      isNfcAvailable = await NfcManager.instance.isAvailable();
    } catch (e) {
      debugPrint('NFC Availability Error: $e');
      isNfcAvailable = false;
    }
    setState(() {});
  }

  Future<void> _startNfcSession() async {
    if (!isNfcAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC is not available on this device')),
      );
      return;
    }

    setState(() => isReading = true);

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          final tagId = tag.data['nfca']?['identifier'] ??
              tag.data['isodep']?['identifier'] ??
              tag.data['mifareclassic']?['identifier'] ??
              tag.data['mifareultralight']?['identifier'];

          if (tagId != null) {
            final nfcIdHex =
                tagId.map((e) => e.toRadixString(16).padLeft(2, '0')).join('');
            debugPrint('NFC ID: $nfcIdHex');

            studentBloc.add(HandleAssignStudentCardEvent(
              studentCode: widget.studentCode ?? '',
              cardId: nfcIdHex,
            ));

            setState(() {
              nfcId = nfcIdHex;
              isReading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Card detected: $nfcIdHex')),
            );

            await Future.delayed(const Duration(seconds: 1));
            await NfcManager.instance.stopSession();
          } else {
            throw Exception('Could not read card ID');
          }
        },
      );
    } catch (e) {
      debugPrint('NFC Error: $e');
      setState(() => isReading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reading NFC: $e')),
      );
    }
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

   Future<bool> _onWillPop() async {
    Navigator.of(context).pop();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Assign Card',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.blue,
        ),
        body: BlocListener<AssignStudentCardBloc, AssignStudentCardState>(
          listener: (context, state) {
            if (state is AssignStudentCardSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Card assigned successfully!')),
              );
              Future.delayed(const Duration(seconds: 2), () {
                context.safeGoNamed(assignCard, params: {
                  'classroom': widget.classroom.toString(),
                  'classroomId': widget.studentId.toString(),
                });
              });
            } else if (state is AssignStudentCardError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${state.message}')),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isNfcAvailable)
                  const Text(
                    'NFC is not available on this device',
                    style: TextStyle(color: Colors.red),
                  )
                else ...[
                  // CircleAvatar(
                  //   radius: 100,
                  //   backgroundColor: primaryColor.withOpacity(0.1),
                  //   backgroundImage: widget.profileImage != null
                  //       ? NetworkImage(widget.profileImage!)
                  //       : null,
                  //   child: widget.profileImage == null
                  //       ? const Icon(Icons.person, color: primaryColor, size: 80)
                  //       : null,
                  // ),
                  const SizedBox(height: 10),
                  Text(
                    widget.studentName ?? 'Unknown Student',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Text(
                      'Place the NFC card on the device to assign',
                      style: GoogleFonts.poppins(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  BlocBuilder<AssignStudentCardBloc, AssignStudentCardState>(
                    builder: (context, state) {
                      if (state is AssignStudentCardLoading || isReading) {
                        return const Column(
                          children: [
                            // CircularProgressIndicator(
                            //   valueColor:
                            //       AlwaysStoppedAnimation<Color>(Colors.blue),
                            //   strokeWidth: 4.0,
                            // ),
                          SizedBox(
                              height: 100,
                              width: 100,
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.blue),
                                strokeWidth: 8.0,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text('Reading NFC card...'),
                          ],
                        );
                      } else if (state is AssignStudentCardSuccess) {
                        return const Column(
                          children: [
                            Icon(Icons.check_circle,
                                size: 100, color: Colors.green),
                            SizedBox(height: 16),
                            Text('Card assigned successfully!'),
                          ],
                        );
                      } else {
                        return ElevatedButton(
                          onPressed: _startNfcSession,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                          child: const Text('Start Reading Card'),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

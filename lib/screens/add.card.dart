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
  String? lastTagInfo;
  late AssignStudentCardBloc studentBloc;
  bool isNfcAvailable = false;

  @override
  void initState() {
    super.initState();
    studentBloc = BlocProvider.of<AssignStudentCardBloc>(context);
    checkNfcAvailability();
  }

  Future<void> checkNfcAvailability() async {
    try {
      isNfcAvailable = await NfcManager.instance.isAvailable();
      setState(() {});
    } catch (e) {
      debugPrint('NFC Availability Error: $e');
      setState(() {
        isNfcAvailable = false;
      });
    }
  }

  String _formatTagData(Map<String, dynamic> data) {
    return data.entries
        .map((e) =>
            '${e.key}: ${e.value is List ? _formatBytes(e.value) : e.value}')
        .join('\n');
  }

  String _formatBytes(List<int> bytes) {
    return bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
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
      nfcId = null;
      lastTagInfo = null;
    });

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            // Store complete tag information for debugging
            final Map<String, dynamic> tagData = tag.data;
            setState(() {
              lastTagInfo = _formatTagData(tagData);
            });
            debugPrint('Found NFC tag: $lastTagInfo');

            // Get the ID from the NFC tag
            final tagId = tag.data['nfca']?['identifier'] ??
                tag.data['isodep']?['identifier'] ??
                tag.data['mifareclassic']?['identifier'] ??
                tag.data['mifareultralight']?['identifier'];

            if (tagId != null) {
              // Convert bytes to hex string without colons
              final nfcIdHex = tagId
                  .map((e) => e.toRadixString(16).padLeft(2, '0'))
                  .join('');
              debugPrint('NFC ID: $nfcIdHex');
              // Dispatch event to BLoC
              studentBloc.add(HandleAssignStudentCardEvent(
                studentCode: widget.studentCode ?? '',
                cardId: nfcIdHex,
              ));

              setState(() {
                nfcId = nfcIdHex;
                isReading = false;
              });

              // Vibrate and show success message
              // await HapticFeedback.vibrate();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Card detected: $nfcIdHex')),
              );

              await NfcManager.instance.stopSession();
            } else {
              throw Exception('Could not read card ID');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reading NFC: $e')),
      );
    }
  }

  @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text(
  //         'Assign Card',
  //         style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
  //       ),
  //       backgroundColor: Colors.blue,
  //     ),
  //     body: BlocListener<AssignStudentCardBloc, AssignStudentCardState>(
  //       listener: (context, state) {
  //         if (state is AssignStudentCardSuccess) {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(content: Text('Card assigned successfully!')),
  //           );
  //           Future.delayed(const Duration(seconds: 2), () {
  //             context.safeGoNamed(assignCard, params: {
  //               'classroom': widget.classroom.toString(),
  //               'classroomId': widget.studentId.toString(),
  //             });
  //           });
  //         } else if (state is AssignStudentCardError) {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             SnackBar(content: Text('Error: ${state.message}')),
  //           );
  //         }
  //       },
  //       child: SingleChildScrollView(
  //         padding: const EdgeInsets.all(16.0),
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             if (!isNfcAvailable)
  //               const Card(
  //                 color: Colors.red,
  //                 child: Padding(
  //                   padding: EdgeInsets.all(16.0),
  //                   child: Text(
  //                     'NFC is not available on this device',
  //                     style: TextStyle(color: Colors.white),
  //                   ),
  //                 ),
  //               )
  //             else ...[
  //               Card(
  //                 child: Padding(
  //                   padding: const EdgeInsets.all(16.0),
  //                   child: Column(
  //                     children: [
  //                       Text(
  //                         'Assign Card to Student:',
  //                         style: GoogleFonts.poppins(fontSize: 18),
  //                         textAlign: TextAlign.center,
  //                       ),
  //                       const SizedBox(height: 8),
  //                       Text(
  //                         widget.studentName.toString(),
  //                         style: GoogleFonts.poppins(
  //                           fontSize: 22,
  //                           fontWeight: FontWeight.bold,
  //                           color: Colors.blue,
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //               const SizedBox(height: 24),
  //               BlocBuilder<AssignStudentCardBloc, AssignStudentCardState>(
  //                 builder: (context, state) {
  //                   if (state is AssignStudentCardLoading || isReading) {
  //                     return const Column(
  //                       children: [
  //                         CircularProgressIndicator(),
  //                         SizedBox(height: 16),
  //                         Text('Reading NFC card...'),
  //                       ],
  //                     );
  //                   } else if (state is AssignStudentCardSuccess) {
  //                     return const Column(
  //                       children: [
  //                         Icon(Icons.check_circle,
  //                             size: 100, color: Colors.green),
  //                         SizedBox(height: 16),
  //                         Text('Card assigned successfully!'),
  //                       ],
  //                     );
  //                   } else {
  //                     return Column(
  //                       children: [
  //                         ElevatedButton.icon(
  //                           onPressed: startNfcSession,
  //                           icon: const Icon(Icons.nfc),
  //                           label: const Text('Start Reading Card'),
  //                           style: ElevatedButton.styleFrom(
  //                             padding: const EdgeInsets.symmetric(
  //                               horizontal: 32,
  //                               vertical: 16,
  //                             ),
  //                           ),
  //                         ),
  //                         if (lastTagInfo != null) ...[
  //                           const SizedBox(height: 24),
  //                           Card(
  //                             child: Padding(
  //                               padding: const EdgeInsets.all(16.0),
  //                               child: Column(
  //                                 crossAxisAlignment: CrossAxisAlignment.start,
  //                                 children: [
  //                                   Text(
  //                                     'Last Read Tag Info:',
  //                                     style: GoogleFonts.poppins(
  //                                       fontWeight: FontWeight.bold,
  //                                     ),
  //                                   ),
  //                                   const SizedBox(height: 8),
  //                                   Text(lastTagInfo!),
  //                                 ],
  //                               ),
  //                             ),
  //                           ),
  //                         ],
  //                       ],
  //                     );
  //                   }
  //                 },
  //               ),
  //             ],
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget build(BuildContext context) {
    return Scaffold(
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
                CircleAvatar(
                  radius: 60,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  backgroundImage: widget.profileImage != null
                      ? NetworkImage(widget.profileImage.toString())
                      : null, // Placeholder if no image is available
                  child: widget.profileImage == null
                      ? const Icon(Icons.person, color: primaryColor)
                      : null,
                ),
                Text(
                  'Place the NFC card on the device to assign to:',
                  style: GoogleFonts.poppins(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.studentName.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 24),
                BlocBuilder<AssignStudentCardBloc, AssignStudentCardState>(
                  builder: (context, state) {
                    if (state is AssignStudentCardLoading || isReading) {
                      return const Column(
                        children: [
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
                        onPressed: startNfcSession,
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
    );
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }
}

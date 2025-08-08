import 'package:attendance/controllers/assign_student_card_controller.dart';
import 'package:attendance/routes/routes.names.dart';
import 'package:attendance/routes/routes.provider.dart';
import 'package:attendance/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nfc_manager/nfc_manager.dart';

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
  // Create a controller instance using GetX
  final AssignStudentCardController _cardController = Get.put(AssignStudentCardController());
  
  RxBool isReading = false.obs;
  RxString? nfcId = RxString('');
  RxBool isNfcAvailable = false.obs;

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    try {
      isNfcAvailable.value = await NfcManager.instance.isAvailable();
    } catch (e) {
      debugPrint('NFC Availability Error: $e');
      isNfcAvailable.value = false;
    }
  }

  Future<void> _startNfcSession() async {
    if (!isNfcAvailable.value) {
      Get.snackbar(
        'NFC Not Available', 
        'NFC is not available on this device',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white
      );
      return;
    }

    isReading.value = true;

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

            // Call the GetX controller instead of BLoC
            await _cardController.assignCardToStudent(widget.studentId ?? '', nfcIdHex);

            nfcId?.value = nfcIdHex;
            isReading.value = false;

            // Get.snackbar(
            //   'Card Detected', 
            //   'Card detected: $nfcIdHex',
            //   snackPosition: SnackPosition.BOTTOM,
            //   backgroundColor: Colors.green.withOpacity(0.7),
            //   colorText: Colors.white
            // );

            await Future.delayed(const Duration(seconds: 1));
            await NfcManager.instance.stopSession();
          } else {
            throw Exception('Could not read card ID');
          }
        },
      );
    } catch (e) {
      debugPrint('NFC Error: $e');
      isReading.value = false;
      Get.snackbar(
        'Error', 
        'Error reading NFC: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white
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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Using Obx for reactive UI updates
                Obx(() => isNfcAvailable.value
                  ? Column(
                      children: [
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
                        
                        // Using GetX for state management
                        Obx(() {
                          // Success state
                          if (_cardController.isSuccess.value) {
                            // Handle navigation after success
                            Future.delayed(const Duration(seconds: 2), () {
                            Get.toNamed(assignCard, parameters: {
                                'classroom': widget.classroom.toString(),
                                'classroomId': widget.studentId.toString(),
                              });
                            });
                            
                            return const Column(

                              children: [
                                Icon(Icons.check_circle,
                                    size: 100, color: Colors.green),
                                SizedBox(height: 16),
                                Text('Card assigned successfully!'),
                              ],
                            );
                          }
                          // Loading state
                          else if (_cardController.isLoading.value || isReading.value) {
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
                          }
                          // Error state
                          else if (_cardController.errorMessage.value.isNotEmpty) {
                            return Column(
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 100, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(
                                  'Error: ${_cardController.errorMessage.value}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.red),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _startNfcSession,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text('Try Again'),
                                ),
                              ],
                            );
                          }
                          // Initial state
                          else {
                            return ElevatedButton(
                              onPressed: _startNfcSession,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                backgroundColor: Colors.blue,
                              ),
                              child: const Text('Start Reading Card'),
                            );
                          }
                        }),
                      ],
                    )
                  : const Text(
                      'NFC is not available on this device',
                      style: TextStyle(color: Colors.red),
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

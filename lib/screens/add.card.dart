import 'package:attendance/controllers/assign_student_card_controller.dart';
import 'package:attendance/routes/routes.names.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../utils/colors.dart';

class AssignCardPage extends StatefulWidget {
  final String? studentName;
  final String? studentId;
  final String? studentCode;
  final String? classroom;
  final String? profileImage;
  final String? existingCardId; // Add this to check if card already exists

  const AssignCardPage({
    Key? key,
    this.studentName,
    this.studentId,
    this.studentCode,
    this.classroom,
    this.profileImage,
    this.existingCardId,
  }) : super(key: key);

  @override
  _AssignCardPageState createState() => _AssignCardPageState();
}

class _AssignCardPageState extends State<AssignCardPage> {
  final AssignStudentCardController _cardController = Get.put(AssignStudentCardController());
  
  RxBool isReading = false.obs;
  RxString? nfcId = RxString('');
  RxBool isNfcAvailable = false.obs;

  @override
  void initState() {
    super.initState();
    // CRITICAL: Reset controller state when page loads
    _cardController.reset();
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
    _cardController.reset(); // Reset before starting new session

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

            await _cardController.assignCardToStudent(widget.studentId ?? '', nfcIdHex);
            nfcId?.value = nfcIdHex;
            isReading.value = false;

            await Future.delayed(const Duration(milliseconds: 500));
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

  Future<void> _removeCard() async {
    // Show confirmation dialog
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(
          'Remove Card',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to remove the card from ${widget.studentName}?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Remove', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Call API to remove card (assign empty string or null)
      await _cardController.assignCardToStudent(widget.studentId ?? '', '');
    }
  }

  void _goBackToClassroom() {
    // Defer reset and navigation to avoid build phase conflicts
    Future.microtask(() {
      _cardController.reset(); // Reset before navigation
      Get.toNamed(
        assignCard,
        parameters: {
          'classroom': widget.classroom.toString(),
          'classroomId': widget.studentId.toString(),
        },
      );
    });
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    _cardController.reset(); // Reset when user presses back
    Navigator.of(context).pop();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(
            'Assign Card',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          backgroundColor: primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // Defer reset to avoid build phase conflicts
              Future.microtask(() {
                _cardController.reset();
                Navigator.of(context).pop();
              });
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Student Info Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue[100],
                          backgroundImage: widget.profileImage != null
                              ? NetworkImage(widget.profileImage!)
                              : null,
                          child: widget.profileImage == null
                              ? Icon(Icons.person, size: 50, color: Colors.blue[700])
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.studentName ?? 'Unknown Student',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'ID: ${widget.studentCode ?? 'N/A'}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (widget.classroom != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.classroom!,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // NFC Card Assignment Section
                  Obx(() => isNfcAvailable.value
                      ? _buildNfcSection()
                      : _buildNfcUnavailable()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNfcSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Obx(() {
        // Success State
        if (_cardController.isSuccess.value) {
          return _buildSuccessState();
        }
        // Loading State
        else if (_cardController.isLoading.value || isReading.value) {
          return _buildLoadingState();
        }
        // Error State
        else if (_cardController.errorMessage.value.isNotEmpty) {
          return _buildErrorState();
        }
        // Initial State
        else {
          return _buildInitialState();
        }
      }),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green[50],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green[600],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Card Assigned Successfully!',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.green[700],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        if (nfcId?.value.isNotEmpty == true)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Card ID: ${nfcId?.value}',
              style: GoogleFonts.robotoMono(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Defer reset to avoid build phase conflicts
                  Future.microtask(() {
                    _cardController.reset();
                    isReading.value = false;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: Text(
                  'Assign Another',
                  style: GoogleFonts.poppins(),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.blue[700]!),
                  foregroundColor: Colors.blue[700],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _goBackToClassroom,
                icon: const Icon(Icons.done),
                label: Text(
                  'Done',
                  style: GoogleFonts.poppins(),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        SizedBox(
          height: 100,
          width: 100,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
            strokeWidth: 6.0,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Reading NFC Card...',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please hold the card near your device',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[500],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red[50],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[600],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Assignment Failed',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.red[700],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _cardController.errorMessage.value,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.red[700],
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              _cardController.reset();
              _startNfcSession();
            },
            icon: const Icon(Icons.refresh),
            label: Text(
              'Try Again',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialState() {
    final hasExistingCard = widget.existingCardId?.isNotEmpty == true;

    return Column(
      children: [
        Icon(
          Icons.nfc,
          size: 80,
          color: Colors.blue[300],
        ),
        const SizedBox(height: 20),
        Text(
          hasExistingCard ? 'Card Already Assigned' : 'Ready to Assign Card',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        if (hasExistingCard)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Current Card: ${widget.existingCardId}',
                  style: GoogleFonts.robotoMono(
                    fontSize: 12,
                    color: Colors.amber[900],
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            hasExistingCard
                ? 'You can re-assign a new card or remove the existing one'
                : 'Tap the button below and place the NFC card near your device',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _startNfcSession,
            icon: const Icon(Icons.nfc),
            label: Text(
              hasExistingCard ? 'Re-assign Card' : 'Start Reading Card',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (hasExistingCard) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _removeCard,
              icon: const Icon(Icons.delete_outline),
              label: Text(
                'Remove Card',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.red[700],
                side: BorderSide(color: Colors.red[700]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNfcUnavailable() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.smartphone_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'NFC Not Available',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'NFC is not available on this device. Please use a device with NFC support.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
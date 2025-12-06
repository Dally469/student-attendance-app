import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../controllers/attendance_controller.dart';
import '../models/classroom.model.dart';
import '../utils/colors.dart';

class AttendanceConfigBottomSheet extends StatefulWidget {
  final Classrooms classroom;
  final Function(String attendanceId) onAttendanceReady;

  const AttendanceConfigBottomSheet({
    Key? key,
    required this.classroom,
    required this.onAttendanceReady,
  }) : super(key: key);

  @override
  State<AttendanceConfigBottomSheet> createState() =>
      _AttendanceConfigBottomSheetState();
}

class _AttendanceConfigBottomSheetState
    extends State<AttendanceConfigBottomSheet> {
  final AttendanceController _attendanceController =
      Get.find<AttendanceController>();

  String _selectedMode = 'CHECK_IN_ONLY';
  String _selectedDeviceType = 'FACE';
  bool _isCheckingExisting = true;
  bool _hasExistingAttendance = false;

  @override
  void initState() {
    super.initState();
    _checkExistingAttendance();
  }

  Future<void> _checkExistingAttendance() async {
    setState(() => _isCheckingExisting = true);

    final existingAttendance = await _attendanceController.checkTodayAttendance(
      widget.classroom.id ?? '',
    );

    // Check if there are multiple attendances
    // If there are multiple attendances with different modes, we'll handle it in make.attendance screen
    // For now, just set the existing attendance
    setState(() {
      _isCheckingExisting = false;
      _hasExistingAttendance = existingAttendance != null;
    });
  }

  void _handleExistingAttendance() {
    final attendance = _attendanceController.existingAttendance.value;
    if (attendance?.data?.id != null) {
      Navigator.pop(context);
      widget.onAttendanceReady(attendance!.data!.id!);
    }
  }

  void _showWarningDialog(String message) async {
    // Get existing attendance ID if available
    String? existingAttendanceId;

    // First check if existingAttendance is already set
    final existingAttendance = _attendanceController.existingAttendance.value;
    if (existingAttendance?.data?.id != null) {
      existingAttendanceId = existingAttendance!.data!.id!;
    } else {
      // If not available, fetch it
      final attendance = await _attendanceController.checkTodayAttendance(
        widget.classroom.id ?? '',
      );
      if (attendance?.data?.id != null) {
        existingAttendanceId = attendance!.data!.id!;
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Warning',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog only
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close bottom sheet

                // Navigate to scanning page if attendance ID is available
                if (existingAttendanceId != null &&
                    existingAttendanceId.isNotEmpty) {
                  widget.onAttendanceReady(existingAttendanceId);
                }
              },
              child: Text(
                'Record attendance',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createNewAttendance() async {
    await _attendanceController.createAttendance(
      widget.classroom.id ?? '',
      mode: _selectedMode,
      deviceType: _selectedDeviceType,
    );

    // Check for errors first
    if (_attendanceController.errorMessage.value.trim().isNotEmpty) {
      // Show warning dialog instead of SnackBar
      // If attendance already exists, we'll navigate to it when OK is clicked
      if (mounted) {
        _showWarningDialog(_attendanceController.errorMessage.value);
      }
      return;
    }

    // Check if attendance was actually created by checking currentAttendance directly
    // This is more reliable than checking successMessage which might be empty
    final currentAttendance = _attendanceController.currentAttendance.value;
    if (currentAttendance?.data?.id != null &&
        currentAttendance!.data!.id!.isNotEmpty) {
      Navigator.pop(context);
      widget.onAttendanceReady(currentAttendance.data!.id!);
    } else {
      // Fallback to getAttendanceId method
      final attendanceId = _attendanceController.getAttendanceId();
      if (attendanceId.isNotEmpty) {
        Navigator.pop(context);
        widget.onAttendanceReady(attendanceId);
      } else {
        // Show error if no attendance ID was found
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create attendance. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
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
            children: [
              // Drag handle
              _buildDragHandle(context),

              // Header
              _buildHeader(context),

              // Content
              Expanded(
                child: _isCheckingExisting
                    ? _buildLoadingState()
                    : _hasExistingAttendance
                        ? _buildExistingAttendanceView()
                        : _buildConfigurationForm(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
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
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.checklist_rounded,
              color: primaryColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance Setup',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  widget.classroom.name ?? 'Unknown Classroom',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SpinKitDoubleBounce(color: primaryColor, size: 50),
          const SizedBox(height: 20),
          Text(
            'Checking for existing attendance...',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingAttendanceView() {
    final attendance = _attendanceController.existingAttendance.value;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 40,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Attendance Already Created',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'An attendance session already exists for today.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Attendance details card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.event,
                  'Date',
                  attendance?.data?.attendanceDate ?? 'Today',
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  Icons.check_circle_outline,
                  'Mode',
                  attendance?.data?.mode == 'CHECK_IN_ONLY'
                      ? 'Check-in Only'
                      : 'Check-in and Check-out',
                ),
                const Divider(height: 16),
                _buildInfoRow(
                  Icons.devices,
                  'Device Type',
                  attendance?.data?.deviceType ?? 'FACE',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.outline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _handleExistingAttendance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Continue to Attendance',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationForm(ScrollController scrollController) {
    return Obx(() {
      final isCreating = _attendanceController.isCreatingAttendance.value;

      return SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No attendance session found for today. Configure and create a new one.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // Device Type Selection
            _buildSectionTitle('Device Type'),
            const SizedBox(height: 12),
            _buildDeviceTypeSelector(),
            const SizedBox(height: 24),

            // Mode Selection
            _buildSectionTitle('Attendance Mode'),
            const SizedBox(height: 12),
            _buildModeSelector(),
            const SizedBox(height: 32),

            // Create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCreating ? null : _createNewAttendance,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  disabledBackgroundColor: primaryColor.withOpacity(0.5),
                ),
                child: isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Create Attendance',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildDeviceTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildDeviceTypeOption(
            'FACE',
            'Face Recognition',
            Icons.face,
            primaryColor,
            'Use facial recognition for attendance',
          ),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          _buildDeviceTypeOption(
            'NFC',
            'Student Card',
            Icons.credit_card,
            orangeColor,
            'Use NFC cards for attendance',
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTypeOption(
    String value,
    String title,
    IconData icon,
    Color color,
    String description,
  ) {
    final isSelected = _selectedDeviceType == value;

    return InkWell(
      onTap: () => setState(() => _selectedDeviceType = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
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
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedDeviceType,
              activeColor: primaryColor,
              onChanged: (val) => setState(() => _selectedDeviceType = val!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildModeOption(
            'CHECK_IN_ONLY',
            'Check In Only',
            'Students can only check in',
            Icons.login,
          ),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          _buildModeOption(
            'CHECK_IN_OUT',
            'Check In / Check Out',
            'Students can check in and check out',
            Icons.logout,
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(
    String value,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedMode == value;

    return InkWell(
      onTap: () => setState(() => _selectedMode = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryColor : Colors.grey,
                size: 24,
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
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedMode,
              activeColor: primaryColor,
              onChanged: (val) => setState(() => _selectedMode = val!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: primaryColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

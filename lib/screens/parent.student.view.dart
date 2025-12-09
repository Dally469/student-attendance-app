import 'dart:async';
import 'dart:convert';
import 'package:attendance/models/parent.lookup.model.dart';
import 'package:attendance/models/student.model.dart';
import 'package:attendance/utils/colors.dart';
import 'package:attendance/utils/notifiers.dart';
import 'package:attendance/api/auth.service.dart';
import 'package:attendance/screens/view.student.attendance.screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ParentStudentView extends StatelessWidget {
  final List<StudentWithFees> studentsWithFees;
  final String query;
  final String? token;
  final String? expiresIn;

  const ParentStudentView({
    Key? key,
    required this.studentsWithFees,
    required this.query,
    this.token,
    this.expiresIn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: whiteColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          studentsWithFees.length == 1
              ? 'Student Information'
              : 'Students Information',
          style: GoogleFonts.poppins(
            color: whiteColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: studentsWithFees.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: greyColor1,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No students found',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: blackColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check the registration number or phone number',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: greyColor1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: studentsWithFees.length,
              cacheExtent: 500, // Cache more items for smoother scrolling
              itemBuilder: (context, index) {
                final studentWithFees = studentsWithFees[index];
                return _buildStudentCard(studentWithFees, context, index);
              },
            ),
    );
  }

  Widget _buildStudentCard(
      StudentWithFees studentWithFees, BuildContext context, int index) {
    final student = studentWithFees.student;

    if (student == null) return const SizedBox.shrink();

    // Use a key to help Flutter identify widgets during scrolling
    return _StudentCardWidget(
      key: ValueKey('student_${student.id}_$index'),
      studentWithFees: studentWithFees,
      query: query,
    );
  }
}

// Separate StatefulWidget for better memory management
class _StudentCardWidget extends StatelessWidget {
  final StudentWithFees studentWithFees;
  final String query;

  const _StudentCardWidget({
    Key? key,
    required this.studentWithFees,
    required this.query,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final student = studentWithFees.student;

    if (student == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Student Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: whiteColor,
                    border: Border.all(color: whiteColor, width: 2),
                  ),
                  child: student.profileImage != null &&
                          student.profileImage!.isNotEmpty &&
                          student.profileImage != 'null'
                      ? ClipOval(
                          child: Image.network(
                            student.profileImage!,
                            fit: BoxFit.cover,
                            width: 60,
                            height: 60,
                            cacheWidth: 120, // Cache at 2x for retina displays
                            cacheHeight: 120,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        primaryColor),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 30,
                                color: primaryColor,
                              );
                            },
                            frameBuilder: (context, child, frame,
                                wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded) return child;
                              return AnimatedOpacity(
                                opacity: frame == null ? 0 : 1,
                                duration: const Duration(milliseconds: 200),
                                child: child,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: primaryColor,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name ?? 'Unknown Student',
                        style: GoogleFonts.poppins(
                          color: whiteColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reg: ${student.code ?? 'N/A'}',
                        style: GoogleFonts.poppins(
                          color: whiteColor.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Student Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StudentCardWidget._buildInfoRow(
                  icon: Icons.school_outlined,
                  label: 'School',
                  value: student.school ?? 'N/A',
                ),
                const SizedBox(height: 12),
                _StudentCardWidget._buildInfoRow(
                  icon: Icons.class_outlined,
                  label: 'Classroom',
                  value: student.classroom ?? 'N/A',
                ),
                const SizedBox(height: 12),
                _StudentCardWidget._buildInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Parent Contact',
                  value: student.parentContact ?? 'N/A',
                ),
                const SizedBox(height: 12),
                _StudentCardWidget._buildInfoRow(
                  icon: Icons.person_outline,
                  label: 'Gender',
                  value: student.gender ?? 'N/A',
                ),
                if (student.level != null) ...[
                  const SizedBox(height: 12),
                  _StudentCardWidget._buildInfoRow(
                    icon: Icons.stairs_outlined,
                    label: 'Level',
                    value: student.level ?? 'N/A',
                  ),
                ],
                // View Fees Button (always visible - fees are fetched on the details page)
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ParentFeeDetailsScreen(
                              studentWithFees: studentWithFees,
                              query: query,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              color: whiteColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'View Fee Details',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: whiteColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: whiteColor,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  fontWeight: FontWeight.w400,
                  color: greyColor1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: blackColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Fee Details Screen
class ParentFeeDetailsScreen extends StatefulWidget {
  final StudentWithFees studentWithFees;
  final String? query;
  final VoidCallback? onRefresh;

  const ParentFeeDetailsScreen({
    Key? key,
    required this.studentWithFees,
    this.query,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<ParentFeeDetailsScreen> createState() => _ParentFeeDetailsScreenState();
}

class _ParentFeeDetailsScreenState extends State<ParentFeeDetailsScreen> {
  late StudentWithFees _currentStudentWithFees;
  bool _isRefreshing = false;
  bool _isLoading = false;
  bool _showProcessingModal = false;
  int _processingSeconds = 0;
  static const double _transactionFee = 300.0;

  @override
  void initState() {
    super.initState();
    _currentStudentWithFees = widget.studentWithFees;

    // Debug: Log initial student data
    debugPrint('=== Initial Student Data ===');
    debugPrint('Student ID: ${widget.studentWithFees.student?.id}');
    debugPrint('Student Name: ${widget.studentWithFees.student?.name}');
    debugPrint(
        'Account MoMo Phone: ${widget.studentWithFees.student?.accountMomoPhone}');
    debugPrint('School Phone: ${widget.studentWithFees.student?.schoolPhone}');
    debugPrint(
        'Parent Contact: ${widget.studentWithFees.student?.parentContact}');
    debugPrint('============================');

    // Fetch fees when screen loads
    _fetchFeesByStudentId();
  }

  Future<void> _fetchFeesByStudentId() async {
    final studentId = widget.studentWithFees.student?.id;
    if (studentId == null || studentId.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final AuthService authService = AuthService();
      final result = await authService.fetchStudentFeesByStudentId(studentId);

      if (result['success'] == true && result['data'] != null) {
        final List<dynamic> feesData = result['data'] as List<dynamic>;
        final List<StudentFee> fees = feesData
            .map((feeJson) =>
                StudentFee.fromJson(feeJson as Map<String, dynamic>))
            .toList();

        // Calculate fee summary
        double totalDue = 0.0;
        double totalPaid = 0.0;
        double totalOutstanding = 0.0;

        for (var fee in fees) {
          totalDue += fee.amountDue ?? 0.0;
          totalPaid += fee.amountPaid ?? 0.0;
          totalOutstanding += fee.amountOutstanding ?? 0.0;
        }

        final feeSummary = FeeSummary(
          totalDue: totalDue,
          totalPaid: totalPaid,
          totalOutstanding: totalOutstanding,
          allFees: fees,
        );

        // Update the student with fees, preserving the original student data
        // Use _currentStudentWithFees.student if available, otherwise use widget.studentWithFees.student
        final currentStudent =
            _currentStudentWithFees.student ?? widget.studentWithFees.student;

        debugPrint('=== Updating Student With Fees ===');
        debugPrint('Student ID: ${currentStudent?.id}');
        debugPrint('Student Name: ${currentStudent?.name}');
        debugPrint('Account MoMo Phone: ${currentStudent?.accountMomoPhone}');
        debugPrint('School Phone: ${currentStudent?.schoolPhone}');
        debugPrint('Parent Contact: ${currentStudent?.parentContact}');
        debugPrint('==================================');

        setState(() {
          _currentStudentWithFees = StudentWithFees(
            student: currentStudent,
            unpaidFees: fees.where((f) => f.status == 'UNPAID').toList(),
            feeSummary: feeSummary,
            hasUnpaidFees: totalOutstanding > 0,
          );
        });
      } else {
        showErrorAlert(
          result['message'] ?? 'Failed to fetch fee information',
          context,
        );
      }
    } catch (e) {
      showErrorAlert('Error fetching fees: $e', context);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshFees() async {
    setState(() {
      _isRefreshing = true;
      _showProcessingModal = true;
      _processingSeconds = 0;
    });

    // Start timer for processing modal
    Timer? timer;
    if (mounted) {
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted && _showProcessingModal) {
          setState(() {
            _processingSeconds = t.tick;
          });
        } else {
          t.cancel();
        }
      });
    }

    try {
      final studentId = widget.studentWithFees.student?.id;
      if (studentId == null || studentId.isEmpty) {
        await _fetchFeesByStudentId();
        return;
      }

      final AuthService authService = AuthService();

      // Get pending transaction IDs from SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? pendingTransactionsJson =
          prefs.getString('pendingTransactions_$studentId');

      bool hasFailedPayment = false;
      List<String> failedTransactions = [];

      if (pendingTransactionsJson != null &&
          pendingTransactionsJson.isNotEmpty) {
        final List<dynamic> pendingTransactions =
            jsonDecode(pendingTransactionsJson) as List<dynamic>;
        final List<String> transactionsToRemove = [];

        // First check payment status, then update fee if SUCCESS
        for (var transactionId in pendingTransactions) {
          final String txId = transactionId.toString();

          debugPrint('=== Checking payment status for transaction: $txId ===');

          // Step 1: Check payment status with GET /api/mopay/status/{transactionId}
          final statusResult = await authService.checkPaymentStatus(txId);

          if (statusResult['success'] == true) {
            final statusData = statusResult['data'] as Map<String, dynamic>?;
            final status = statusData?['status'] as String?;

            debugPrint('Payment status for $txId: $status');

            if (status == 'SUCCESS') {
              // Step 2: If SUCCESS, call updateFee
              debugPrint(
                  'Payment successful, calling updateFee for transaction: $txId');
              final updateResult = await authService.updateFee(txId);

              if (updateResult['success'] == true) {
                transactionsToRemove.add(txId);
                debugPrint('✅ Fee updated successfully for transaction: $txId');
              } else {
                debugPrint(
                    '❌ Failed to update fee for transaction: $txId - ${updateResult['message']}');
              }
            } else if (status == 'FAILED') {
              // Payment failed - track for error message
              hasFailedPayment = true;
              failedTransactions.add(txId);
              transactionsToRemove.add(txId);
              debugPrint('❌ Payment failed for transaction: $txId');
            } else {
              // Payment still pending or other status
              debugPrint(
                  '⏳ Payment status is $status for transaction: $txId - keeping in pending list');
            }
          } else {
            debugPrint(
                '❌ Failed to check payment status for transaction: $txId');
          }
        }

        // Remove processed transactions
        if (transactionsToRemove.isNotEmpty) {
          final updatedTransactions = pendingTransactions
              .where((tx) => !transactionsToRemove.contains(tx.toString()))
              .toList();

          if (updatedTransactions.isEmpty) {
            await prefs.remove('pendingTransactions_$studentId');
          } else {
            await prefs.setString('pendingTransactions_$studentId',
                jsonEncode(updatedTransactions));
          }
        }
      }

      // Fetch fees after updating payments
      await _fetchFeesByStudentId();

      // Close processing modal first
      if (mounted) {
        setState(() {
          _showProcessingModal = false;
        });
      }

      // Cancel timer
      timer?.cancel();

      // Show messages after all processing is complete
      if (mounted) {
        if (hasFailedPayment) {
          showErrorAlert(
            'Payment failed. Please try again.',
            context,
          );
        } else {
          showSuccessAlert('Fee information updated', context);
        }
      }
    } catch (e) {
      debugPrint('Error refreshing fees: $e');

      // Close processing modal
      if (mounted) {
        setState(() {
          _showProcessingModal = false;
        });
      }

      // Cancel timer
      timer?.cancel();

      // Show error after modal is closed
      if (mounted) {
        showErrorAlert('Error refreshing fees: $e', context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = _currentStudentWithFees.student;
    final feeSummary = _currentStudentWithFees.feeSummary;
    final allFees = feeSummary?.allFees ?? [];

    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: whiteColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Fee Details - ${student?.name ?? 'Student'}',
          style: GoogleFonts.poppins(
            color: whiteColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note, color: whiteColor),
            onPressed: () {
              final studentCode = student?.code;
              final studentName = student?.name ?? 'Student';
              if (studentCode != null && studentCode.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewStudentAttendanceScreen(
                      studentCode: studentCode,
                      studentName: studentName,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Student code not available',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            tooltip: 'View Attendance',
          ),
          TextButton.icon(
            onPressed: _isRefreshing ? null : _refreshFees,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.check_circle, color: whiteColor, size: 20),
            label: Text(
              _isRefreshing ? 'Confirming...' : 'Confirm',
              style: GoogleFonts.poppins(
                color: whiteColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : feeSummary == null
              ? Center(
                  child: Text(
                    'No fee information available',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: greyColor1,
                    ),
                  ),
                )
              : Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Fee Summary Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor,
                                  primaryColor.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fee Summary',
                                  style: GoogleFonts.poppins(
                                    color: whiteColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildSummaryItem('Total Due',
                                        feeSummary.totalDue ?? 0.0, whiteColor),
                                    _buildSummaryItem(
                                        'Total Paid',
                                        feeSummary.totalPaid ?? 0.0,
                                        whiteColor),
                                    _buildSummaryItem(
                                        'Outstanding',
                                        feeSummary.totalOutstanding ?? 0.0,
                                        whiteColor),
                                  ],
                                ),
                                if (feeSummary.academicYear != null ||
                                    feeSummary.term != null) ...[
                                  const SizedBox(height: 12),
                                  Divider(color: whiteColor.withOpacity(0.3)),
                                  const SizedBox(height: 8),
                                  if (feeSummary.academicYear != null)
                                    Text(
                                      'Academic Year: ${feeSummary.academicYear}',
                                      style: GoogleFonts.poppins(
                                        color: whiteColor.withOpacity(0.9),
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (feeSummary.term != null)
                                    Text(
                                      'Term: ${feeSummary.term}',
                                      style: GoogleFonts.poppins(
                                        color: whiteColor.withOpacity(0.9),
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // View Attendance Button
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue,
                                  Colors.blue.withOpacity(0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  final studentCode = student?.code;
                                  final studentName = student?.name ?? 'Student';
                                  if (studentCode != null && studentCode.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ViewStudentAttendanceScreen(
                                          studentCode: studentCode,
                                          studentName: studentName,
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Student code not available',
                                          style: GoogleFonts.poppins(),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14, horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.event_note,
                                        color: whiteColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'View Attendance',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: whiteColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: whiteColor,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'All Fees (${allFees.length})',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: blackColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (allFees.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.receipt_long_outlined,
                                      size: 64,
                                      color: greyColor1,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No fees found',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: greyColor1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ...allFees.map((fee) =>
                                _buildFeeCard(fee, _currentStudentWithFees)),
                        ],
                      ),
                    ),
                    // Processing Modal Overlay
                    if (_showProcessingModal)
                      Container(
                        color: Colors.black.withOpacity(0.7),
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: whiteColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: primaryColor,
                                  strokeWidth: 3,
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Processing payment',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: blackColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please be patient',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: greyColor1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Note: A transaction fee of ${NumberFormat.currency(symbol: '', decimalDigits: 2).format(_transactionFee)} is included',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: greyColor1,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '$_processingSeconds seconds',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color textColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: textColor.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${NumberFormat.currency(symbol: '', decimalDigits: 2).format(amount)}',
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFeeCard(StudentFee fee, StudentWithFees studentWithFees) {
    final isPaid = fee.status == 'PAID';
    final isUnpaid = fee.status == 'UNPAID';
    final statusColor = isPaid
        ? Colors.green
        : isUnpaid
            ? Colors.orange
            : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  fee.feeTypeName ?? 'Unknown Fee',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: blackColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  fee.status ?? 'UNKNOWN',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFeeDetailItem(
                    'Due', fee.amountDue ?? 0.0, Colors.blue),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFeeDetailItem(
                    'Paid', fee.amountPaid ?? 0.0, Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFeeDetailItem(
                    'Outstanding', fee.amountOutstanding ?? 0.0, Colors.orange),
              ),
            ],
          ),
          if (fee.dueDate != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: greyColor1),
                const SizedBox(width: 8),
                Text(
                  'Due Date: ${_formatDate(fee.dueDate!)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: greyColor1,
                  ),
                ),
              ],
            ),
          ],
          if (fee.academicYear != null || fee.term != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.school_outlined, size: 16, color: greyColor1),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${fee.academicYear ?? ''}${fee.academicYear != null && fee.term != null ? ' - ' : ''}${fee.term ?? ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: greyColor1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          // Pay Button for Unpaid Fees
          if (isUnpaid && (fee.amountOutstanding ?? 0.0) > 0) ...[
            const SizedBox(height: 16),
            Divider(color: greyColor1.withOpacity(0.3)),
            const SizedBox(height: 8),
            _PayButton(
              fee: fee,
              student: studentWithFees.student,
              onPaymentSuccess: () {
                // Refresh fees after payment
                _refreshFees();
              },
            ),
          ],
          if (fee.payments != null && fee.payments!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: greyColor1.withOpacity(0.3)),
            const SizedBox(height: 8),
            Text(
              'Payments (${fee.payments!.length})',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: blackColor,
              ),
            ),
            const SizedBox(height: 8),
            ...fee.payments!.map((payment) => _buildPaymentItem(payment)),
          ],
        ],
      ),
    );
  }

  Widget _buildFeeDetailItem(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: greyColor1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${NumberFormat.currency(symbol: '', decimalDigits: 2).format(amount)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(Payment payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${NumberFormat.currency(symbol: '', decimalDigits: 2).format(payment.amount ?? 0.0)}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  payment.paymentMethod ?? 'N/A',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          if (payment.paymentDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Date: ${_formatDate(payment.paymentDate!)}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: greyColor1,
              ),
            ),
          ],
          if (payment.referenceNumber != null) ...[
            const SizedBox(height: 4),
            Text(
              'Ref: ${payment.referenceNumber}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: greyColor1,
              ),
            ),
          ],
          if (payment.remarks != null && payment.remarks!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              payment.remarks!,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: greyColor1,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}

// Pay Button Widget
class _PayButton extends StatefulWidget {
  final StudentFee fee;
  final StudentData? student;
  final VoidCallback? onPaymentSuccess;

  const _PayButton({
    Key? key,
    required this.fee,
    required this.student,
    this.onPaymentSuccess,
  }) : super(key: key);

  @override
  State<_PayButton> createState() => _PayButtonState();
}

class _PayButtonState extends State<_PayButton> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  static const double _transactionFee = 300.0;

  Future<void> _handlePayment() async {
    if (widget.student?.parentContact == null ||
        widget.student!.parentContact!.isEmpty) {
      showErrorAlert('Parent phone number is required for payment', context);
      return;
    }

    final feeAmount = widget.fee.amountOutstanding ?? 0.0;
    if (feeAmount <= 0) {
      showErrorAlert('No outstanding amount to pay', context);
      return;
    }

    final totalAmount = feeAmount + _transactionFee;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirm Payment',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fee: ${widget.fee.feeTypeName ?? 'Unknown'}',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fee Amount:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: greyColor1,
                  ),
                ),
                Text(
                  NumberFormat.currency(symbol: '', decimalDigits: 2)
                      .format(feeAmount),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction Fee:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: greyColor1,
                  ),
                ),
                Text(
                  NumberFormat.currency(symbol: '', decimalDigits: 2)
                      .format(_transactionFee),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount:',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: blackColor,
                  ),
                ),
                Text(
                  NumberFormat.currency(symbol: '', decimalDigits: 2)
                      .format(totalAmount),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Phone: ${widget.student!.parentContact}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: greyColor1,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A transaction fee of ${NumberFormat.currency(symbol: '', decimalDigits: 2).format(_transactionFee)} will be added to your payment.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: primaryColor,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You will receive a payment request on your phone. Continue?',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: greyColor1,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: greyColor1,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: whiteColor,
            ),
            child: Text(
              'Pay Now',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.fee.id == null || widget.fee.id!.isEmpty) {
        showErrorAlert('Fee ID is missing', context);
        return;
      }

      if (widget.student?.code == null || widget.student!.code!.isEmpty) {
        showErrorAlert('Student code is missing', context);
        return;
      }

      // Check if accountMomoPhone is available
      if (widget.student?.accountMomoPhone == null ||
          widget.student!.accountMomoPhone!.isEmpty) {
        debugPrint('❌ Account MoMo Phone is missing!');
        debugPrint('Student ID: ${widget.student?.id}');
        debugPrint('Student Name: ${widget.student?.name}');
        debugPrint('Student Code: ${widget.student?.code}');
        debugPrint('Account MoMo Phone: ${widget.student?.accountMomoPhone}');
        debugPrint('School Phone: ${widget.student?.schoolPhone}');
        debugPrint('School: ${widget.student?.school}');
        debugPrint('All student fields: ${widget.student?.toJson()}');
        showErrorAlert(
          'This school has not configured a MoMo payment account. Please contact ${widget.student?.school ?? "the school"} to set up payment.',
          context,
        );
        return;
      }

      debugPrint('=== Payment Request Details ===');
      debugPrint('Student: ${widget.student!.name}');
      debugPrint('Student Code: ${widget.student!.code}');
      debugPrint('Payer Phone: ${widget.student!.parentContact}');
      debugPrint('School MoMo Phone: ${widget.student!.accountMomoPhone}');
      debugPrint('Fee Amount: $feeAmount');
      debugPrint('Total Amount: $totalAmount');
      debugPrint('================================');

      if (widget.student?.name == null || widget.student!.name!.isEmpty) {
        showErrorAlert('Student name is missing', context);
        return;
      }

      final result = await _authService.payStudentFee(
        studentFeeId: widget.fee.id!,
        studentCode: widget.student!.code!,
        studentName: widget.student!.name!,
        feeTypeName: widget.fee.feeTypeName ?? 'Fee',
        payerPhone: widget.student!.parentContact ?? '',
        schoolMomoPhone: widget.student!.accountMomoPhone!,
        totalAmount: totalAmount, // Total amount including transaction fee
        feeAmount: feeAmount, // Fee amount without transaction fee
      );

      if (result['success'] == true) {
        // Extract transaction ID from payment initiation response
        // Response structure: { "data": { "transactionId": "SSC..." } }
        // payStudentFee returns: { "success": true, "data": <entire_api_response> }
        // So transactionId is at: result['data']['data']['transactionId']
        final apiResponse = result['data'] as Map<String, dynamic>?;
        final transactionId = apiResponse?['data']?['transactionId'] as String?;

        debugPrint('=== Payment Initiated ===');
        debugPrint('Full API response: $apiResponse');
        debugPrint('Transaction ID extracted: $transactionId');

        // Store transaction ID for Confirm button to call update-fee endpoint
        if (transactionId != null &&
            transactionId.isNotEmpty &&
            widget.student?.id != null) {
          try {
            final SharedPreferences prefs =
                await SharedPreferences.getInstance();
            final String key = 'pendingTransactions_${widget.student!.id}';
            final String? existingJson = prefs.getString(key);

            List<String> pendingTransactions = [];
            if (existingJson != null && existingJson.isNotEmpty) {
              pendingTransactions = List<String>.from(jsonDecode(existingJson));
            }

            if (!pendingTransactions.contains(transactionId)) {
              pendingTransactions.add(transactionId);
              await prefs.setString(key, jsonEncode(pendingTransactions));
              debugPrint(
                  '✅ Stored transaction ID: $transactionId for student: ${widget.student!.id}');
              debugPrint('All pending transactions: $pendingTransactions');
            } else {
              debugPrint('⚠️ Transaction ID already stored: $transactionId');
            }
          } catch (e) {
            debugPrint('❌ Error storing transaction ID: $e');
          }
        } else {
          debugPrint(
              '❌ Transaction ID is null or empty. Student ID: ${widget.student?.id}');
        }

        // Show success dialog with refresh option
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Payment Initiated',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result['message'] ?? 'Payment request sent successfully',
                    style: GoogleFonts.poppins(),
                  ),
                  if (transactionId != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.receipt, size: 16, color: greyColor1),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Transaction: $transactionId',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: greyColor1,
                              ).copyWith(fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Payment Instructions',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• You will receive a payment request on your phone\n'
                          '• The payment amount includes a transaction fee of ${NumberFormat.currency(symbol: '', decimalDigits: 2).format(_transactionFee)}\n'
                          '• Check your phone to complete the payment\n'
                          '• After payment, click "Confirm" to update fee status',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: greyColor1,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      color: greyColor1,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Trigger refresh callback
                    widget.onPaymentSuccess?.call();
                  },
                  icon: const Icon(Icons.confirmation_num, size: 18),
                  label: Text(
                    'Confirm',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: whiteColor,
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        showErrorAlert(
          result['message'] ?? 'Payment request failed',
          context,
        );
      }
    } catch (e) {
      showErrorAlert('Error processing payment: $e', context);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green,
            Colors.green.shade700,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handlePayment,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(
                    Icons.payment_outlined,
                    color: whiteColor,
                    size: 20,
                  ),
                if (!_isLoading) const SizedBox(width: 8),
                Text(
                  _isLoading
                      ? 'Processing...'
                      : 'Pay ${NumberFormat.currency(symbol: '', decimalDigits: 2).format((widget.fee.amountOutstanding ?? 0.0) + _transactionFee)}',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: whiteColor,
                    letterSpacing: 0.5,
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

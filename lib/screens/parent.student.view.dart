import 'package:attendance/models/parent.lookup.model.dart';
import 'package:attendance/models/student.model.dart';
import 'package:attendance/utils/colors.dart';
import 'package:attendance/utils/notifiers.dart';
import 'package:attendance/api/auth.service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
              itemBuilder: (context, index) {
                final studentWithFees = studentsWithFees[index];
                return _buildStudentCard(studentWithFees, context);
              },
            ),
    );
  }

  Widget _buildStudentCard(
      StudentWithFees studentWithFees, BuildContext context) {
    final student = studentWithFees.student;
    final feeSummary = studentWithFees.feeSummary;
    final hasUnpaidFees = studentWithFees.hasUnpaidFees ?? false;

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
                          student.profileImage!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            student.profileImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 30,
                                color: primaryColor,
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
                _buildInfoRow(
                  icon: Icons.school_outlined,
                  label: 'School',
                  value: student.school ?? 'N/A',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.class_outlined,
                  label: 'Classroom',
                  value: student.classroom ?? 'N/A',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Parent Contact',
                  value: student.parentContact ?? 'N/A',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.person_outline,
                  label: 'Gender',
                  value: student.gender ?? 'N/A',
                ),
                if (student.level != null) ...[
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    icon: Icons.stairs_outlined,
                    label: 'Level',
                    value: student.level ?? 'N/A',
                  ),
                ],
                // Fee Summary Section
                if (feeSummary != null) ...[
                  const SizedBox(height: 16),
                  Divider(color: greyColor1.withOpacity(0.3)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20,
                        color: hasUnpaidFees ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Fee Summary',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: blackColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: _buildFeeStatCard(
                          'Total Due',
                          feeSummary.totalDue ?? 0.0,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFeeStatCard(
                          'Total Paid',
                          feeSummary.totalPaid ?? 0.0,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildFeeStatCard(
                          'Outstanding',
                          feeSummary.totalOutstanding ?? 0.0,
                          hasUnpaidFees ? Colors.orange : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // View Fees Button
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeStatCard(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: greyColor1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${NumberFormat.currency(symbol: '', decimalDigits: 2).format(amount)}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
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

  @override
  void initState() {
    super.initState();
    _currentStudentWithFees = widget.studentWithFees;
  }

  Future<void> _refreshFees() async {
    if (widget.query == null || widget.query!.isEmpty) {
      showErrorAlert('Cannot refresh: Query not available', context);
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      final AuthService authService = AuthService();
      final result = await authService.fetchStudentsByParent(widget.query!);

      if (result.success == true &&
          result.data != null &&
          result.data!.students != null &&
          result.data!.students!.isNotEmpty) {
        // Find the matching student
        final studentId = widget.studentWithFees.student?.id;
        final updatedStudent = result.data!.students!.firstWhere(
          (s) => s.student?.id == studentId,
          orElse: () => widget.studentWithFees,
        );

        setState(() {
          _currentStudentWithFees = updatedStudent;
        });

        showSuccessAlert('Fee information updated', context);
      } else {
        showErrorAlert('Failed to refresh fee information', context);
      }
    } catch (e) {
      showErrorAlert('Error refreshing fees: $e', context);
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
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh, color: whiteColor),
            onPressed: _isRefreshing ? null : _refreshFees,
            tooltip: 'Refresh fees',
          ),
        ],
      ),
      body: feeSummary == null
          ? Center(
              child: Text(
                'No fee information available',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: greyColor1,
                ),
              ),
            )
          : SingleChildScrollView(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSummaryItem('Total Due',
                                feeSummary.totalDue ?? 0.0, whiteColor),
                            _buildSummaryItem('Total Paid',
                                feeSummary.totalPaid ?? 0.0, whiteColor),
                            _buildSummaryItem('Outstanding',
                                feeSummary.totalOutstanding ?? 0.0, whiteColor),
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
                    ...allFees.map(
                        (fee) => _buildFeeCard(fee, _currentStudentWithFees)),
                ],
              ),
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
          ),
          const SizedBox(height: 4),
          Text(
            '${NumberFormat.currency(symbol: '', decimalDigits: 2).format(amount)}',
            style: GoogleFonts.poppins(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
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
                Text(
                  '${fee.academicYear ?? ''}${fee.academicYear != null && fee.term != null ? ' - ' : ''}${fee.term ?? ''}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: greyColor1,
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
          ),
          const SizedBox(height: 4),
          Text(
            '${NumberFormat.currency(symbol: '', decimalDigits: 2).format(amount)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
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

  Future<void> _handlePayment() async {
    if (widget.student?.parentContact == null ||
        widget.student!.parentContact!.isEmpty) {
      showErrorAlert('Parent phone number is required for payment', context);
      return;
    }

    final amount = widget.fee.amountOutstanding ?? 0.0;
    if (amount <= 0) {
      showErrorAlert('No outstanding amount to pay', context);
      return;
    }

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
            const SizedBox(height: 8),
            Text(
              'Amount: ${NumberFormat.currency(symbol: '', decimalDigits: 2).format(amount)}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Phone: ${widget.student!.parentContact}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: greyColor1,
              ),
            ),
            const SizedBox(height: 16),
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

      final result = await _authService.payStudentFee(
        feeId: widget.fee.id!,
        studentCode: widget.student!.code!,
        payerPhone: widget.student!.parentContact ?? '',
        amount: amount,
      );

      if (result['success'] == true) {
        final transactionId = result['data']?['transactionId'];

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
                  Text(
                    'You will receive a payment request on your phone. Check your phone to complete the payment.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: greyColor1,
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
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(
                    'Refresh',
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
                      : 'Pay ${NumberFormat.currency(symbol: '', decimalDigits: 2).format(widget.fee.amountOutstanding ?? 0.0)}',
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

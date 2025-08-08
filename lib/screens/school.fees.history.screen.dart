import 'package:attendance/controllers/school_fees_controller.dart';
import 'package:attendance/models/classroom.fee.history.dart';
import 'package:attendance/routes/routes.names.dart';
import 'package:attendance/utils/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class FeeHistory extends StatefulWidget {
  final String? classroomId;
  final String? classroom;
  const FeeHistory({super.key, this.classroomId, this.classroom});

  @override
  State<FeeHistory> createState() => _FeeHistoryState();
}

class _FeeHistoryState extends State<FeeHistory> with SingleTickerProviderStateMixin {
  final SchoolFeesController _schoolFeesController = Get.find<SchoolFeesController>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Filter controllers
  final RxString _selectedAcademicYear = ''.obs;
  final RxString _selectedClassroom = ''.obs;
  final RxString _selectedFeeType = ''.obs;

  // Date formatter
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Fetch fee history and types
    if (widget.classroomId != null) {
      _schoolFeesController.fetchFeeHistory(widget.classroomId!);
    } else {
      _schoolFeesController.fetchSchoolFeeHistory();
    }
    _schoolFeesController.fetchFeeTypes('school_id'); // Replace with actual schoolId
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async => true;

  // Format ISO 8601 date to 'dd MMM yyyy'
  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'N/A';
    try {
      final parsedDate = DateTime.parse(date);
      return _dateFormatter.format(parsedDate);
    } catch (e) {
      return 'N/A';
    }
  }

  // Show bottom sheet with fee details and payment options
  void _showFeeDetailsBottomSheet(BuildContext context, ClassroomFeesData fee) {
    final TextEditingController _amountController = TextEditingController();
    final TextEditingController _referenceNumberController = TextEditingController();
    final TextEditingController _receivedByController = TextEditingController();
    final RxString _paymentMethod = 'Cash'.obs;
    final RxBool _isPayingFull = true.obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      margin: const EdgeInsets.only(top: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fee Details',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: blackColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Student Name', fee.studentName ?? 'Unknown'),
                  _buildDetailRow('Student Code', fee.studentCode ?? 'N/A'),
                  _buildDetailRow('Fee Type', fee.feeTypeName ?? 'Unknown'),
                  _buildDetailRow('Amount Due', '\$${fee.amountDue?.toStringAsFixed(2) ?? '0.00'}'),
                  _buildDetailRow('Amount Paid', '\$${fee.amountPaid?.toStringAsFixed(2) ?? '0.00'}'),
                  _buildDetailRow('Amount Outstanding', '\$${fee.amountOutstanding?.toStringAsFixed(2) ?? '0.00'}'),
                  _buildDetailRow('Due Date', _formatDate(fee.dueDate)),
                  _buildDetailRow('Status', fee.status ?? 'N/A'),
                  _buildDetailRow('Academic Year', fee.academicYear ?? 'N/A'),
                  _buildDetailRow('Term', fee.term ?? 'N/A'),
            
                  const SizedBox(height: 16),
                  // Payment Section
                  if (fee.status != 'PAID' && (fee.amountOutstanding ?? 0) > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Record Payment',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: blackColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Obx(() => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ChoiceChip(
                                  label: Text(
                                    'Pay in Full',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: _isPayingFull.value ? whiteColor : blackColor,
                                    ),
                                  ),
                                  selected: _isPayingFull.value,
                                  selectedColor: primaryColor,
                                  onSelected: (selected) {
                                    if (selected) {
                                      _isPayingFull.value = true;
                                      _amountController.text =
                                          (fee.amountOutstanding ?? 0).toStringAsFixed(2);
                                    }
                                  },
                                ),
                                ChoiceChip(
                                  label: Text(
                                    'Partial Payment',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: !_isPayingFull.value ? whiteColor : blackColor,
                                    ),
                                  ),
                                  selected: !_isPayingFull.value,
                                  selectedColor: primaryColor,
                                  onSelected: (selected) {
                                    if (selected) {
                                      _isPayingFull.value = false;
                                      _amountController.clear();
                                    }
                                  },
                                ),
                              ],
                            )),
                        const SizedBox(height: 8),
                        Obx(() => TextFormField(
                              controller: _amountController,
                              enabled: !_isPayingFull.value,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Payment Amount',
                                labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: primaryColor, width: 2),
                                ),
                              ),
                              style: GoogleFonts.poppins(fontSize: 14),
                            )),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _paymentMethod.value,
                          decoration: InputDecoration(
                            labelText: 'Payment Method',
                            labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                          ),
                          items: ['Cash', 'Card', 'Bank Transfer']
                              .map((method) => DropdownMenuItem(
                                    value: method,
                                    child: Text(
                                      method,
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) => _paymentMethod.value = value!,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _referenceNumberController,
                          decoration: InputDecoration(
                            labelText: 'Reference Number',
                            labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                          ),
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _receivedByController,
                          decoration: InputDecoration(
                            labelText: 'Received By',
                            labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryColor, width: 2),
                            ),
                          ),
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Obx(() => _schoolFeesController.isLoading.value
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: whiteColor,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  final amount = _isPayingFull.value
                                      ? (fee.amountOutstanding ?? 0)
                                      : double.tryParse(_amountController.text) ?? 0;
                                  if (amount <= 0 ||
                                      amount > (fee.amountOutstanding ?? 0)) {
                                    Get.snackbar(
                                      'Error',
                                      'Invalid payment amount',
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                    return;
                                  }
                                  if (_referenceNumberController.text.isEmpty ||
                                      _receivedByController.text.isEmpty) {
                                    Get.snackbar(
                                      'Error',
                                      'Please fill all required fields',
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                    return;
                                  }
                                  await _schoolFeesController.recordPayment(
                                    feeId: fee.id!,
                                    amount: amount,
                                    paymentMethod: _paymentMethod.value,
                                    referenceNumber: _referenceNumberController.text,
                                    receivedBy: _receivedByController.text,
                                  );
                                  if (_schoolFeesController.errorMessage.value.isEmpty) {
                                    // Refresh fee history
                                    if (widget.classroomId != null) {
                                      await _schoolFeesController
                                          .fetchFeeHistory(widget.classroomId!);
                                    } else {
                                      await _schoolFeesController.fetchSchoolFeeHistory();
                                    }
                                    if (mounted) {
                                      Navigator.pop(context); // Close bottom sheet
                                      Get.snackbar(
                                        'Success',
                                        'Payment recorded successfully',
                                        backgroundColor: Colors.green,
                                        colorText: Colors.white,
                                      );
                                    }
                                  }
                                },
                                child: Text(
                                  'Record Payment',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: whiteColor,
                                  ),
                                ),
                              )),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: blackColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: primaryColor,
          elevation: 0,
          toolbarHeight: 80,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.toNamed(home),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "School Fee History",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Obx(() => Text(
                    "Total fees: ${_schoolFeesController.feeHistory.length}",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  )),
            ],
          ),
        ),
        body: Obx(() {
          if (_schoolFeesController.isLoading.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SpinKitDoubleBounce(color: primaryColor, size: 50.0),
                  const SizedBox(height: 20),
                  Text(
                    'Loading fee history...',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          } else if (_schoolFeesController.feeHistory.isNotEmpty) {
            // Extract unique values for filters
            final academicYears = _schoolFeesController.feeHistory
                .map((fee) => fee.academicYear)
                .where((year) => year != null)
                .toSet()
                .toList()
              ..sort();
            final classrooms = _schoolFeesController.feeHistory
                .map((fee) => widget.classroom ?? 'All Classes')
                .toSet()
                .toList();
            final feeTypes = _schoolFeesController.feeTypes
                .map((feeType) => feeType.name)
                .where((name) => name != null)
                .toSet()
                .toList();

            // Apply filters
            final filteredFees = _schoolFeesController.feeHistory.where((fee) {
              final matchesYear = _selectedAcademicYear.value.isEmpty ||
                  fee.academicYear == _selectedAcademicYear.value;
              final matchesClass = _selectedClassroom.value.isEmpty ||
                  widget.classroom == _selectedClassroom.value;
              final matchesFeeType = _selectedFeeType.value.isEmpty ||
                  fee.feeTypeName == _selectedFeeType.value;
              return matchesYear && matchesClass && matchesFeeType;
            }).toList();

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Fee History",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Filter Section
                      Row(
                        children: [
                          Expanded(
                            child: _buildFilterDropdown(
                              hint: 'Academic Year',
                              value: _selectedAcademicYear.value.isEmpty
                                  ? null
                                  : _selectedAcademicYear.value,
                              items: ['All Years', ..._schoolFeesController.academicYears],
                              onChanged: (value) {
                                _selectedAcademicYear.value =
                                    value == 'All Years' ? '' : value!;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterDropdown(
                              hint: 'Classroom',
                              value: _selectedClassroom.value.isEmpty
                                  ? null
                                  : _selectedClassroom.value,
                              items: ['All Classes', ...classrooms],
                              onChanged: (value) {
                                _selectedClassroom.value =
                                    value == 'All Classes' ? '' : value!;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildFilterDropdown(
                              hint: 'Fee Type',
                              value: _selectedFeeType.value.isEmpty
                                  ? null
                                  : _selectedFeeType.value,
                              items: ['All Fee Types', ...[]],
                              onChanged: (value) {
                                _selectedFeeType.value =
                                    value == 'All Fee Types' ? '' : value!;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Fee Cards
                      filteredFees.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.grey, width: 2),
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    child: const Icon(Icons.inbox, size: 48, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No fees match the selected filters',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredFees.length,
                              itemBuilder: (context, index) {
                                final fee = filteredFees[index];
                                return GestureDetector(
                                  onTap: () => _showFeeDetailsBottomSheet(context, fee),
                                  child: Card(
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    margin: const EdgeInsets.symmetric(vertical: 8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.white, Colors.grey[50]!],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey[200]!,
                                          width: 1,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    fee.studentName ?? 'Unknown',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.w600,
                                                      color: blackColor,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: fee.status == 'PAID'
                                                        ? Colors.green.withOpacity(0.1)
                                                        : Colors.red.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    fee.status ?? 'N/A',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: fee.status == 'PAID'
                                                          ? Colors.green
                                                          : Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Fee Type: ${fee.feeTypeName ?? 'Unknown'}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Amount Due: \$${fee.amountDue?.toStringAsFixed(2) ?? '0.00'}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: blackColor,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Due Date: ${_formatDate(fee.dueDate)}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey, width: 2),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: const Icon(Icons.inbox, size: 48, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Fees found',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }
        }),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(
          hint,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        isExpanded: true,
        underline: const SizedBox(),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: blackColor,
              ),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
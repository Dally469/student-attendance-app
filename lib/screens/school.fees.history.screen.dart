import 'dart:convert';
import 'package:attendance/controllers/school_fees_controller.dart';
import 'package:attendance/models/classroom.fee.history.dart';
import 'package:attendance/utils/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late Animation<Offset> _slideAnimation;
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy');
  String? userFullNames, schoolName, schoolLogo, schoolId;
  final RxBool _isInitialLoading = true.obs; // Track initial loading

  Future<void> getCurrentUserInfo() async {
    try {
      _schoolFeesController.isLoading.value = true;
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      String? userJson = sharedPreferences.getString("currentUser");
      if (userJson != null) {
        Map<String, dynamic> userMap = jsonDecode(userJson);
        setState(() {
          if (userMap.containsKey('school') && userMap['school'] != null) {
            schoolName = userMap['school']['name'];
            schoolLogo = userMap['school']['logo'];
            schoolId = userMap['school']['id'];
          }
        });
        debugPrint("School ID: $schoolId");
        await _schoolFeesController.fetchFeeTypes(schoolId!);
      }
    } catch (e) {
      debugPrint('Error getting user info: $e');
      _schoolFeesController.errorMessage.value = 'Error getting user info: $e';
    } finally {
      _schoolFeesController.isLoading.value = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Fetch initial data with loading state
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      _isInitialLoading.value = true;
      _schoolFeesController.isLoading.value = true;
      if (widget.classroomId != null) {
        await _schoolFeesController.fetchSchoolFeeHistory(classroomId: widget.classroomId);
      } else {
        await _schoolFeesController.fetchSchoolFeeHistory();
      }
      await getCurrentUserInfo();
      await _schoolFeesController.getSchoolClassrooms();
       _animationController.forward();
    } catch (e) {
      debugPrint('Error initializing data: $e');
      Get.snackbar(
        'Error',
        'Failed to load initial data: $e',
        backgroundColor: Colors.red,
        colorText: whiteColor,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      _isInitialLoading.value = false;
      _schoolFeesController.isLoading.value = false;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'N/A';
    try {
      final parsedDate = DateTime.parse(date);
      return _dateFormatter.format(parsedDate);
    } catch (e) {
      return 'N/A';
    }
  }

  void _showFeeDetailsBottomSheet(BuildContext context, ClassroomFeesData fee) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: greyColor1.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Fee Details',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: blackColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow('Student Name', fee.studentName ?? 'Unknown', blackColor),
                  _buildDetailRow('Student Code', fee.studentCode ?? 'N/A', blackColor),
                  _buildDetailRow('Fee Type', fee.feeTypeName ?? 'Unknown', blackColor),
                  _buildDetailRow('Amount Due', '\$${fee.amountDue?.toStringAsFixed(2) ?? '0.00'}', blackColor),
                  _buildDetailRow('Amount Paid', '\$${fee.amountPaid?.toStringAsFixed(2) ?? '0.00'}', blackColor),
                  _buildDetailRow('Amount Outstanding', '\$${fee.amountOutstanding?.toStringAsFixed(2) ?? '0.00'}', blackColor),
                  _buildDetailRow('Due Date', _formatDate(fee.dueDate), blackColor),
                  _buildDetailRow('Status', fee.status ?? 'N/A', blackColor),
                  _buildDetailRow('Academic Year', fee.academicYear ?? 'N/A', blackColor),
                  _buildDetailRow('Term', fee.term ?? 'N/A', blackColor),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: whiteColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Close',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: whiteColor,
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

  void _showRecordFeeBottomSheet(BuildContext context, ClassroomFeesData fee) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController referenceNumberController = TextEditingController();
    final TextEditingController receivedByController = TextEditingController();
    final RxString paymentMethod = 'Cash'.obs;
    final RxBool isPayingFull = true.obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: whiteColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, accentColor.withOpacity(0.9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: whiteColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      fee.studentName ?? 'Unknown',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: whiteColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Student Code: ${fee.studentCode ?? 'N/A'}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: whiteColor.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fee Details',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: blackColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildDetailRow('Fee Type', fee.feeTypeName ?? 'Unknown', blackColor),
                                _buildDetailRow('Amount Due', '\$${fee.amountDue?.toStringAsFixed(2) ?? '0.00'}', blackColor),
                                _buildDetailRow('Amount Paid', '\$${fee.amountPaid?.toStringAsFixed(2) ?? '0.00'}', blackColor),
                                _buildDetailRow('Amount Outstanding', '\$${fee.amountOutstanding?.toStringAsFixed(2) ?? '0.00'}', Colors.red),
                                _buildDetailRow('Due Date', _formatDate(fee.dueDate), blackColor),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (fee.status != 'PAID' && (fee.amountOutstanding ?? 0) > 0)
                          Obx(() => Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Record Payment',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: blackColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildPaymentOptionChip(
                                        'Pay in Full',
                                        isPayingFull.value,
                                        () {
                                          isPayingFull.value = true;
                                          amountController.text = (fee.amountOutstanding ?? 0).toStringAsFixed(2);
                                        },
                                        primaryColor,
                                        whiteColor,
                                        blackColor,
                                      ),
                                      _buildPaymentOptionChip(
                                        'Partial Payment',
                                        !isPayingFull.value,
                                        () {
                                          isPayingFull.value = false;
                                          amountController.clear();
                                        },
                                        primaryColor,
                                        whiteColor,
                                        blackColor,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: amountController,
                                    label: 'Payment Amount',
                                    enabled: !isPayingFull.value,
                                    keyboardType: TextInputType.number,
                                    primaryColor: primaryColor,
                                    blackColor: blackColor,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDropdownField(
                                    value: paymentMethod,
                                    items: ['Cash', 'Card', 'Bank Transfer'],
                                    label: 'Payment Method',
                                    primaryColor: primaryColor,
                                    blackColor: blackColor,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: referenceNumberController,
                                    label: 'Reference Number',
                                    primaryColor: primaryColor,
                                    blackColor: blackColor,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: receivedByController,
                                    label: 'Received By',
                                    primaryColor: primaryColor,
                                    blackColor: blackColor,
                                  ),
                                  const SizedBox(height: 24),
                                  _schoolFeesController.isLoading.value
                                      ? Center(child: SpinKitDoubleBounce(color: primaryColor, size: 40.0))
                                      : _buildSubmitButton(
                                          context,
                                          fee,
                                          isPayingFull,
                                          amountController,
                                          paymentMethod,
                                          referenceNumberController,
                                          receivedByController,
                                          primaryColor,
                                          whiteColor,
                                        ),
                                ],
                              )),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: greyColor1,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionChip(
    String label,
    bool isSelected,
    VoidCallback onSelected,
    Color primaryColor,
    Color whiteColor,
    Color blackColor,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          label: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? whiteColor : blackColor,
            ),
          ),
          selected: isSelected,
          selectedColor: primaryColor,
          backgroundColor: Colors.grey[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (selected) => onSelected(),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    TextInputType? keyboardType,
    required Color primaryColor,
    required Color blackColor,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: greyColor1),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: greyColor1.withOpacity(0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: greyColor1.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      style: GoogleFonts.poppins(fontSize: 14, color: blackColor),
    );
  }

  Widget _buildDropdownField({
    required RxString value,
    required List<String> items,
    required String label,
    required Color primaryColor,
    required Color blackColor,
  }) {
    return Obx(() => DropdownButtonFormField<String>(
          value: value.value.isEmpty || !items.contains(value.value) ? null : value.value,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.poppins(color: greyColor1),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: greyColor1.withOpacity(0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: greyColor1.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
          ),
          items: items
              .map((method) => DropdownMenuItem(
                    value: method,
                    child: Text(
                      method,
                      style: GoogleFonts.poppins(fontSize: 14, color: blackColor),
                    ),
                  ))
              .toList(),
          onChanged: (newValue) => value.value = newValue!,
        ));
  }

  Widget _buildSubmitButton(
    BuildContext context,
    ClassroomFeesData fee,
    RxBool isPayingFull,
    TextEditingController amountController,
    RxString paymentMethod,
    TextEditingController referenceNumberController,
    TextEditingController receivedByController,
    Color primaryColor,
    Color whiteColor,
  ) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: whiteColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      onPressed: () async {
        final amount = isPayingFull.value
            ? (fee.amountOutstanding ?? 0)
            : double.tryParse(amountController.text) ?? 0;
        if (amount <= 0 || amount > (fee.amountOutstanding ?? 0)) {
          Get.snackbar(
            'Error',
            'Invalid payment amount',
            backgroundColor: Colors.red,
            colorText: whiteColor,
            snackPosition: SnackPosition.TOP,
          );
          return;
        }
        if (referenceNumberController.text.isEmpty || receivedByController.text.isEmpty) {
          Get.snackbar(
            'Error',
            'Please fill all required fields',
            backgroundColor: Colors.red,
            colorText: whiteColor,
            snackPosition: SnackPosition.TOP,
          );
          return;
        }
        await _schoolFeesController.recordPayment(
          feeId: fee.id!,
          amount: amount,
          paymentMethod: paymentMethod.value,
          referenceNumber: referenceNumberController.text,
          receivedBy: receivedByController.text,
        );
        if (_schoolFeesController.errorMessage.value.isEmpty) {
          await _schoolFeesController.fetchSchoolFeeHistory(
            classroomId: widget.classroomId,
          );
          Navigator.pop(context);
          Get.snackbar(
            'Success',
            'Payment recorded successfully',
            backgroundColor: Colors.green,
            colorText: whiteColor,
            snackPosition: SnackPosition.TOP,
          );
        } else {
          Get.snackbar(
            'Error',
            _schoolFeesController.errorMessage.value,
            backgroundColor: Colors.red,
            colorText: whiteColor,
            snackPosition: SnackPosition.TOP,
          );
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        toolbarHeight: 80,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: whiteColor),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'School Fee History',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: whiteColor,
              ),
            ),
            Obx(() => Text(
                  'Total fees: ${_schoolFeesController.feeHistory.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: whiteColor.withOpacity(0.8),
                  ),
                )),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: whiteColor),
            onPressed: () => _schoolFeesController.showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Obx(() => _isInitialLoading.value
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SpinKitDoubleBounce(color: primaryColor, size: 50.0),
                  const SizedBox(height: 20),
                  Text(
                    'Loading initial data...',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: blackColor,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fee History',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Obx(() {
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
                                      color: blackColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else if (_schoolFeesController.feeHistory.isNotEmpty) {
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _schoolFeesController.feeHistory.length,
                              itemBuilder: (context, index) {
                                final fee = _schoolFeesController.feeHistory[index];
                                return Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [whiteColor, Colors.grey[50]!],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: greyColor1.withOpacity(0.3)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
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
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: blackColor,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: fee.status == 'PAID' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  fee.status ?? 'N/A',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: fee.status == 'PAID' ? Colors.green : Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Fee Type: ${fee.feeTypeName ?? 'Unknown'}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: greyColor1,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Amount Due: \$${fee.amountDue?.toStringAsFixed(2) ?? '0.00'}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: blackColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Due Date: ${_formatDate(fee.dueDate)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w400,
                                              color: greyColor1,
                                            ),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              TextButton(
                                                child: Text(
                                                  'View Details',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: primaryColor,
                                                  ),
                                                ),
                                                onPressed: () => _showFeeDetailsBottomSheet(context, fee),
                                              ),
                                              if (fee.amountOutstanding != null && fee.amountOutstanding! > 0)
                                                TextButton.icon(
                                                  icon: const Icon(Icons.payment, color: primaryColor, size: 12),
                                                  label: Text(
                                                    'Tap to pay',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w500,
                                                      color: primaryColor,
                                                    ),
                                                  ),
                                                  onPressed: () => _showRecordFeeBottomSheet(context, fee),
                                                ),
                                              TextButton.icon(
                                                icon: const Icon(Icons.send, color: accentColor, size: 13),
                                                label: Text(
                                                  'Notify to parent',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: accentColor,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  _schoolFeesController.notifyStudentFeeToParent(
                                                    fee.studentId!,
                                                    sendSMS: true,
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          } else {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: greyColor1, width: 2),
                                    ),
                                    padding: const EdgeInsets.all(20),
                                    child: const Icon(Icons.inbox, size: 48, color: greyColor1),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No fees found',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: blackColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            )),
    );
  }
}
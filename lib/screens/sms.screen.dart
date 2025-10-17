import 'dart:convert';

import 'package:attendance/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:attendance/controllers/sms.controller.dart';
import 'package:attendance/models/sms.transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/reference.key.dart';

class SMSTopUpScreen extends StatefulWidget {
  const SMSTopUpScreen({super.key});

  @override
  State<SMSTopUpScreen> createState() => _SMSTopUpScreenState();
}

class _SMSTopUpScreenState extends State<SMSTopUpScreen>
    with TickerProviderStateMixin {
  final SMSController _smsController = Get.find<SMSController>();
  late TabController _tabController;
  final TextEditingController _topUpAmountController = TextEditingController();
  final TextEditingController _paymentReferenceController =
      TextEditingController();
  String _selectedPaymentMethod = 'mtn';
  int _historyPage = 0;
  final int _historyPageSize = 10;

  final List<double> _quickAmounts = [25, 50, 100, 200, 500];
  final List<Map<String, dynamic>> _paymentMethods = [
    {'id': 'mtn', 'name': 'MTN Momo', 'icon': "assets/icons/mtn-momo.png"},
    {'id': 'airtel', 'name': 'Airtel Money', 'icon': "assets/icons/airtel.jpg"},
  ];

  Future<void> getCurrentUserInfo() async {
    try {
      _smsController.isLoading.value = true;
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      String? userJson = sharedPreferences.getString("currentUser");
      if (userJson != null) {
        Map<String, dynamic> userMap = jsonDecode(userJson);
        setState(() {
          if (userMap.containsKey('school') && userMap['school'] != null) {
            _smsController.schoolId = userMap['school']['id'];
          }
        });
        debugPrint("School ID: ${userMap['school']['id']}");
        await _smsController.getSMSBalance();
      }
    } catch (e) {
      debugPrint('Error getting user info: $e');
      _smsController.errorMessage.value = 'Error getting user info: $e';
    } finally {
      _smsController.isLoading.value = false;
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUserInfo();
    _tabController = TabController(length: 2, vsync: this);
    if (_smsController.schoolId.isNotEmpty) {
      _smsController.getSMSBalance();
      _smsController.getSMSHistory(page: _historyPage, size: _historyPageSize);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _topUpAmountController.dispose();
    _paymentReferenceController.dispose();
    super.dispose();
  }

  void _selectQuickAmount(double amount) {
    _topUpAmountController.text = amount.toString();

    final autoReference = ReferenceCodeGenerator.generateCustomPattern(
      "TOP-999-XXX",
    );

    _paymentReferenceController.text = autoReference;
    HapticFeedback.lightImpact();
  }

  Future<void> _processTopUp() async {
    if (_topUpAmountController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter an amount',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    if (_paymentReferenceController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a payment reference',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    final amount = double.tryParse(_topUpAmountController.text);
    if (amount == null || amount <= 0) {
      Get.snackbar(
        'Error',
        'Please enter a valid amount',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildConfirmationDialog(amount),
    );

    if (confirmed == true) {
      await _smsController.topUpSMS(
        amount: amount,
        paymentMethod: _selectedPaymentMethod,
        paymentReference: _paymentReferenceController.text,
      );
      _topUpAmountController.clear();
      _paymentReferenceController.clear();
    }
  }

  Widget _buildConfirmationDialog(double amount) {
    final paymentMethod = _paymentMethods
        .firstWhere((method) => method['id'] == _selectedPaymentMethod);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.confirmation_num, color: primaryColor, size: 24),
          const SizedBox(width: 8),
          Text('Confirm Top-up',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 18)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amount: ${amount.toStringAsFixed(0)} SMS Credits',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Payment Method: ${paymentMethod['name']}',
              style: GoogleFonts.poppins(fontSize: 14)),
          const SizedBox(height: 8),
          Text('Cost: \$${(amount * 0.1).toStringAsFixed(2)}',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.orange)),
          const SizedBox(height: 8),
          Text('Reference: ${_paymentReferenceController.text}',
              style: GoogleFonts.poppins(fontSize: 14)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: GoogleFonts.poppins()),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child:
              Text('Confirm', style: GoogleFonts.poppins(color: Colors.white)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 4,
        title: Text(
          'SMS Management',
          style: GoogleFonts.poppins(
              fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle:
              GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Top-up & Balance'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildTopUpTab(),
              // _buildHistoryTab(),
              _buildHistoryTab(),
            ],
          ),
          Obx(() => _smsController.isLoading.value
              ? Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: SpinKitFadingCircle(
                      color: primaryColor,
                      size: 50.0,
                    ),
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildTopUpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryColor, Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.sms, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Current SMS Balance',
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
                      fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 8),
                Obx(() => Text(
                      '${_smsController.smsBalance.value.toStringAsFixed(0)} Credits',
                      style: GoogleFonts.poppins(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Top-up Section
          Text(
            'Top-up SMS Credits',
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 16),

          // Quick Amount Buttons
          Text(
            'Quick Amounts',
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts
                .map((amount) => InkWell(
                      onTap: () => _selectQuickAmount(amount),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: primaryColor.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${amount.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor),
                            ),
                            Text(
                              '9 RFW',
                              style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 24),

          // Custom Amount Input
          Text(
            'Custom Amount',
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _topUpAmountController,
            keyboardType: TextInputType.number,
            icon: Icons.sms,
            label: 'Enter SMS credits amount',
            validator: (value) {
              if (value == null || value.isEmpty) return 'Amount is required';
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) return 'Enter a valid amount';
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Payment Reference Input
          Text(
            'Payment Reference',
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _paymentReferenceController,
            icon: Icons.receipt,
            label: 'Enter payment reference',
            validator: (value) =>
                value!.isEmpty ? 'Payment reference is required' : null,
          ),

          const SizedBox(height: 24),

          // Payment Method Selection
          Text(
            'Payment Method',
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedPaymentMethod,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: greyColor1),
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
            items: _paymentMethods
                .map((method) => DropdownMenuItem<String>(
                      value: method['id'],
                      child: Row(
                        children: [
                          Image.asset(method['icon'], width: 30, height: 30),
                          const SizedBox(width: 8),
                          Text(method['name'], style: GoogleFonts.poppins()),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (value) =>
                setState(() => _selectedPaymentMethod = value!),
          ),

          const SizedBox(height: 32),

          // Top-up Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _smsController.isLoading.value ? null : _processTopUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Top-up SMS Credits',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          ),

          // Error and Success Messages
          Obx(() {
            if (_smsController.errorMessage.value.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Get.snackbar(
                  'Error',
                  _smsController.errorMessage.value,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                );
              });
            }
            if (_smsController.successMessage.value.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Get.snackbar(
                  'Success',
                  _smsController.successMessage.value,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: primaryColor,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                );
              });
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: () async {
        _historyPage = 0;
        await _smsController.getSMSHistory(
            page: _historyPage, size: _historyPageSize);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SMS Transaction History',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: primaryColor),
                  onPressed: () => _smsController.getSMSHistory(
                      page: _historyPage, size: _historyPageSize),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (_smsController.smsHistory.isEmpty) {
                return Center(
                  child: Text(
                    _smsController.errorMessage.value.isNotEmpty
                        ? _smsController.errorMessage.value
                        : 'No transactions found',
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                );
              }
              return Column(
                children: [
                  ..._smsController.smsHistory
                      .asMap()
                      .entries
                      .map((entry) => _buildHistoryItem(entry.value))
                      .toList(),
                  if (_smsController.smsHistory.length >= _historyPageSize)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: ElevatedButton(
                        onPressed: () async {
                          _historyPage++;
                          await _smsController.getSMSHistory(
                              page: _historyPage, size: _historyPageSize);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Load More',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                await _smsController.clearCache();
                Get.snackbar(
                  'Success',
                  'Cache cleared successfully',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: primaryColor,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(16),
                );
              },
              child: Text(
                'Clear Cache',
                style: GoogleFonts.poppins(color: primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.poppins(fontSize: 14, color: blackColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: greyColor1),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: greyColor1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: greyColor1.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        prefixIcon: Icon(icon, color: greyColor1),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }

  Widget _buildHistoryItem(SMSTransaction transaction) {
    final isCredit = transaction.amount > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isCredit ? Colors.green : Colors.red).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: isCredit ? Colors.green : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description ?? 'SMS Transaction',
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                Text(
                  transaction.createdAt?.toString() ?? 'Unknown date',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : ''}${transaction.amount.toStringAsFixed(0)} Credits',
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isCredit ? Colors.green : Colors.red),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:attendance/api/fee.service.dart';
import 'package:attendance/controllers/school_classroom_controller.dart';
import 'package:attendance/models/fee.assign.dto.dart';
import 'package:attendance/models/school.fee.type.dart';
import 'package:attendance/utils/colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api/classroom_service.dart';
import '../models/classroom.fee.history.dart';
import '../models/classroom.model.dart';
import '../models/student.model.dart';
import '../routes/routes.names.dart' as routes;
import '../routes/routes.names.dart';
import '../utils/notifiers.dart';

class SchoolFeesController extends GetxController {
  final FeeService _feeService = FeeService();
  final ClassroomService _classroomService = ClassroomService();

  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  RxString successMessage = ''.obs;
  RxList<StudentFeeDTO> fees = <StudentFeeDTO>[].obs;
  RxList<ClassroomFeesData> feeHistory = <ClassroomFeesData>[].obs;
  RxList<StudentData> students = <StudentData>[].obs; // Changed to StudentData

  RxList<FeesData> feeTypes = <FeesData>[].obs;
  RxList<String> academicYears = <String>[
    '2024/2025',
    '2025/2026',
  ].obs;
  RxList<String> terms = <String>[
    'Term 1',
    'Term 2',
    'Term 3',
  ].obs;

  RxList<Classrooms> classrooms = <Classrooms>[].obs;
  Timer? _debounce; // Debounce timer for search

  @override
  void onInit() {
    super.onInit();
    // Optionally fetch fee types or other initial data here
  }

  Future<void> fetchFeeTypes(String schoolId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final result = await _feeService.fetchFeeTypes(schoolId);
      if (result.success == true && result.data != null) {
        feeTypes.value = result.data!;
        successMessage.value = 'Fee types loaded successfully';
        debugPrint('Fee types loaded successfully');
      } else {
        errorMessage.value = result.message ?? 'Failed to load fee types';
      }
    } catch (e) {
      errorMessage.value = 'Error loading fee types: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getSchoolClassrooms() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _classroomService.fetchSchoolClassrooms();
      debugPrint("Classrooms: ${result.data?.classrooms?.length}");
      if (result.success == true && result.data != null) {
        classrooms.assignAll(result.data!.classrooms!);
      } else {
        errorMessage.value = result.message ?? 'Failed to fetch classrooms';
      }
    } catch (e) {
      errorMessage.value = 'Error fetching classrooms: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSchoolFeeHistory({
    String? classroomId,
    String? academicYear,
    String? status,
    String? feeTypeId,
    String? term,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final result = await _feeService.fetchSchoolFeeHistory(
        classroomId: classroomId,
        academicYear: academicYear,
        status: status,
        feeTypeId: feeTypeId,
        term: term,
      );
      if (result.isNotEmpty) {
        feeHistory.value = result;
        successMessage.value = 'Fee history loaded successfully';
      } else {
        feeHistory.clear();
        successMessage.value = 'No fee history found for the selected filters';
      }
    } catch (e) {
      errorMessage.value = 'Error loading fee history: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
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
    );
  }

  void showFilterBottomSheet(BuildContext context) {
    final RxString? selectedClassroom = ''.obs;
    final RxString? selectedAcademicYear = ''.obs;
    final RxString? selectedStatus = ''.obs;
    final RxString? selectedFeeType = ''.obs;
    final RxString? selectedTerm = ''.obs;

    final AnimationController animationController = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 600),
    );

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    final slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        animationController.forward();
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) => FadeTransition(
            opacity: fadeAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
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
                      SlideTransition(
                        position: slideAnimation,
                        child: Text(
                          'Filter Fee History',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: blackColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Classroom Dropdown
                      SlideTransition(
                        position: slideAnimation,
                        child: Obx(() => DropdownButtonFormField<String>(
                              value: selectedClassroom?.value != null &&
                                      classrooms.any((c) =>
                                          c.id == selectedClassroom?.value)
                                  ? selectedClassroom?.value
                                  : null,
                              hint: Text(
                                'Select Classroom',
                                style: GoogleFonts.poppins(color: greyColor1),
                              ),
                              decoration: _buildInputDecoration('Classroom'),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('All Classrooms'),
                                ),
                                ...classrooms
                                    .map((classroom) => DropdownMenuItem(
                                          value: classroom.id,
                                          child: Text(
                                            classroom.name.toString(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: blackColor,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ],
                              onChanged: (value) =>
                                  selectedClassroom?.value = value!,
                            )),
                      ),
                      const SizedBox(height: 16),
                      // Academic Year Dropdown
                      SlideTransition(
                        position: slideAnimation,
                        child: Obx(() => DropdownButtonFormField<String>(
                              value: selectedAcademicYear?.value != null &&
                                      academicYears
                                          .contains(selectedAcademicYear?.value)
                                  ? selectedAcademicYear?.value
                                  : null,
                              hint: Text(
                                'Select Academic Year',
                                style: GoogleFonts.poppins(color: greyColor1),
                              ),
                              decoration:
                                  _buildInputDecoration('Academic Year'),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('All Years'),
                                ),
                                ...academicYears
                                    .map((year) => DropdownMenuItem(
                                          value: year,
                                          child: Text(
                                            year,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: blackColor,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ],
                              onChanged: (value) =>
                                  selectedAcademicYear?.value = value!,
                            )),
                      ),
                      const SizedBox(height: 16),
                      // Status Dropdown
                      SlideTransition(
                        position: slideAnimation,
                        child: Obx(() => DropdownButtonFormField<String>(
                              value: selectedStatus?.value != null &&
                                      ['PAID', 'UNPAID', 'PARTIALLY_PAID']
                                          .contains(selectedStatus?.value)
                                  ? selectedStatus?.value
                                  : null,
                              hint: Text(
                                'Select Status',
                                style: GoogleFonts.poppins(color: greyColor1),
                              ),
                              decoration:
                                  _buildInputDecoration('Payment Status'),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('All Statuses'),
                                ),
                                ...['PAID', 'UNPAID', 'PARTIALLY_PAID']
                                    .map((status) => DropdownMenuItem(
                                          value: status,
                                          child: Text(
                                            status
                                                .replaceAll('_', ' ')
                                                .capitalize!,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: blackColor,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ],
                              onChanged: (value) =>
                                  selectedStatus?.value = value!,
                            )),
                      ),
                      const SizedBox(height: 16),
                      // Fee Type Dropdown
                      SlideTransition(
                        position: slideAnimation,
                        child: Obx(() => DropdownButtonFormField<String>(
                              value: selectedFeeType?.value != null &&
                                      feeTypes.any(
                                          (f) => f.id == selectedFeeType?.value)
                                  ? selectedFeeType?.value
                                  : null,
                              hint: Text(
                                'Select Fee Type',
                                style: GoogleFonts.poppins(color: greyColor1),
                              ),
                              decoration: _buildInputDecoration('Fee Type'),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('All Fee Types'),
                                ),
                                ...feeTypes
                                    .map((feeType) => DropdownMenuItem(
                                          value: feeType.id,
                                          child: Text(
                                            feeType.name.toString(),
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: blackColor,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ],
                              onChanged: (value) =>
                                  selectedFeeType?.value = value!,
                            )),
                      ),
                      const SizedBox(height: 16),
                      // Term Dropdown
                      SlideTransition(
                        position: slideAnimation,
                        child: Obx(() => DropdownButtonFormField<String>(
                              value: selectedTerm?.value != null &&
                                      terms.contains(selectedTerm?.value)
                                  ? selectedTerm?.value
                                  : null,
                              hint: Text(
                                'Select Term',
                                style: GoogleFonts.poppins(color: greyColor1),
                              ),
                              decoration: _buildInputDecoration('Term'),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('All Terms'),
                                ),
                                ...terms
                                    .map((term) => DropdownMenuItem(
                                          value: term,
                                          child: Text(
                                            term,
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: blackColor,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ],
                              onChanged: (value) =>
                                  selectedTerm?.value = value!,
                            )),
                      ),
                      const SizedBox(height: 24),
                      SlideTransition(
                        position: slideAnimation,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                selectedClassroom?.value = '';
                                selectedAcademicYear?.value = '';
                                selectedStatus?.value = '';
                                selectedFeeType?.value = '';
                                selectedTerm?.value = '';
                                fetchSchoolFeeHistory();
                                animationController
                                    .reverse()
                                    .then((_) => Navigator.pop(context));
                                Get.snackbar(
                                  'Success',
                                  'Filters cleared',
                                  backgroundColor: Colors.green,
                                  colorText: whiteColor,
                                  snackPosition: SnackPosition.TOP,
                                );
                              },
                              child: Text(
                                'Clear Filters',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: whiteColor,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              onPressed: () async {
                                await fetchSchoolFeeHistory(
                                  classroomId: selectedClassroom?.value,
                                  academicYear: selectedAcademicYear?.value,
                                  status: selectedStatus?.value,
                                  feeTypeId: selectedFeeType?.value,
                                  term: selectedTerm?.value,
                                );
                                Navigator.pop(context);
                                if (errorMessage.value.isNotEmpty) {
                                  Get.snackbar(
                                    'Error',
                                    errorMessage.value,
                                    backgroundColor: Colors.red,
                                    colorText: whiteColor,
                                    snackPosition: SnackPosition.TOP,
                                  );
                                } else {
                                  Get.snackbar(
                                    'Success',
                                    successMessage.value,
                                    backgroundColor: Colors.green,
                                    colorText: whiteColor,
                                    snackPosition: SnackPosition.TOP,
                                  );
                                }
                              },
                              child: Text(
                                'Apply Filters',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: whiteColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ).whenComplete(() => animationController.dispose());
  }

  Future<void> applyFee({
    required String classroomId,
    required String feeTypeId,
    required double amount,
    required String dueDate, // ISO 8601 format (e.g., "2025-12-31T23:59:59")
    required String academicYear,
    required String term,
    List<String>? studentIds,
    String? singleStudentId,
    bool isClassLevel = true,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final fee = await _feeService.applyFee(
        classroomId: classroomId,
        feeTypeId: feeTypeId,
        amount: amount,
        dueDate: dueDate,
        academicYear: academicYear,
        term: term,
        studentIds: studentIds,
        singleStudentId: singleStudentId,
        isClassLevel: isClassLevel,
      );

      if (isClassLevel) {
        successMessage.value = 'Fee assigned to classroom successfully';
        // Fetch updated fee history for the classroom
        await fetchFeeHistory(classroomId);
      } else {
        fees.add(fee);
        successMessage.value = 'Fee assigned to student successfully';
        await fetchSchoolFeeHistory();
      }

      Navigator.pop(Get.context!);

      Get.toNamed(routes.feeHistory, parameters: {
        'classroomId': classroomId,
        'classroom': feeTypeId,
      });
    } catch (e) {
      errorMessage.value = 'Error applying fee: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> recordPayment({
    required String feeId,
    required double amount,
    required String paymentMethod,
    required String referenceNumber,
    required String receivedBy,
    String? remarks,
  }) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final payment = await _feeService.recordPayment(
        feeId: feeId,
        amount: amount,
        paymentMethod: paymentMethod,
        referenceNumber: referenceNumber,
        receivedBy: receivedBy,
        remarks: remarks,
      );

      debugPrint(payment.toString());
      if (payment.success == true && payment.status == 200) {
        successMessage.value = 'Payment recorded successfully';
        showSuccessAlert(successMessage.value, Get.context!);
        // Fetch updated fee history for the classroom
        await fetchSchoolFeeHistory();
        // Get.back();
        Navigator.pop(Get.context!);
          Get.toNamed(home);
      }
      // feeHistory.add(payment);
    } catch (e) {
      errorMessage.value = 'Error recording payment: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchFeeHistory(String classroomId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final history = await _feeService.fetchFeeHistory(classroomId);
      feeHistory.value = history;
      successMessage.value = 'Fee history loaded successfully';
    } catch (e) {
      errorMessage.value = 'Error loading fee history: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStudentFees(String studentId) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final studentFees = await _feeService.fetchStudentFees(studentId);
      fees.value = studentFees;
      successMessage.value = 'Student fees loaded successfully';
    } catch (e) {
      errorMessage.value = 'Error loading student fees: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> notifyStudentFeeToParent(String studentId,
      {bool sendSMS = false}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      await _feeService.notifyStudentFeeToParent(studentId, sendSMS: sendSMS);
      successMessage.value = 'Fee notification sent successfully';
    } catch (e) {
      errorMessage.value = 'Error loading fee history: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

// Updated searchStudents with debouncing
  Future<void> searchStudents(String query) async {
    // Cancel previous debounce timer
    _debounce?.cancel();

    // Validate query
    if (query.trim().isEmpty) {
      students.clear();
      errorMessage.value = 'Please enter a valid search query';
      showErrorAlert(errorMessage.value, Get.context!);
      return;
    }

    // Debounce search by 500ms
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        isLoading.value = true;
        errorMessage.value = '';
        successMessage.value = '';

        final result = await _feeService.searchStudents(query);
        if (result.success == true && result.data != null) {
          students.value = result.data!;
          debugPrint(result.data!.toString());
          successMessage.value = result.data!.isNotEmpty
              ? 'Students loaded successfully'
              : 'No students found for the query';
          if (result.data!.isEmpty && Get.context != null) {
            showSuccessAlert(successMessage.value, Get.context!);
          }
        } else {
          students.clear();
          errorMessage.value = result.message ?? 'Failed to load students';
          showErrorAlert(errorMessage.value, Get.context!);
        }
      } catch (e) {
        students.clear();
        errorMessage.value = 'Error loading students: ${e.toString()}';
        showErrorAlert(errorMessage.value, Get.context!);
      } finally {
        isLoading.value = false;
      }
    });
  }
}

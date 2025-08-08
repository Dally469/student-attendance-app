import 'package:attendance/api/fee.service.dart';
import 'package:attendance/models/fee.assign.dto.dart';
import 'package:attendance/models/fee.payment.dto.dart';
import 'package:attendance/models/school.fee.type.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../models/classroom.fee.history.dart';
import '../routes/routes.names.dart' as routes;

class SchoolFeesController extends GetxController {
  final FeeService _feeService = FeeService();

  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  RxString successMessage = ''.obs;
  RxList<StudentFeeDTO> fees = <StudentFeeDTO>[].obs;
  RxList<ClassroomFeesData> feeHistory = <ClassroomFeesData>[].obs;
  RxList<Map<String, dynamic>> students = <Map<String, dynamic>>[].obs;
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

  Future<void> fetchSchoolFeeHistory() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final result = await _feeService.fetchSchoolFeeHistory();
      if (result.isNotEmpty) {
        feeHistory.value = result;
        successMessage.value = 'Fee history loaded successfully';
      } else {
        errorMessage.value = 'Failed to load fee history';
      }
    } catch (e) {
      errorMessage.value = 'Error loading fee types: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
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

       Get.toNamed(routes.feeHistory, parameters: {
         'classroomId': classroomId,
         'classroom': feeTypeId,
         
       });
       Get.back();
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

      // feeHistory.add(payment);
      successMessage.value = 'Payment recorded successfully';
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
}
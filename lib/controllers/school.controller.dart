import 'package:attendance/api/fee.service.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../models/record.school.dart';
import '../models/school.model.dart';
import '../routes/routes.names.dart';
import '../utils/notifiers.dart';

class SchoolController extends GetxController {
  final FeeService _feeService = FeeService();
  final RxList<SchoolData> schools = <SchoolData>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isInitialLoading = true.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxString successMessage = ''.obs;

  // Filtered schools based on search
  List<SchoolData> get filteredSchools {
    if (searchQuery.value.isEmpty) {
      return schools;
    }
    return schools.where((school) {
      return school.name!
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()) ||
          (school.phone!
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase())) ||
          (school.email!
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase()));
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchSchools();
  }

  // Fetch all schools
  Future<void> fetchSchools() async {
    try {
      isInitialLoading.value = true;
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _feeService.fetchSchools();
      schools.value = response;
      isInitialLoading.value = false;
      isLoading.value = false;
    } catch (e) {
      errorMessage.value = 'Error fetching schools: $e';
      debugPrint('Error fetching schools: $e');
    } finally {
      isLoading.value = false;
      isInitialLoading.value = false;
    }
  }

  Future<bool> createSchool(SchoolData schoolData) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      debugPrint(schoolData.toString());

      final school = await _feeService.addSchool(schoolData);
   

      debugPrint(school.toString());
      if (school.success == true && school.status == 201) {
        successMessage.value = 'School added successfully';
        showSuccessAlert(successMessage.value, Get.context!);
        // Fetch updated fee history for the classroom
        await fetchSchools();
        // Get.back();
        Navigator.pop(Get.context!);
        Get.toNamed(home);
      }
      return true;
    } catch (e) {
      errorMessage.value = 'Error adding school: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateSchool(SchoolData schoolData) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final school = await _feeService.updateSchool(
        id: schoolData.id!,
        name: schoolData.name!,
        phone: schoolData.phone!,
        email: schoolData.email!,
        logo: schoolData.logo!,
        status: schoolData.status!,
        slogan: schoolData.slogan!,
      );

      debugPrint(school.toString());
      if (school.success == true && school.status == 200) {
        successMessage.value = 'School updated successfully';
        showSuccessAlert(successMessage.value, Get.context!);
        // Fetch updated fee history for the classroom
        await fetchSchools();
        // Get.back();
        Navigator.pop(Get.context!);
        Get.toNamed(home);
      }
      return true;
    } catch (e) {
      errorMessage.value = 'Error updating school: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> deleteSchool(String id) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      successMessage.value = '';

      final school = await _feeService.deleteSchool(id);

      debugPrint(school.toString());
      if (school.success == true && school.status == 204) {
        successMessage.value = 'School deleted successfully';
        showSuccessAlert(successMessage.value, Get.context!);
        // Fetch updated fee history for the classroom
        await fetchSchools();
        // Get.back();
        Navigator.pop(Get.context!);
        Get.toNamed(home);
      }
      return true;
    } catch (e) {
      errorMessage.value = 'Error deleting school: ${e.toString()}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Search schools
  void searchSchools(String query) {
    searchQuery.value = query;
  }

  // Clear search
  void clearSearch() {
    searchQuery.value = '';
  }

  // Refresh schools
  Future<void> refreshSchools() async {
    await fetchSchools();
  }
}

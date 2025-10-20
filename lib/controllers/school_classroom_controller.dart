import 'package:attendance/api/classroom_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../models/classroom.model.dart';

class SchoolClassroomController extends GetxController {
  final ClassroomService _classroomService = ClassroomService();

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxList<Classrooms> classrooms = <Classrooms>[].obs;
  final RxList<Classrooms> filteredClassrooms = <Classrooms>[].obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Listen to classroom changes to update filtered list
    ever(classrooms, (_) => _updateFilteredList());
  }

  // Fetch school classrooms using the stored token
  Future<void> getSchoolClassrooms({bool forceRefresh = false}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _classroomService.fetchSchoolClassrooms(
        forceRefresh: forceRefresh,
      );

      debugPrint("Classrooms: ${result.data?.classrooms?.length}");

      if (result.success == true && result.data != null) {
        classrooms.assignAll(result.data!.classrooms!);
        // Sort classrooms alphabetically
        classrooms.sort((a, b) => 
          (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase())
        );
      } else {
        errorMessage.value = result.message ?? 'Failed to fetch classrooms';
      }
    } catch (e) {
      debugPrint('Error in getSchoolClassrooms: $e');
      errorMessage.value = 'Error fetching classrooms: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Search classrooms by name
  void searchClassrooms(String query) {
    searchQuery.value = query;
    _updateFilteredList();
  }

  // Update filtered list based on search query
  void _updateFilteredList() {
    if (searchQuery.value.isEmpty) {
      filteredClassrooms.assignAll(classrooms);
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredClassrooms.assignAll(
        classrooms.where((classroom) {
          final name = (classroom.name ?? '').toLowerCase();
          return name.contains(query);
        }).toList(),
      );
    }
  }

  // Clear search
  void clearSearch() {
    searchQuery.value = '';
    _updateFilteredList();
  }

  // Reset the controller
  void reset() {
    isLoading.value = false;
    classrooms.clear();
    filteredClassrooms.clear();
    errorMessage.value = '';
    searchQuery.value = '';
  }
}
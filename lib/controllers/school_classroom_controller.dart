import 'package:attendance/api/classroom_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../models/classroom.model.dart';

class SchoolClassroomController extends GetxController {
  final ClassroomService _classroomService = ClassroomService();

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxList<Classrooms> classrooms = <Classrooms>[].obs;
  final RxString errorMessage = ''.obs;

  // Fetch school classrooms using the stored token
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
      print('Error in getSchoolClassrooms: $e'); // Debug log
      errorMessage.value = 'Error fetching classrooms: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Reset the controller
  void reset() {
    isLoading.value = false;
    classrooms.clear();
    errorMessage.value = '';
  }
}
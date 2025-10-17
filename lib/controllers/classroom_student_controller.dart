import 'package:attendance/api/auth.service.dart';
import 'package:attendance/models/student.model.dart';
import 'package:get/get.dart';

class ClassroomStudentController extends GetxController {
  final AuthService _authService = AuthService();

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxList<StudentData> students = <StudentData>[].obs;
  final RxString errorMessage = ''.obs;
  final RxList<StudentData> selectedStudentIds = <StudentData>[].obs; // New: Track selected student IDs
  final RxMap<String, String> parentContacts = <String, String>{}.obs; // New: Store parent contact info

  // Function to fetch students by classroom ID
  Future<void> getStudentsByClassroomId(String classroom) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _authService.fetchStudents(classroom);
      if (result.success!) {
        students.assignAll(result.data ?? []);
      } else {
        errorMessage.value = result.message ?? 'Failed to fetch students';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred while fetching students: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // New: Function to fetch parent contact information for selected students
  // Future<void> fetchParentContacts(List<String> studentIds) async {
  //   try {
  //     isLoading.value = true;
  //     errorMessage.value = '';

  //     for (var studentId in studentIds) {
  //       final response = await _authService.fetchParentContact(studentId);
  //       if (response.success && response.data != null) {
  //         parentContacts[studentId] = response.data!['contact'] ?? '';
  //       } else {
  //         errorMessage.value = 'Failed to fetch parent contact for student $studentId';
  //       }
  //     }
  //   } catch (e) {
  //     errorMessage.value = 'Error fetching parent contacts: $e';
  //   } finally {
  //     isLoading.value = false;
  //   }
  // }

  // // New: Function to toggle student selection
  void toggleStudentSelection(StudentData student, bool isSelected) {
    if (isSelected) {
      selectedStudentIds.add(student);
    } else {
      selectedStudentIds.remove(student);
    }
    selectedStudentIds.refresh();
  }

  // New: Function to select or deselect all students
  void toggleSelectAll(bool selectAll, {String filter = 'all'}) {
    selectedStudentIds.clear();
    if (selectAll) {
      selectedStudentIds.addAll(students
          .where((s) => filter == 'all' ||
              (filter == 'assigned' && s.cardId != "") ||
              (filter == 'unassigned' && s.cardId == ""))
          .map((s) => s));
    }
    selectedStudentIds.refresh();
  }

  // New: Function to get filtered students
  List<StudentData> getFilteredStudents(String filter) {
    if (filter == 'all') {
      return students;
    } else if (filter == 'assigned') {
      return students.where((s) => s.cardId != "").toList();
    } else {
      return students.where((s) => s.cardId == "").toList();
    }
  }

  // Function to get student by card ID
  Future<StudentData?> getStudentByCardId(String classroom, String cardId) async {
    try {
      if (students.isNotEmpty) {
        final student = students.firstWhereOrNull((student) => student.cardId == cardId);
        if (student != null) {
          return student;
        }
      }

      await getStudentsByClassroomId(classroom);
      return students.firstWhereOrNull((student) => student.cardId == cardId);
    } catch (e) {
      errorMessage.value = 'Error finding student by card ID: $e';
      return null;
    }
  }

  // Function to get student by ID
  StudentData? getStudentById(String studentId) {
    try {
      return students.firstWhereOrNull((student) => student.id == studentId);
    } catch (e) {
      errorMessage.value = 'Error getting student by ID: $e';
      return null;
    }
  }

  // Function to check if a student exists by card ID
  bool hasStudentWithCardId(String cardId) {
    return students.any((student) => student.cardId == cardId);
  }

  // Function to reset the controller
  void reset() {
    isLoading.value = false;
    students.clear();
    selectedStudentIds.clear();
    parentContacts.clear();
    errorMessage.value = '';
  }
}
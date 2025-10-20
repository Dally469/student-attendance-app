import 'package:attendance/api/auth.service.dart';
import 'package:attendance/models/student.model.dart';
import 'package:get/get.dart';

class ClassroomStudentController extends GetxController {
  final AuthService _authService = AuthService();

  // Observable variables
  final RxBool isLoading = false.obs;
  final RxList<StudentData> students = <StudentData>[].obs;
  final RxList<StudentData> filteredStudents = <StudentData>[].obs;
  final RxString errorMessage = ''.obs;
  final RxList<StudentData> selectedStudentIds = <StudentData>[].obs;
  final RxMap<String, String> parentContacts = <String, String>{}.obs;
  final RxString searchQuery = ''.obs;
  final RxString currentFilter = 'all'.obs; // Track current filter

  // Helper method to check if student has card
  bool hasCard(StudentData student) {
    return student.cardId != null && 
           student.cardId!.isNotEmpty && 
           student.cardId != "null";
  }

  // Get count of students with cards
  int get studentsWithCard => students.where((s) => hasCard(s)).length;

  // Get count of students without cards
  int get studentsWithoutCard => students.where((s) => !hasCard(s)).length;

  @override
  void onInit() {
    super.onInit();
    // Listen to filter and search changes to update filtered list
    ever(currentFilter, (_) => _updateFilteredList());
    ever(searchQuery, (_) => _updateFilteredList());
    ever(students, (_) => _updateFilteredList());
  }

  // Function to fetch students by classroom ID
  Future<void> getStudentsByClassroomId(String classroom, {bool forceRefresh = false}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await _authService.fetchStudents(classroom);
      if (result.success!) {
        students.assignAll(result.data ?? []);
        // Sort students alphabetically by name
        students.sort((a, b) => 
          (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase())
        );
      } else {
        errorMessage.value = result.message ?? 'Failed to fetch students';
      }
    } catch (e) {
      errorMessage.value = 'An error occurred while fetching students: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // Update a specific student's card assignment
  void updateStudentCard(String studentId, String cardId) {
    final index = students.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      // Create a new student object with updated cardId
      final updatedStudent = students[index];
      updatedStudent.cardId = cardId;
      updatedStudent.isCardAvailable = true;
      
      // Update the student in the list
      students[index] = updatedStudent;
      students.refresh();
      
      // Update filtered list
      _updateFilteredList();
    }
  }

  // Remove card assignment from a student
  void removeStudentCard(String studentId) {
    final index = students.indexWhere((s) => s.id == studentId);
    if (index != -1) {
      final updatedStudent = students[index];
      updatedStudent.cardId = null;
      updatedStudent.isCardAvailable = false;
      
      students[index] = updatedStudent;
      students.refresh();
      
      _updateFilteredList();
    }
  }

  // Search students by name or code
  void searchStudents(String query) {
    searchQuery.value = query;
  }

  // Set filter option
  void setFilter(String filter) {
    currentFilter.value = filter;
  }

  // Update filtered list based on search and filter
  void _updateFilteredList() {
    List<StudentData> tempList = [];

    // Apply filter first
    switch (currentFilter.value) {
      case 'assigned':
        tempList = students.where((s) => hasCard(s)).toList();
        break;
      case 'unassigned':
        tempList = students.where((s) => !hasCard(s)).toList();
        break;
      case 'all':
      default:
        tempList = students.toList();
        break;
    }

    // Apply search if query is not empty
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      tempList = tempList.where((student) {
        final name = (student.name ?? '').toLowerCase();
        final code = (student.code ?? '').toLowerCase();
        return name.contains(query) || code.contains(query);
      }).toList();
    }

    filteredStudents.assignAll(tempList);
  }

  // Clear search
  void clearSearch() {
    searchQuery.value = '';
  }

  // Toggle student selection
  void toggleStudentSelection(StudentData student, bool isSelected) {
    if (isSelected) {
      if (!selectedStudentIds.any((s) => s.id == student.id)) {
        selectedStudentIds.add(student);
      }
    } else {
      selectedStudentIds.removeWhere((s) => s.id == student.id);
    }
    selectedStudentIds.refresh();
  }

  // Check if student is selected
  bool isStudentSelected(String studentId) {
    return selectedStudentIds.any((s) => s.id == studentId);
  }

  // Select or deselect all students
  void toggleSelectAll(bool selectAll) {
    selectedStudentIds.clear();
    if (selectAll) {
      selectedStudentIds.addAll(filteredStudents);
    }
    selectedStudentIds.refresh();
  }

  // Get filtered students (for external use)
  List<StudentData> getFilteredStudents(String filter) {
    switch (filter) {
      case 'assigned':
        return students.where((s) => hasCard(s)).toList();
      case 'unassigned':
        return students.where((s) => !hasCard(s)).toList();
      case 'all':
      default:
        return students.toList();
    }
  }

  // Function to get student by card ID
  Future<StudentData?> getStudentByCardId(String classroom, String cardId) async {
    try {
      if (students.isNotEmpty) {
        final student = students.firstWhereOrNull((student) => 
          student.cardId == cardId && student.cardId != null
        );
        if (student != null) {
          return student;
        }
      }

      await getStudentsByClassroomId(classroom);
      return students.firstWhereOrNull((student) => 
        student.cardId == cardId && student.cardId != null
      );
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
    return students.any((student) => 
      student.cardId == cardId && 
      student.cardId != null && 
      student.cardId!.isNotEmpty
    );
  }

  // Function to reset the controller
  void reset() {
    isLoading.value = false;
    students.clear();
    filteredStudents.clear();
    selectedStudentIds.clear();
    parentContacts.clear();
    searchQuery.value = '';
    currentFilter.value = 'all';
    errorMessage.value = '';
  }
}
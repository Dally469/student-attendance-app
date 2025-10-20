import 'package:attendance/controllers/classroom_student_controller.dart';
import 'package:attendance/routes/routes.names.dart';
import 'package:attendance/utils/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/student.model.dart';

class AssignStudentCard extends StatefulWidget {
  final String? classroomId;
  final String? classroom;
  const AssignStudentCard({super.key, this.classroomId, this.classroom});

  @override
  State<AssignStudentCard> createState() => _AssignStudentCardState();
}

class _AssignStudentCardState extends State<AssignStudentCard> {
  final ClassroomStudentController _studentController = Get.find<ClassroomStudentController>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print("${widget.classroomId ?? 'Unknown ID'} - ${widget.classroom ?? 'Unknown Classroom'}");
    }

    // Reset controller state
    _studentController.reset();
    
    // Fetch students using GetX controller
    _studentController.getStudentsByClassroomId(widget.classroom ?? "");

    // Listen to search query changes
    ever(_studentController.searchQuery, (query) {
      if (_searchController.text != query) {
        _searchController.text = query;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _studentController.clearSearch();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    return true;
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
          toolbarHeight: 100,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Get.toNamed(home);
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.classroom.toString(),
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Obx(() => Text(
                "Total students: ${_studentController.students.length}",
                style: const TextStyle(fontSize: 16, color: Colors.white),
              )),
            ],
          ),
        ),
        body: Obx(() {
          if (_studentController.isLoading.value) {
            return _buildLoadingState();
          } else if (_studentController.students.isNotEmpty) {
            return _buildStudentsList();
          } else {
            return _buildEmptyState();
          }
        }),
        bottomSheet: Container(
          color: whiteColor,
          height: 40,
          child: Center(
            child: Text(
              "Powered by Besoft & BePay ltd",
              style: GoogleFonts.poppins(fontSize: 12, color: blackColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 70.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  'Loading students',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                const SpinKitDoubleBounce(
                  color: primaryColor,
                  size: 50.0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 70.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 2),
              ),
              padding: const EdgeInsets.all(20),
              child: const Icon(
                Icons.inbox,
                size: 48,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Students found',
              style: GoogleFonts.poppins(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _studentController.getStudentsByClassroomId(
                widget.classroom ?? "",
                forceRefresh: true,
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text('Retry', style: GoogleFonts.poppins(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    return RefreshIndicator(
      onRefresh: () async {
        await _studentController.getStudentsByClassroomId(
          widget.classroom ?? "",
          forceRefresh: true,
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              
              // Search Field
              _buildSearchField(),
              const SizedBox(height: 16),

              // Filter controls
              _buildFilterChips(),
              const SizedBox(height: 16),

              // Stats summary
              _buildStatsCards(),
              const SizedBox(height: 16),

              // Result count (when searching)
              _buildResultCount(),

              // Student List
              _buildStudentListView(),
              
              // Bottom padding for bottomSheet
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Obx(() => TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      onChanged: (value) => _studentController.searchStudents(value),
      decoration: InputDecoration(
        hintText: 'Search by name or code...',
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
        prefixIcon: const Icon(Icons.search, color: primaryColor, size: 20),
        suffixIcon: _studentController.searchQuery.value.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  _studentController.clearSearch();
                  _searchController.clear();
                  _searchFocusNode.unfocus();
                },
              )
            : null,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
      style: GoogleFonts.poppins(fontSize: 14),
    ));
  }

  Widget _buildFilterChips() {
    return Obx(() => Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: FilterChip(
            selected: _studentController.currentFilter.value == 'all',
            label: Text('All (${_studentController.students.length})'),
            onSelected: (selected) {
              if (selected) _studentController.setFilter('all');
            },
            backgroundColor: Colors.grey.shade200,
            selectedColor: primaryColor.withOpacity(0.2),
            checkmarkColor: primaryColor,
            labelStyle: GoogleFonts.poppins(fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilterChip(
            selected: _studentController.currentFilter.value == 'assigned',
            label: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: _studentController.currentFilter.value == 'assigned'
                      ? Colors.green
                      : Colors.grey,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Card (${_studentController.studentsWithCard})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            onSelected: (selected) {
              if (selected) _studentController.setFilter('assigned');
            },
            backgroundColor: Colors.grey.shade200,
            selectedColor: Colors.green.withOpacity(0.2),
            checkmarkColor: Colors.green,
            labelStyle: GoogleFonts.poppins(fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilterChip(
            selected: _studentController.currentFilter.value == 'unassigned',
            label: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.credit_card_off,
                  size: 14,
                  color: _studentController.currentFilter.value == 'unassigned'
                      ? Colors.orange
                      : Colors.grey,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'No (${_studentController.studentsWithoutCard})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            onSelected: (selected) {
              if (selected) _studentController.setFilter('unassigned');
            },
            backgroundColor: Colors.grey.shade200,
            selectedColor: Colors.orange.withOpacity(0.2),
            checkmarkColor: Colors.orange,
            labelStyle: GoogleFonts.poppins(fontSize: 12),
          ),
        ),
      ],
    ));
  }

  Widget _buildStatsCards() {
    return Obx(() => Row(
      children: [
        _buildStatCard(
          'Total',
          _studentController.students.length.toString(),
          Icons.people,
          primaryColor,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          'With Card',
          _studentController.studentsWithCard.toString(),
          Icons.credit_card,
          Colors.green,
        ),
        const SizedBox(width: 8),
        _buildStatCard(
          'No Card',
          _studentController.studentsWithoutCard.toString(),
          Icons.credit_card_off,
          Colors.orange,
        ),
      ],
    ));
  }

  Widget _buildResultCount() {
    return Obx(() {
      if (_studentController.searchQuery.value.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Text(
          'Found ${_studentController.filteredStudents.length} student${_studentController.filteredStudents.length != 1 ? 's' : ''}',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    });
  }

  Widget _buildStudentListView() {
    return Obx(() {
      final studentsToShow = _studentController.filteredStudents;

      if (studentsToShow.isEmpty) {
        return _buildNoResultsState();
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: studentsToShow.length,
        itemBuilder: (context, index) {
          final student = studentsToShow[index];
          final hasCard = _studentController.hasCard(student);

          return _buildStudentCard(student, hasCard);
        },
      );
    });
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No students found',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() => Text(
              _studentController.searchQuery.value.isNotEmpty
                  ? 'No students match "${_studentController.searchQuery.value}"'
                  : 'No students in this category',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(StudentData student, bool hasCard) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasCard ? Colors.green.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasCard ? Colors.green.withOpacity(0.3) : Colors.grey.shade300,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Get.toNamed(addCard, parameters: {
            'studentName': student.name.toString(),
            'studentId': student.id.toString(),
            'studentCode': student.code.toString(),
            'classroom': student.classroom.toString(),
            'profileImage': student.profileImage.toString(),
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: primaryColor.withOpacity(0.1),
              backgroundImage: student.profileImage != null && 
                               student.profileImage!.isNotEmpty &&
                               student.profileImage != 'null'
                  ? NetworkImage(student.profileImage!)
                  : null,
              child: student.profileImage == null || 
                     student.profileImage!.isEmpty ||
                     student.profileImage == 'null'
                  ? const Icon(Icons.person, color: primaryColor, size: 28)
                  : null,
            ),
            const SizedBox(width: 14),
            
            // Student Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name ?? 'Unknown',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Code: ${student.code ?? 'N/A'}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Card Status Badge or Button
                  hasCard
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Card Assigned',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : TextButton.icon(
                          onPressed: () {
                            Get.toNamed(addCard, parameters: {
                              'studentName': student.name.toString(),
                              'studentId': student.id.toString(),
                              'studentCode': student.code.toString(),
                              'classroom': student.classroom.toString(),
                              'profileImage': student.profileImage.toString(),
                            });
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: Size.zero,
                          ),
                          icon: const Icon(Icons.credit_card, size: 16),
                          label: Text(
                            "Assign Card",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ],
              ),
            ),
            
            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              count,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
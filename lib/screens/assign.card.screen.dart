import 'package:attendance/controllers/classroom_student_controller.dart';
import 'package:attendance/routes/routes.names.dart';
import 'package:attendance/routes/routes.provider.dart';
import 'package:attendance/utils/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AssignStudentCard extends StatefulWidget {
  final String? classroomId;
  final String? classroom;
  const AssignStudentCard({super.key, this.classroomId, this.classroom});

  @override
  State<AssignStudentCard> createState() => _AssignStudentCardState();
}

class _AssignStudentCardState extends State<AssignStudentCard> {
  final ClassroomStudentController _studentController =
      Get.find<ClassroomStudentController>();

  // Filter option
  final RxString _filterOption = 'all'.obs; // 'all', 'assigned', 'unassigned'

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print(
          "${widget.classroomId ?? 'Unknown ID'} - ${widget.classroom ?? 'Unknown Classroom'}");
    }

    // Fetch students using GetX controller
    _studentController.getStudentsByClassroomId(widget.classroom ?? "");
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
                style:
                    const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
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
                              color: Colors.black),
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
          } else if (_studentController.students.isNotEmpty) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // Filter controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FilterChip(
                          selected: _filterOption.value == 'all',
                          label: const Text('All Students'),
                          onSelected: (selected) {
                            if (selected) {
                              _filterOption.value = 'all';
                            }
                          },
                          backgroundColor: Colors.grey.shade200,
                          selectedColor: primaryColor.withOpacity(0.2),
                          checkmarkColor: primaryColor,
                        ),
                        FilterChip(
                          selected: _filterOption.value == 'assigned',
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  size: 14,
                                  color: _filterOption.value == 'assigned'
                                      ? primaryColor
                                      : Colors.grey),
                              SizedBox(width: 4),
                              Text('With Card'),
                            ],
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              _filterOption.value = 'assigned';
                            }
                          },
                          backgroundColor: Colors.grey.shade200,
                          selectedColor: Colors.green.withOpacity(0.2),
                          checkmarkColor: Colors.green,
                        ),
                        FilterChip(
                          selected: _filterOption.value == 'unassigned',
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.credit_card_off,
                                  size: 14,
                                  color: _filterOption.value == 'unassigned'
                                      ? primaryColor
                                      : Colors.grey),
                              SizedBox(width: 4),
                              Text('No Card'),
                            ],
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              _filterOption.value = 'unassigned';
                            }
                          },
                          backgroundColor: Colors.grey.shade200,
                          selectedColor: primaryColor.withOpacity(0.1),
                          checkmarkColor: primaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stats summary
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: Row(
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
                            _studentController.students
                                .where((s) => s.cardId != "")
                                .length
                                .toString(),
                            Icons.credit_card,
                            Colors.green,
                          ),
                          const SizedBox(width: 8),
                          _buildStatCard(
                            'No Card',
                            _studentController.students
                                .where((s) => s.cardId == "")
                                .length
                                .toString(),
                            Icons.credit_card_off,
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Filtered ListView
                    Obx(() => ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filterOption.value == 'all'
                              ? _studentController.students.length
                              : _filterOption.value == 'assigned'
                                  ? _studentController.students
                                      .where((s) => s.cardId != "")
                                      .length
                                  : _studentController.students
                                      .where((s) => s.cardId == "")
                                      .length,
                          itemBuilder: (context, index) {
                            // Get the appropriate student based on filter
                            final filteredStudents =
                                _filterOption.value == 'all'
                                    ? _studentController.students
                                    : _filterOption.value == 'assigned'
                                        ? _studentController.students
                                            .where((s) => s.cardId != "")
                                            .toList()
                                        : _studentController.students
                                            .where((s) => s.cardId == "")
                                            .toList();

                            final student = filteredStudents[index];

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: student.cardId != ""
                                    ? Colors.green.withOpacity(0.05)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: student.cardId != ""
                                      ? Colors.green.withOpacity(0.3)
                                      : whiteColor1,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 2,
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      primaryColor.withOpacity(0.1),
                                  backgroundImage: student.profileImage != null
                                      ? NetworkImage(student.profileImage!)
                                      : null,
                                  child: student.profileImage == null
                                      ? Icon(Icons.person, color: primaryColor)
                                      : null,
                                ),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${student.name}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: primaryColor,
                                      ),
                                    ),
                                    Text(
                                      'Code: ${student.code}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        student.cardId != ""
                                            ? Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5),
                                                decoration: BoxDecoration(
                                                    color: Colors.green
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                        color: Colors.green
                                                            .withOpacity(0.3))),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.check_circle,
                                                        size: 16,
                                                        color: Colors.green),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Assigned',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 12,
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : TextButton(
                                                onPressed: () {
                                                  Get.toNamed(addCard,
                                                      parameters: {
                                                        'studentName': student
                                                            .name
                                                            .toString(),
                                                        'studentId': student.id
                                                            .toString(),
                                                        'studentCode': student
                                                            .code
                                                            .toString(),
                                                        'classroom': student
                                                            .classroom
                                                            .toString(),
                                                        'profileImage': student
                                                            .profileImage
                                                            .toString(),
                                                      });
                                                },
                                                style: TextButton.styleFrom(
                                                  backgroundColor: primaryColor,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                                child: const Text(
                                                  "Assign Card",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              )
                                      ],
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Get.toNamed(addCard, parameters: {
                                    'studentName': student.name.toString(),
                                    'studentId': student.id.toString(),
                                    'studentCode': student.code.toString(),
                                    'classroom': student.classroom.toString(),
                                    'profileImage':
                                        student.profileImage.toString(),
                                  });
                                },
                              ),
                            );
                          },
                        )),
                  ],
                ),
              ),
            );
          } else {
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
                  ],
                ),
              ),
            );
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

  // Helper method to build stat cards
  Widget _buildStatCard(
      String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

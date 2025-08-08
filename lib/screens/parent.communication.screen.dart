import 'package:attendance/controllers/classroom_student_controller.dart';
import 'package:attendance/controllers/parent_communication_controller.dart';
import 'package:attendance/routes/routes.names.dart';
import 'package:attendance/routes/routes.provider.dart';
import 'package:attendance/utils/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/student.model.dart';

class ParentCommunication extends StatefulWidget {
  final String? classroomId;
  final String? classroom;
  const ParentCommunication({super.key, this.classroomId, this.classroom});

  @override
  State<ParentCommunication> createState() => _ParentCommunicationState();
}

class _ParentCommunicationState extends State<ParentCommunication>
    with SingleTickerProviderStateMixin {
  final ClassroomStudentController _studentController =
      Get.find<ClassroomStudentController>();
  final ParentCommunicationController _communicationController =
      Get.find<ParentCommunicationController>();
  final RxString _filterOption = 'all'.obs;
  late AnimationController _animationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print(
          "${widget.classroomId ?? 'Unknown ID'} - ${widget.classroom ?? 'Unknown Classroom'}");
    }
    _studentController.getStudentsByClassroomId(widget.classroom ?? "");
    _communicationController.fetchRecipients(widget.classroomId ?? "");

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // // Snackbar logic with mounted check
    // ever(_communicationController.successMessage, (message) {
    //   if (message.isNotEmpty && mounted) {
    //     WidgetsBinding.instance.addPostFrameCallback((_) {
    //       Get.snackbar('Success', message, backgroundColor: Colors.green, colorText: Colors.white);
    //     });
    //   }
    // });

    // ever(_communicationController.errorMessage, (message) {
    //   if (message.isNotEmpty && mounted) {
    //     WidgetsBinding.instance.addPostFrameCallback((_) {
    //       Get.snackbar('Error', message, backgroundColor: Colors.red, colorText: Colors.white);
    //     });
    //   }
    // });

    ever(_studentController.selectedStudentIds, (_) {
      if (mounted) {
        if (kDebugMode) {
          print(
              "Selected student IDs updated: ${_studentController.selectedStudentIds}");
        }
        if (_studentController.selectedStudentIds.isNotEmpty) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      }
    });

    // Listen to filter changes to clear selections if needed
    ever(_filterOption, (_) {
      // Clear selections when filter changes to avoid stale IDs
      _studentController.toggleSelectAll(false, filter: _filterOption.value);
      if (kDebugMode) {
        print("Filter changed to: ${_filterOption.value}, cleared selections");
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async => true;

  void _showComposeMessageSheet() {
    // _studentController.fetchParentContacts(_studentController.selectedStudentIds);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ComposeMessageSheet(
        classroomId: widget.classroomId ?? "",
        selectedStudentIds: _studentController.selectedStudentIds,
        communicationController: _communicationController,
        studentController: _studentController,
      ),
    );
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
          toolbarHeight: 80,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Get.toNamed(home),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.classroom.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Obx(() => Text(
                    "Total students: ${_studentController.students.length}",
                    style: GoogleFonts.poppins(
                        fontSize: 14, color: Colors.white70),
                  )),
            ],
          ),
        ),
        floatingActionButton:
            Obx(() => _studentController.selectedStudentIds.isNotEmpty
                ? ScaleTransition(
                    scale: _fabAnimation,
                    child: FloatingActionButton.extended(
                      onPressed: _showComposeMessageSheet,
                      backgroundColor: primaryColor,
                      label: Text(
                        'Compose Message',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      icon: const Icon(Icons.message, color: Colors.white),
                    ),
                  )
                : const SizedBox.shrink()),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: Obx(() {
          if (_studentController.isLoading.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SpinKitDoubleBounce(color: primaryColor, size: 50.0),
                  const SizedBox(height: 20),
                  Text(
                    'Loading students...',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w400),
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
                    Text(
                      "Parents Communication",
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Obx(() {
                          final filteredStudents = _studentController
                              .getFilteredStudents(_filterOption.value);
                          final allSelected = filteredStudents.isNotEmpty &&
                              _studentController.selectedStudentIds.length ==
                                  filteredStudents.length &&
                              filteredStudents.every((student) =>
                                  _studentController.selectedStudentIds
                                      .contains(student.id.toString()));
                          return Checkbox(
                            value: allSelected,
                            onChanged: (value) {
                              _studentController.toggleSelectAll(value ?? false,
                                  filter: _filterOption.value);
                              if (kDebugMode) {
                                print(
                                    "Select All toggled: $value, filter: ${_filterOption.value}");
                              }
                            },
                            activeColor: primaryColor,
                          );
                        }),
                        Text(
                          "Select All Students",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      final filteredStudents = _studentController
                          .getFilteredStudents(_filterOption.value);
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _studentController.selectedStudentIds
                                        .contains(student.id.toString())
                                    ? primaryColor.withOpacity(0.5)
                                    : Colors.grey.shade200,
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
                                backgroundColor: primaryColor.withOpacity(0.1),
                                backgroundImage: student.profileImage != null
                                    ? NetworkImage(student.profileImage!)
                                    : null,
                                child: student.profileImage == null
                                    ? Icon(Icons.person, color: primaryColor)
                                    : null,
                              ),
                              title: Text(
                                student.name ?? 'Unknown',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: blackColor,
                                ),
                              ),
                              subtitle: Text(
                                'Parent Contact: ${student.parentContact} \nCode: ${student.code}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: Obx(() => Checkbox(
                                    value: _studentController.selectedStudentIds
                                        .contains(student),
                                    onChanged: (value) {
                                      _studentController.toggleStudentSelection(
                                          student, value ?? false);
                                      if (kDebugMode) {
                                        print(
                                            "Checkbox toggled for student ${student.id}: $value");
                                      }
                                    },
                                    activeColor: primaryColor,
                                  )),
                              onTap: () {
                                final isSelected = !_studentController
                                    .selectedStudentIds
                                    .contains(student);
                                _studentController.toggleStudentSelection(
                                    student, isSelected);
                                if (kDebugMode) {
                                  print(
                                      "ListTile tapped for student ${student.id}: $isSelected");
                                }
                              },
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey, width: 2),
                    ),
                    padding: const EdgeInsets.all(20),
                    child:
                        const Icon(Icons.inbox, size: 48, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Students found',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }
        }),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
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

class _ComposeMessageSheet extends StatefulWidget {
  final String classroomId;
  final RxList<StudentData> selectedStudentIds;
  final ParentCommunicationController communicationController;
  final ClassroomStudentController studentController;

  const _ComposeMessageSheet({
    required this.classroomId,
    required this.selectedStudentIds,
    required this.communicationController,
    required this.studentController,
  });

  @override
  _ComposeMessageSheetState createState() => _ComposeMessageSheetState();
}

class _ComposeMessageSheetState extends State<_ComposeMessageSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isPreviewVisible = false; // Track preview visibility

  // Track which placeholders are used
  bool get _isStudentNameUsed =>
      _messageController.text.contains('{{student_name}}');
  bool get _isSchoolUsed => _messageController.text.contains('{{school}}');
  bool get _isClassroomUsed =>
      _messageController.text.contains('{{classroom}}');

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Listen to text changes to update preview and chip states
    _messageController.addListener(() {
      setState(() {}); // Trigger rebuild to update preview and chip states
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Insert placeholder into the TextFormField at the current cursor position
  void _insertPlaceholder(String placeholder) {
    final text = _messageController.text;
    final textSelection = _messageController.selection;
    final newText = text.replaceRange(
      textSelection.start,
      textSelection.end,
      placeholder,
    );
    _messageController.text = newText;
    _messageController.selection = TextSelection.collapsed(
      offset: textSelection.start + placeholder.length,
    );
  }

  // Generate preview messages for up to 3 students
  List<String> _generatePreviews() {
    final message = _messageController.text.trim().isEmpty
        ? 'Type your message here (e.g., Hello Dear parent {{student_name}} at {{school}}, your child in {{classroom}} has an upcoming event...)'
        : _messageController.text.trim();
    final previews = <String>[];
    final students = widget.selectedStudentIds.take(3).toList(); // Limit to 3
    for (var student in students) {
      String preview = message;
      preview =
          preview.replaceAll('{{student_name}}', student.name ?? 'Student');
      preview = preview.replaceAll('{{school}}', student.school ?? 'School');
      preview =
          preview.replaceAll('{{classroom}}', student.classroom ?? 'Classroom');
      previews.add(preview);
    }
    return previews;
  }

  // Build a placeholder chip
  Widget _buildPlaceholderChip(String placeholder, bool isUsed) {
    return ActionChip(
      label: Text(
        placeholder,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isUsed ? Colors.grey[900] : primaryColor,
        ),
      ),
      onPressed: isUsed ? null : () => _insertPlaceholder(placeholder),
      backgroundColor: isUsed ? Colors.grey[300] : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isUsed ? Colors.grey[400]! : primaryColorOverlay,
          width: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compose Message',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: blackColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a message to ${widget.selectedStudentIds.length} selected ${widget.selectedStudentIds.length == 1 ? 'student' : 'students'}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap below to insert placeholders (used placeholders are disabled):',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildPlaceholderChip(
                                '{{student_name}}', _isStudentNameUsed),
                            _buildPlaceholderChip('{{school}}', _isSchoolUsed),
                            _buildPlaceholderChip(
                                '{{classroom}}', _isClassroomUsed),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _messageController,
                          maxLines: 10,
                          decoration: InputDecoration(
                            hintText:
                                'Type your message here (e.g., Hello Dear parent {{student_name}} at {{school}}, your child in {{classroom}} has an upcoming event...)',
                            hintStyle:
                                GoogleFonts.poppins(color: Colors.grey[500]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: greyColor1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: primaryColor, width: 2),
                            ),
                          ),
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Message Preview (First 3 Recipients):',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: blackColor,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isPreviewVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: primaryColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPreviewVisible = !_isPreviewVisible;
                                });
                              },
                              tooltip: _isPreviewVisible
                                  ? 'Hide Preview'
                                  : 'Show Preview',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_isPreviewVisible)
                          widget.selectedStudentIds.isEmpty
                              ? Text(
                                  'Select students to see a preview.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey[600],
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _generatePreviews()
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: Container(
                                        padding: const EdgeInsets.all(12.0),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          entry.value,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: blackColor,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.studentController.toggleSelectAll(false);
                              },
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Obx(() => widget
                                    .communicationController.isLoading.value
                                ? CircularProgressIndicator(color: primaryColor)
                                : ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: whiteColor,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                    onPressed: () async {
                                      if (_messageController.text
                                          .trim()
                                          .isNotEmpty) {
                                        for (var student
                                            in widget.selectedStudentIds) {
                                          var parentContact = widget
                                              .studentController
                                              .parentContacts
                                              .entries
                                              .firstWhere(
                                            (entry) => entry.key == student.id,
                                            orElse: () => MapEntry('', ''),
                                          );
                                          if (parentContact.key.isNotEmpty) {
                                            await widget.communicationController
                                                .sendCommunication(
                                              classroomId: widget.classroomId,
                                              message: _messageController.text
                                                  .trim(),
                                              recipientIds: [
                                                parentContact.value
                                              ],
                                              studentId: student.id,
                                              isClassLevel: false,
                                            );
                                          }
                                        }
                                        if (mounted) {
                                          Navigator.pop(context);
                                          widget.studentController
                                              .toggleSelectAll(false);
                                        }
                                      } else {
                                        if (mounted) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {});
                                        }
                                      }
                                    },
                                    child: Text(
                                      'Send Message',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: whiteColor,
                                      ),
                                    ),
                                  )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

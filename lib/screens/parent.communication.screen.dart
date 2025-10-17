import 'dart:convert';

import 'package:attendance/controllers/classroom_student_controller.dart';
import 'package:attendance/controllers/parent_communication_controller.dart';
import 'package:attendance/controllers/sms.controller.dart';
import 'package:attendance/routes/routes.names.dart';
import 'package:attendance/utils/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../models/student.model.dart';

class ParentCommunication extends StatefulWidget {
  final String? classroomId;
  final String? classroom;
  const ParentCommunication({super.key, this.classroomId, this.classroom});

  @override
  State<ParentCommunication> createState() => _ParentCommunicationState();
}

class _ParentCommunicationState extends State<ParentCommunication> {
  final ClassroomStudentController _studentController =
      Get.find<ClassroomStudentController>();
      final SMSController _smsController = Get.find<SMSController>();
  final ParentCommunicationController _communicationController =
      Get.find<ParentCommunicationController>();
  final RxString _filterOption = 'all'.obs;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print(
          "${widget.classroomId ?? 'Unknown ID'} - ${widget.classroom ?? 'Unknown Classroom'}");
    }
    _studentController.getStudentsByClassroomId(widget.classroom ?? "");
  getCurrentUserInfo();

    // Listen to filter changes to clear selections
    ever(_filterOption, (_) {
      _studentController.toggleSelectAll(false, filter: _filterOption.value);
      if (kDebugMode) {
        print("Filter changed to: ${_filterOption.value}, cleared selections");
      }
    });
  }

    Future<void> getCurrentUserInfo() async {
    try {
      _smsController.isLoading.value = true;
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      String? userJson = sharedPreferences.getString("currentUser");
      if (userJson != null) {
        Map<String, dynamic> userMap = jsonDecode(userJson);
        setState(() {
          if (userMap.containsKey('school') && userMap['school'] != null) {
        
            _smsController.schoolId = userMap['school']['id'];
          }
        });
        debugPrint("School ID: ${userMap['school']['id']}");
        await _smsController.getSMSBalance();
      }
    } catch (e) {
      debugPrint('Error getting user info: $e');
      _smsController.errorMessage.value = 'Error getting user info: $e';
    } finally {
      _smsController.isLoading.value = false;
    }
  }

  Future<bool> _onWillPop() async => true;

  void _showMessageTypeSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MessageTypeSheet(
        onSelect: (isWhatsApp) {
          Navigator.pop(context); // Close message type sheet
          _showComposeMessageSheet(isWhatsApp: isWhatsApp);
        },
      ),
    );
  }

  void _showComposeMessageSheet({required bool isWhatsApp}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ComposeMessageSheet(
        classroomId: widget.classroomId ?? "",
        selectedStudentIds: _studentController.selectedStudentIds,
        communicationController: _communicationController,
        studentController: _studentController,
        isWhatsApp: isWhatsApp,
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
        floatingActionButton: Obx(() {
          if (_studentController.selectedStudentIds.isEmpty) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            onPressed: _showMessageTypeSheet,
            backgroundColor: primaryColor,
            child: const Icon(Icons.message, color: Colors.white),
            heroTag: 'message_fab',
          );
        }),
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
                    Obx(() {
                      final filteredStudents = _studentController
                          .getFilteredStudents(_filterOption.value);
                      final selectedCount =
                          _studentController.selectedStudentIds.length;
                      final unselectedCount =
                          filteredStudents.length - selectedCount;
                      final allSelected = filteredStudents.isNotEmpty &&
                          selectedCount == filteredStudents.length;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: allSelected,
                                onChanged: (value) {
                                  _studentController.toggleSelectAll(
                                      value ?? false,
                                      filter: _filterOption.value);
                                  if (kDebugMode) {
                                    print(
                                        "Select All toggled: $value, filter: ${_filterOption.value}");
                                  }
                                },
                                activeColor: primaryColor,
                              ),
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
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 18.0),
                            child: Text(
                              "Selected: $selectedCount | Not Selected: $unselectedCount",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
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
                                    .contains(student.id.toString());
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
}

// Message type selection bottom sheet
class _MessageTypeSheet extends StatelessWidget {
  final Function(bool) onSelect;

  const _MessageTypeSheet({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Message Type',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: blackColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => onSelect(true),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade400,
                                  Colors.green.shade600
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.message,
                                    color: Colors.white, size: 28),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'WhatsApp Message',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'Send a message or media via WhatsApp',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white70,
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
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => onSelect(false),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor,
                                  primaryColor.withOpacity(0.8)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.sms, color: Colors.white, size: 28),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SMS Message',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'Send a text message via SMS',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.white70,
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
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _ComposeMessageSheet extends StatefulWidget {
  final String classroomId;
  final RxList<StudentData> selectedStudentIds;
  final ParentCommunicationController communicationController;
  final ClassroomStudentController studentController;
  final bool isWhatsApp;

  const _ComposeMessageSheet({
    required this.classroomId,
    required this.selectedStudentIds,
    required this.communicationController,
    required this.studentController,
    required this.isWhatsApp,
  });

  @override
  _ComposeMessageSheetState createState() => _ComposeMessageSheetState();
}

class _ComposeMessageSheetState extends State<_ComposeMessageSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isPreviewVisible = false;
  late FocusNode _messageFocusNode;
  File? _selectedFile;
  String? _fileType; // 'image' or 'document'

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
    _messageFocusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_messageFocusNode);
    });

    _messageController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _animationController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      if (result.files.single.size > 10 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File size exceeds 10MB limit')),
        );
        return;
      }
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileType =
            result.files.single.extension == 'pdf' ? 'document' : 'image';
      });
    }
  }

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

  List<String> _generatePreviews() {
    final message = _messageController.text.trim().isEmpty
        ? 'Type your message here (e.g., Hello Dear parent {{student_name}} at {{school}}, your child in {{classroom}} has an upcoming event...)'
        : _messageController.text.trim();
    final previews = <String>[];
    final students = widget.selectedStudentIds.take(3).toList();
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
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
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
                            borderRadius: BorderRadius.circular(10),
                          ),
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
                          widget.isWhatsApp
                              ? 'Compose WhatsApp Message'
                              : 'Compose Message',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: blackColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a ${widget.isWhatsApp ? 'WhatsApp' : 'SMS'} message to ${widget.selectedStudentIds.length} selected ${widget.selectedStudentIds.length == 1 ? 'student' : 'students'}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Visibility(
                          visible: false,
                          child: Column(
                            children: [
                              Text(
                                'Upload an image or document (optional):',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _pickFile,
                                    icon: const Icon(Icons.upload_file,
                                        color: Colors.white),
                                    label: Text(
                                      'Pick File',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  if (_selectedFile != null)
                                    Expanded(
                                      child: Text(
                                        'Selected: ${_selectedFile!.path.split('/').last}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        overflow: TextOverflow.ellipsis, 
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
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
                          focusNode: _messageFocusNode,
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
                                      backgroundColor: widget.isWhatsApp
                                          ? Colors.green
                                          : primaryColor,
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
                                          .isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'Please enter a message')),
                                        );
                                        return;
                                      }
                                      bool success = false;
                                      if (widget.isWhatsApp) {
                                        if (_selectedFile != null) {
                                          String? fileUrl = await widget
                                              .communicationController
                                              .uploadFileToFirebase(
                                                  _selectedFile!,
                                                  _selectedFile!.path
                                                      .split('/')
                                                      .last);
                                          if (fileUrl == null) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content: Text(
                                                      'Failed to upload file')),
                                            );
                                            return;
                                          }
                                          if (_fileType == 'image') {
                                            success = await widget
                                                .communicationController
                                                .sendWhatsAppImage(
                                              classroomId: widget.classroomId,
                                              caption: _messageController.text
                                                  .trim(),
                                              imageUrl: fileUrl,
                                              students:
                                                  widget.selectedStudentIds,
                                            );
                                          } else if (_fileType == 'document') {
                                            success = await widget
                                                .communicationController
                                                .sendWhatsAppDocument(
                                              classroomId: widget.classroomId,
                                              caption: _messageController.text
                                                  .trim(),
                                              documentUrl: fileUrl,
                                              documentName: _selectedFile!.path
                                                  .split('/')
                                                  .last,
                                              students:
                                                  widget.selectedStudentIds,
                                            );
                                          }
                                        } else {
                                          success = await widget
                                              .communicationController
                                              .sendBulkWhatsApp(
                                            message:
                                                _messageController.text.trim(),
                                            students: widget.selectedStudentIds,
                                          );
                                        }
                                      } else {
                                        success = await widget
                                            .communicationController
                                            .sendBulkSms(
                                          classroomId: widget.classroomId,
                                          message:
                                              _messageController.text.trim(),
                                          students: widget.selectedStudentIds,
                                        );
                                      }
                                      // if (success && mounted) {
                                      //   Navigator.pop(context);

                                      // }

                                      widget.studentController
                                          .toggleSelectAll(false);
                                    },
                                    child: Text(
                                      widget.isWhatsApp
                                          ? 'Send WhatsApp'
                                          : 'Send Message',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: whiteColor,
                                      ),
                                    ),
                                  )),
                          ],
                        ),
                        Obx(() {
                          if (widget.communicationController.errorMessage.value
                              .isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                widget
                                    .communicationController.errorMessage.value,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                            );
                          }
                          if (widget.communicationController.successMessage
                              .value.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                widget.communicationController.successMessage
                                    .value,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.green,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
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

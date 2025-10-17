import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:attendance/controllers/classroom_student_controller.dart';
import 'package:attendance/controllers/parent_communication_controller.dart';
import 'package:attendance/controllers/sms.controller.dart';
import 'package:attendance/routes/routes.names.dart';
import 'package:attendance/utils/colors.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import '../api/facial.service.dart';
import '../models/student.model.dart';

class EnhancedAssignFacialData extends StatefulWidget {
  final String? classroomId;
  final String? classroom;
  const EnhancedAssignFacialData({super.key, this.classroomId, this.classroom});

  @override
  State<EnhancedAssignFacialData> createState() => _EnhancedAssignFacialDataState();
}

class _EnhancedAssignFacialDataState extends State<EnhancedAssignFacialData> {
  final ClassroomStudentController _studentController = Get.find<ClassroomStudentController>();
  final SMSController _smsController = Get.find<SMSController>();
   final FacialService _facialService = Get.find<FacialService>();
  final RxString _filterOption = 'all'.obs;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      print("${widget.classroomId ?? 'Unknown ID'} - ${widget.classroom ?? 'Unknown Classroom'}");
    }
    _studentController.getStudentsByClassroomId(widget.classroom ?? "");
    getCurrentUserInfo();

  ever(_filterOption, (value) {
  _studentController.toggleSelectAll(false, filter: value);
  if (kDebugMode) {
    print("Filter changed to: $value, cleared selections");
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

  void _showAdvancedFacialCaptureSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) => AdvancedFacialCaptureSheet(
        selectedStudents: _studentController.selectedStudentIds,
        facialService: _facialService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Enhanced App Bar
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor,
                      primaryColor.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.classroom.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Obx(() => Text(
                        "Total students: ${_studentController.students.length}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      )),
                ],
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Get.toNamed(home),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Obx(() {
              if (_studentController.isLoading.value) {
                return Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 5,
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const SpinKitWanderingCubes(
                            color: primaryColor,
                            size: 50.0,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'Loading students...',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (_studentController.students.isNotEmpty) {
                return _buildStudentsList();
              } else {
                return _buildEmptyState();
              }
            }),
          ),
        ],
      ),
      floatingActionButton: Obx(() {
        if (_studentController.selectedStudentIds.isEmpty) {
          return const SizedBox.shrink();
        }
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                spreadRadius: 3,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: FloatingActionButton.extended(
            onPressed: _showAdvancedFacialCaptureSheet,
            backgroundColor: Colors.transparent,
            elevation: 0,
            icon: const Icon(Icons.face_retouching_natural, color: Colors.white),
            label: Text(
              'Assign Face (${_studentController.selectedStudentIds.length})',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        );
      }),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStudentsList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with enhanced styling
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade50, Colors.blue.shade50],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.face_retouching_natural, 
                        color: Colors.green.shade700, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "ASSIGN STUDENT FACE DATA",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Select students and capture their facial data for secure attendance tracking",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          // Enhanced selection controls
          Obx(() {
            final filteredStudents = _studentController.getFilteredStudents(_filterOption.value);
            final selectedCount = _studentController.selectedStudentIds.length;
            final unselectedCount = filteredStudents.length - selectedCount;
            final allSelected = filteredStudents.isNotEmpty && selectedCount == filteredStudents.length;
            
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Transform.scale(
                        scale: 1.2,
                        child: Checkbox(
                          value: allSelected,
                          onChanged: (value) {
                            _studentController.toggleSelectAll(
                                value ?? false,
                                filter: _filterOption.value);
                          },
                          activeColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Select All Students",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                "Selected: $selectedCount",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.pending, color: Colors.orange.shade600, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                "Pending: $unselectedCount",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 20),

          // Enhanced student list
          Obx(() {
            final filteredStudents = _studentController.getFilteredStudents(_filterOption.value);
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final student = filteredStudents[index];
                final isSelected = _studentController.selectedStudentIds.contains(student.id.toString());
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected 
                          ? primaryColor.withOpacity(0.1) 
                          : Colors.grey.withOpacity(0.05),
                        spreadRadius: isSelected ? 2 : 1,
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        final newSelection = !isSelected;
                        _studentController.toggleStudentSelection(student, newSelection);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Student Avatar
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    primaryColor.withOpacity(0.8),
                                    primaryColor,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  (student.name ?? 'U').substring(0, 1).toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Student Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name ?? 'Unknown Student',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Code: ${student.code}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Selection Indicator
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? primaryColor : Colors.grey.shade400,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          
          const SizedBox(height: 100), // Extra space for FAB
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200, width: 2),
              ),
              child: Icon(
                Icons.school_outlined,
                size: 60,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Students Found',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no students in this classroom yet.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced Advanced Facial Capture Sheet
// Enhanced Advanced Facial Capture Sheet
class AdvancedFacialCaptureSheet extends StatefulWidget {
  final List<StudentData> selectedStudents;
  final FacialService facialService;

  const AdvancedFacialCaptureSheet({
    Key? key,
    required this.selectedStudents,
    required this.facialService,
  }) : super(key: key);

  @override
  _AdvancedFacialCaptureSheetState createState() => _AdvancedFacialCaptureSheetState();
}

class _AdvancedFacialCaptureSheetState extends State<AdvancedFacialCaptureSheet>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  String? _selectedStudentId;
  String? _errorMessage;
  String? _successMessage;

  // Face detection using ML Kit
  FaceDetector? _faceDetector;
  bool _faceDetected = false;
  bool _faceInPosition = false;
  bool _faceTooClose = false;
  bool _faceTooFar = false;
  bool _faceNotCentered = false;
  bool _lightingGood = false;
  double _faceConfidence = 0.0;
  Timer? _faceDetectionTimer;

  // Enhanced face analysis
  bool _eyesOpen = true;
  bool _straightHead = true;
  Size? _faceSize;
  Offset? _faceCenter;

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _statusController;
  late Animation<Color?> _statusColorAnimation;

  // Capture states
  bool _isCapturing = false;
  File? _capturedImage;
  bool _showPreview = false;
  int _captureCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initializeFaceDetector();
    _initializeCamera();
    _initializeAnimations();
    _lockOrientation();
  }

  void _initializeFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false,
        enableClassification: true,
        enableLandmarks: true,
        enableTracking: false,
        minFaceSize: 0.2,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  void _lockOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  void _unlockOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  
  Future<DeviceOrientation> _getPreferredOrientation() async {
    // Get device orientation to properly handle camera preview
    try {
      // Default to portrait
      DeviceOrientation orientation = DeviceOrientation.portraitUp;
      
      // Check if we're using a back camera
      if (_cameraController?.description.lensDirection == CameraLensDirection.back) {
        // For back camera with 270 degree rotation, we need to adjust the orientation
        orientation = DeviceOrientation.landscapeLeft;
        debugPrint('Setting preferred orientation to landscape for back camera');
      }
      
      return orientation;
    } catch (e) {
      debugPrint('Error determining orientation: $e');
      return DeviceOrientation.portraitUp; // Default fallback
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _statusController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _statusColorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.green,
    ).animate(_statusController);

    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeCamera() async {
    try {
      debugPrint('=== ENHANCED CAMERA INITIALIZATION START ===');
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        _setError('No cameras available on this device');
        return;
      }

      // Prefer front camera for better face capture experience
      CameraDescription selectedCamera;
      try {
        selectedCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
            orElse: () => _cameras!.first,
          ),
        );
      } catch (e) {
        _setError('Failed to select camera: $e');
        return;
      }

      // Set the correct sensor orientation based on camera type
      int sensorOrientation = selectedCamera.sensorOrientation;
      // For back camera, explicitly set to 270 degrees as required
      if (selectedCamera.lensDirection == CameraLensDirection.back) {
        sensorOrientation = 360;
        debugPrint('Back camera detected, forcing 270 degree rotation');
      }
      debugPrint('Camera sensor orientation set to: $sensorOrientation degrees');

      // Create camera controller with explicit orientation settings
      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      // Store the camera orientation for use in other methods
      final deviceOrientation = await _getPreferredOrientation();
      debugPrint('Device orientation: $deviceOrientation');

      await _cameraController!.initialize();

      // Enhanced camera settings for better image quality
      await _cameraController!.setFocusMode(FocusMode.auto);
      await _cameraController!.setExposureMode(ExposureMode.auto);
      await _cameraController!.setFlashMode(FlashMode.auto);

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _errorMessage = null;
        });
        _startRealTimeFaceDetection();
      }
    } catch (e) {
      _setError('Failed to initialize camera: $e');
    }
  }

  void _setError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
      });
    }
    debugPrint('Camera Error: $message');
  }

  void _startRealTimeFaceDetection() {
    _faceDetectionTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) async {
      if (!mounted || _cameraController == null || !_cameraController!.value.isInitialized) {
        timer.cancel();
        return;
      }
      await _performAdvancedFaceDetection();
    });
  }

  Future<void> _performAdvancedFaceDetection() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        return;
      }
      
      // Take a picture with appropriate quality for face detection
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      
      // Process with face detector
      final faces = await _faceDetector!.processImage(inputImage);
      
      // Check if component is still mounted
      if (!mounted) {
        await File(image.path).delete();
        return;
      }
      
      // Handle multiple faces if detected
      if (faces.length > 1) {
        debugPrint('Multiple faces detected (${faces.length}), selecting the largest one');
        // Sort faces by size (largest first)
        faces.sort((a, b) => (b.boundingBox.width * b.boundingBox.height)
            .compareTo(a.boundingBox.width * a.boundingBox.height));
      }
      
      setState(() {
        _faceDetected = faces.isNotEmpty;
        
        if (faces.isNotEmpty) {
          final face = faces.first;
          _analyzeAdvancedFaceProperties(face);
          
          // Additional logging for debugging
          debugPrint('Face detected: confidence=${face.trackingId ?? 'unknown'}, ' +
                    'eyes: L=${face.leftEyeOpenProbability?.toStringAsFixed(2) ?? 'unknown'}, ' +
                    'R=${face.rightEyeOpenProbability?.toStringAsFixed(2) ?? 'unknown'}, ' +
                    'pose: Y=${face.headEulerAngleY?.toStringAsFixed(1) ?? 'unknown'}, ' +
                    'Z=${face.headEulerAngleZ?.toStringAsFixed(1) ?? 'unknown'}');
        } else {
          _resetFaceProperties();
          debugPrint('No faces detected in frame');
        }
      });
      
      // Update status color animation based on face position
      if (_faceInPosition) {
        _statusController.forward();
      } else {
        _statusController.reverse();
      }

      // Clean up temporary image
      await File(image.path).delete();
    } catch (e) {
      debugPrint('Face detection error: $e');
      // Reset properties on error to avoid UI getting stuck
      if (mounted) {
        setState(() {
          _resetFaceProperties();
        });
      }
    }
  }

  void _analyzeAdvancedFaceProperties(Face face) {
    final boundingBox = face.boundingBox;
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate face metrics
    _faceSize = boundingBox.size;
    _faceCenter = boundingBox.center;
    
    // Enhanced face analysis with improved parameters
    final faceWidth = boundingBox.width;
    final faceHeight = boundingBox.height;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final faceAspectRatio = faceWidth / faceHeight;
    
    // Face size analysis with improved thresholds
    // For back camera with 270 degree rotation, adjust the thresholds
    bool isBackCamera = _cameraController?.description.lensDirection == CameraLensDirection.back;
    
    // Adjust thresholds based on camera type
    double maxWidthRatio = isBackCamera ? 0.50 : 0.45;
    double minWidthRatio = isBackCamera ? 0.18 : 0.20;
    
    _faceTooClose = faceWidth > screenWidth * maxWidthRatio;
    _faceTooFar = faceWidth < screenWidth * minWidthRatio;
    
    // Check for distorted face aspect ratio (should be roughly 0.8-1.2)
    bool faceDistorted = faceAspectRatio < 0.7 || faceAspectRatio > 1.3;
    
    // Face centering with dynamic threshold based on face size
    // Larger faces need less precise centering
    final centerX = screenWidth / 2;
    final centerY = screenHeight / 2;
    final faceX = boundingBox.center.dx;
    final faceY = boundingBox.center.dy;
    
    // Calculate normalized distance from center (0.0 = center, 1.0 = edge)
    final normalizedDistanceX = (faceX - centerX).abs() / (screenWidth / 2);
    final normalizedDistanceY = (faceY - centerY).abs() / (screenHeight / 2);
    
    // Allow larger faces to be further from center
    final sizeAdjustedThreshold = 0.25 - (faceWidth / screenWidth * 0.2).clamp(0.0, 0.15);
    _faceNotCentered = normalizedDistanceX > sizeAdjustedThreshold || 
                       normalizedDistanceY > sizeAdjustedThreshold;
    
    // Head pose analysis with improved thresholds
    final headEulerAngleY = face.headEulerAngleY ?? 0;
    final headEulerAngleZ = face.headEulerAngleZ ?? 0;
    final headEulerAngleX = face.headEulerAngleX ?? 0; // Also check X angle for tilt
    
    // Different thresholds for different angles
    _straightHead = headEulerAngleY.abs() < 18 && 
                   headEulerAngleZ.abs() < 18 &&
                   headEulerAngleX.abs() < 20;
    
    // Eye analysis with improved threshold
    final leftEyeOpen = face.leftEyeOpenProbability ?? 0;
    final rightEyeOpen = face.rightEyeOpenProbability ?? 0;
    _eyesOpen = leftEyeOpen > 0.4 && rightEyeOpen > 0.4;
    
    // Attempt to analyze lighting based on face landmarks if available
    _lightingGood = true; // Default to true
    
    // If we have face contours, try to estimate lighting quality
    if (face.contours.isNotEmpty) {
      try {
        // This is a simplified lighting estimation
        // In a real app, you'd use more sophisticated techniques
        _lightingGood = true;
      } catch (e) {
        debugPrint('Error estimating lighting: $e');
      }
    }
    
    // Overall confidence calculation with weighted factors
    double confidence = 1.0;
    
    // Size factors (most important)
    if (_faceTooClose) confidence -= 0.35;
    if (_faceTooFar) confidence -= 0.35;
    
    // Position factors
    if (_faceNotCentered) confidence -= 0.25;
    
    // Quality factors
    if (!_straightHead) confidence -= 0.2;
    if (!_eyesOpen) confidence -= 0.25;
    if (faceDistorted) confidence -= 0.2;
    if (!_lightingGood) confidence -= 0.15;
    
    // Ensure confidence is in valid range
    _faceConfidence = confidence.clamp(0.0, 1.0);
    
    // Face is in position if confidence exceeds threshold
    // Use a slightly lower threshold for back camera
    double confidenceThreshold = isBackCamera ? 0.65 : 0.7;
    _faceInPosition = _faceConfidence > confidenceThreshold;
    
    // Log detailed analysis for debugging
    debugPrint('Face analysis: size=${faceWidth.toInt()}x${faceHeight.toInt()}, ' +
              'aspect=${faceAspectRatio.toStringAsFixed(2)}, ' +
              'tooClose=$_faceTooClose, tooFar=$_faceTooFar, ' +
              'notCentered=$_faceNotCentered, ' +
              'confidence=${(_faceConfidence * 100).toStringAsFixed(1)}%');
  }

  void _resetFaceProperties() {
    _faceConfidence = 0.0;
    _faceInPosition = false;
    _faceTooClose = false;
    _faceTooFar = false;
    _faceNotCentered = false;
    _eyesOpen = true;
    _straightHead = true;
    _lightingGood = false;
    _faceSize = null;
    _faceCenter = null;
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showError('Camera not initialized');
      return;
    }

    if (!_faceDetected || !_faceInPosition) {
      _showError('Please position your face correctly before capturing');
      return;
    }

    if (_selectedStudentId == null) {
      _showError('Please select a student first');
      return;
    }

    _startCaptureCountdown();
  }

  void _startCaptureCountdown() {
    setState(() {
      _captureCountdown = 3;
      _isCapturing = true;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _captureCountdown--;
      });

      if (_captureCountdown <= 0) {
        timer.cancel();
        _performCapture();
      }
    });
  }

  Future<void> _performCapture() async {
    try {
      final image = await _cameraController!.takePicture();
      final processedImage = await _processImageWithAdvancedEnhancements(File(image.path));

      if (mounted) {
        setState(() {
          _capturedImage = processedImage;
          _showPreview = true;
          _isCapturing = false;
          _captureCountdown = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to capture image: $e';
          _isCapturing = false;
          _captureCountdown = 0;
        });
      }
    }
  }

  Future<File> _processImageWithAdvancedEnhancements(File imageFile) async {
    try {
      final Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) throw Exception('Failed to decode image');

      // Apply proper orientation correction based on camera type
      if (_cameraController?.description.lensDirection == CameraLensDirection.front) {
        // For front camera, flip horizontally for mirror effect
        image = img.flipHorizontal(image);
      } else if (_cameraController?.description.lensDirection == CameraLensDirection.back) {
        // For back camera with 270 degree rotation
        image = img.copyRotate(image, angle: 270);
      }

      // Apply noise reduction for cleaner image
      image = img.gaussianBlur(image, radius: 2);
      
      // Apply histogram equalization for better contrast in different lighting
      image = _equalizeHistogram(image);

      // Resize to optimal resolution while maintaining aspect ratio
      const targetSize = 512;
      if (image.width != targetSize || image.height != targetSize) {
        // Calculate dimensions that maintain aspect ratio
        double aspectRatio = image.width / image.height;
        int newWidth, newHeight;
        
        if (aspectRatio > 1) {
          newWidth = targetSize;
          newHeight = (targetSize / aspectRatio).round();
        } else {
          newHeight = targetSize;
          newWidth = (targetSize * aspectRatio).round();
        }
        
        image = img.copyResize(
          image, 
          width: newWidth, 
          height: newHeight,
          interpolation: img.Interpolation.cubic
        );
        
        // If needed, pad to square with transparent pixels
        if (newWidth != newHeight) {
          final paddedImage = img.Image(width: targetSize, height: targetSize);
          img.compositeImage(
            paddedImage, 
            image, 
            dstX: (targetSize - newWidth) ~/ 2,
            dstY: (targetSize - newHeight) ~/ 2
          );
          image = paddedImage;
        }
      }

      // Enhanced color correction with adaptive parameters
      double brightness = 1.05;
      double contrast = 1.2;
      double saturation = 1.1;
      double gamma = 0.92;
      
      // Adjust parameters based on detected lighting conditions
      if (!_lightingGood) {
        brightness = 1.15;
        contrast = 1.3;
        gamma = 0.85;
      }
      
      image = img.adjustColor(
        image,
        brightness: brightness,
        contrast: contrast,
        saturation: saturation,
        gamma: gamma,
      );

      // Apply subtle sharpening for facial features
      // image = _applySharpen(image);

      // Convert back to bytes with maximum quality
      final processedBytes = img.encodeJpg(image, quality: 100);

      final String processedPath = imageFile.path.replaceAll('.jpg', '_enhanced.jpg');
      final processedFile = File(processedPath);
      await processedFile.writeAsBytes(processedBytes);
      
      return processedFile;
    } catch (e) {
      debugPrint('Error in advanced image processing: $e');
      return imageFile;
    }
  }
  
  // Helper method for histogram equalization
  img.Image _equalizeHistogram(img.Image image) {
    try {
      // Create histogram for each channel
      List<List<int>> histograms = List.generate(3, (_) => List.filled(256, 0));
      List<List<int>> cumulativeHist = List.generate(3, (_) => List.filled(256, 0));
      
      // Calculate histograms
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          histograms[0][pixel.r.toInt()]++;
          histograms[1][pixel.g.toInt()]++;
          histograms[2][pixel.b.toInt()]++;
        }
      }
      
      // Calculate cumulative histograms
      for (int c = 0; c < 3; c++) {
        cumulativeHist[c][0] = histograms[c][0];
        for (int i = 1; i < 256; i++) {
          cumulativeHist[c][i] = cumulativeHist[c][i - 1] + histograms[c][i];
        }
      }
      
      // Apply equalization
      final totalPixels = image.width * image.height;
      final result = img.Image(width: image.width, height: image.height);
      
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          
          // Calculate new values
          final r = ((cumulativeHist[0][pixel.r.toInt()] * 255) / totalPixels).round().clamp(0, 255);
          final g = ((cumulativeHist[1][pixel.g.toInt()] * 255) / totalPixels).round().clamp(0, 255);
          final b = ((cumulativeHist[2][pixel.b.toInt()] * 255) / totalPixels).round().clamp(0, 255);
          
          result.setPixel(x, y, img.ColorRgb8(r, g, b));
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('Error in histogram equalization: $e');
      return image; // Return original if equalization fails
    }
  }
  
  // Helper method for sharpening
  // img.Image _applySharpen(img.Image image) {
  //   try {
  //     // Simple 3x3 sharpening kernel
  //     final kernel = [
  //       0.0, -0.5, 0.0,
  //       -0.5, 3.0, -0.5,
  //       0.0, -0.5, 0.0
  //     ];
      
  //     return img.convolve(image, kernel);
  //   } catch (e) {
  //     debugPrint('Error in sharpening: $e');
  //     return image; // Return original if sharpening fails
  //   }
  // }

  Future<void> _assignFacialData() async {
    if (_selectedStudentId == null || _capturedImage == null) {
      setState(() {
        _errorMessage = 'Please select a student and capture an image';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString("token");
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final XFile xFile = XFile(_capturedImage!.path);
      final success = await widget.facialService.updateFaceEmbedding(
        _selectedStudentId!,
        xFile,
        token,
      );

      setState(() {
        _isProcessing = false;
        if (success) {
          _successMessage = 'Facial data assigned successfully!';
          _capturedImage = null;
          _selectedStudentId = null;
          _showPreview = false;
        } else {
          _errorMessage = 'Failed to assign facial data. Please try again.';
        }
      });

      if (success) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error assigning facial data: $e';
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
      });
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
      _showPreview = false;
      _errorMessage = null;
      _successMessage = null;
    });
  }

  Widget _buildAdvancedFaceGuideOverlay() {
    return Stack(
      children: [
        // Face guide using custom painter that handles camera rotation
        SizedBox.expand(
          child: CustomPaint(
            painter: FaceGuidePainter(
              faceInPosition: _faceInPosition,
              showEars: true,
              cameraDirection: _cameraController?.description.lensDirection,
            ),
          ),
        ),
        
        // Animated pulse effect
        Center(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 280 * _pulseAnimation.value,
                height: 350 * _pulseAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.circular(180),
                  border: Border.all(
                    color: _faceInPosition ? Colors.green : Colors.white,
                    width: 3,
                  ),
                ),
              );
            },
          ),
        ),

        // Status indicators
        Positioned(
          top: 80,
          left: 0,
          right: 0,
          child: Column(
            children: [
              _buildStatusIndicator('Face Detected', _faceDetected, Icons.face),
              _buildStatusIndicator('Perfect Position', _faceInPosition, Icons.center_focus_strong),
              _buildStatusIndicator('Eyes Open', _eyesOpen, Icons.visibility),
              _buildStatusIndicator('Head Straight', _straightHead, Icons.straighten),
            ],
          ),
        ),

        // Instructions
        Positioned(
          bottom: 120,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildInstructionText(),
                const SizedBox(height: 12),
                // Confidence meter
                Container(
                  width: double.infinity,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: _faceConfidence,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _faceInPosition ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quality: ${(_faceConfidence * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        // Capture countdown
        if (_isCapturing && _captureCountdown > 0)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _captureCountdown.toString(),
                    style: const TextStyle(
                      fontSize: 120,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Hold still...',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInstructionText() {
    if (!_faceDetected) {
      return const Text(
        'Position your face within the guide',
        style: TextStyle(color: Colors.white, fontSize: 14),
        textAlign: TextAlign.center,
      );
    } else if (_faceTooClose) {
      return const Text(
        'Move back - you\'re too close',
        style: TextStyle(color: Colors.orange, fontSize: 14),
        textAlign: TextAlign.center,
      );
    } else if (_faceTooFar) {
      return const Text(
        'Move closer to the camera',
        style: TextStyle(color: Colors.orange, fontSize: 14),
        textAlign: TextAlign.center,
      );
    } else if (_faceInPosition) {
      return const Text(
        'Perfect! Ready to capture',
        style: TextStyle(color: Colors.green, fontSize: 16),
        textAlign: TextAlign.center,
      );
    } else {
      return const Text(
        'Adjusting position...',
        style: TextStyle(color: Colors.yellow, fontSize: 14),
        textAlign: TextAlign.center,
      );
    }
  }

  Widget _buildStatusIndicator(String label, bool status, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: status ? Colors.green.withOpacity(0.9) : Colors.grey.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (status) ...[
            const SizedBox(width: 4),
            const Icon(Icons.check_circle, color: Colors.white, size: 12),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.98,
      minChildSize: 0.5,
      maxChildSize: 0.98,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.face_retouching_natural,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Advanced Face Capture',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'High-quality facial recognition setup',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Student selection
              if (!_showPreview)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select Student',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedStudentId,
                    items: widget.selectedStudents.map((student) {
                      return DropdownMenuItem<String>(
                        value: student.code,
                        child: Text(student.name ?? 'Unknown'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStudentId = value;
                        _errorMessage = null;
                      });
                    },
                  ),
                ),

              // Camera/Preview area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _showPreview ? _buildPreviewView() : _buildCameraView(),
                  ),
                ),
              ),

              // Controls
              Container(
                padding: const EdgeInsets.all(20),
                child: _showPreview ? _buildPreviewControls() : _buildCaptureControls(),
              ),

              // Messages
              if (_errorMessage != null || _successMessage != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _errorMessage != null ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage ?? _successMessage ?? '',
                    style: TextStyle(
                      color: _errorMessage != null ? Colors.red.shade700 : Colors.green.shade700,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCameraView() {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    }
    
    // Get the camera controller and screen size
    final CameraController cameraController = _cameraController!;
    final size = MediaQuery.of(context).size;
    
    // Calculate the scale factor to fill the screen while maintaining aspect ratio
    var scale = size.aspectRatio * cameraController.value.aspectRatio;
    
    // If the calculated scale is less than 1, we need to invert it
    if (scale < 1) scale = 1 / scale;
    
    // Determine if we need to apply rotation based on camera type
    bool isBackCamera = cameraController.description.lensDirection == CameraLensDirection.back;
    int rotationDegrees = isBackCamera ? 270 : 0;
    
    debugPrint('Building camera view with rotation: $rotationDegrees degrees');
    
    return Stack(
      fit: StackFit.expand,
      children: [
        // Use Transform to handle rotation for back camera
        ClipRect(
          child: Transform.scale(
            scale: scale,
            child: Center(
              child: isBackCamera
                ? Transform.rotate(
                    angle: rotationDegrees * math.pi / 180,
                    alignment: Alignment.center,
                    child: AspectRatio(
                      aspectRatio: 1 / cameraController.value.aspectRatio,
                      child: CameraPreview(cameraController),
                    ),
                  )
                : AspectRatio(
                    aspectRatio: cameraController.value.aspectRatio,
                    child: CameraPreview(cameraController),
                  ),
            ),
          ),
        ),
        _buildAdvancedFaceGuideOverlay(),
      ],
    );
  }

  Widget _buildPreviewView() {
    if (_capturedImage == null) {
      return const Center(
        child: Text('No image captured', style: TextStyle(color: Colors.white)),
      );
    }

    return Image.file(_capturedImage!, fit: BoxFit.cover);
  }

  Widget _buildCaptureControls() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Camera switch button
            if (_cameras != null && _cameras!.length > 1)
              Container(
                margin: const EdgeInsets.only(right: 40),
                child: FloatingActionButton(
                  heroTag: 'switchCamera',
                  mini: true,
                  onPressed: _isCapturing ? null : _switchCamera,
                  backgroundColor: Colors.white.withOpacity(0.8),
                  child: Icon(
                    Icons.flip_camera_ios_rounded,
                    color: Colors.black87,
                    size: 20,
                  ),
                ),
              ),
              
            // Main capture button
            GestureDetector(
              onTap: _isCapturing || !_faceInPosition || _selectedStudentId == null
                  ? null
                  : _captureImage,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _faceInPosition && _selectedStudentId != null
                      ? Colors.green
                      : Colors.grey,
                  boxShadow: [
                    BoxShadow(
                      color: (_faceInPosition && _selectedStudentId != null)
                          ? Colors.green.withOpacity(0.5)
                          : Colors.black12,
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.camera, color: Colors.white, size: 40),
              ),
            ),
            
            // Empty container for symmetry
            Container(width: 40),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          _faceInPosition && _selectedStudentId != null
              ? 'Tap to Capture'
              : 'Position face and select student',
          style: TextStyle(
            fontSize: 14,
            color: _faceInPosition && _selectedStudentId != null
                ? Colors.green.shade700
                : Colors.grey.shade600,
          ),
        ),
        
        // Camera type indicator
        if (_cameraController != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _cameraController!.description.lensDirection == CameraLensDirection.front
                ? 'Front Camera'
                : 'Back Camera (270°)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreviewControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: _retakePhoto,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50),
          child: const Text('Retake'),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _assignFacialData,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade50),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Assign'),
        ),
      ],
    );
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    
    setState(() {
      _isCameraInitialized = false;
      _faceDetected = false;
      _faceInPosition = false;
      _errorMessage = null;
    });

    // Stop face detection timer before disposing camera
    _faceDetectionTimer?.cancel();
    await _cameraController?.dispose();
    
    // Find the next camera to use
    final currentCamera = _cameraController!.description;
    final currentIndex = _cameras!.indexOf(currentCamera);
    
    // Explicitly select front or back camera rather than just cycling through
    CameraDescription nextCamera;
    if (currentCamera.lensDirection == CameraLensDirection.front) {
      // If current is front, find a back camera
      nextCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras![(currentIndex + 1) % _cameras!.length],
      );
    } else {
      // If current is back or other, find a front camera
      nextCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras![(currentIndex + 1) % _cameras!.length],
      );
    }
    
    debugPrint('Switching from ${currentCamera.lensDirection} to ${nextCamera.lensDirection} camera');
    
    // Set the correct sensor orientation based on camera type
    int sensorOrientation = nextCamera.sensorOrientation;
    // For back camera, explicitly set to 270 degrees as required
    if (nextCamera.lensDirection == CameraLensDirection.back) {
      sensorOrientation = 270;
      debugPrint('Back camera detected, setting orientation to 270 degrees');
    }
    
    _cameraController = CameraController(
      nextCamera,
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      // Initialize the camera
      await _cameraController!.initialize();
      
      // Apply optimal camera settings
      await _cameraController!.setFocusMode(FocusMode.auto);
      await _cameraController!.setExposureMode(ExposureMode.auto);
      await _cameraController!.setFlashMode(FlashMode.auto);
      
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        // Restart face detection
        _startRealTimeFaceDetection();
        
        // Show a brief success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${nextCamera.lensDirection == CameraLensDirection.front ? "front" : "back"} camera'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      _setError('Failed to switch camera: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.close();
    _faceDetectionTimer?.cancel();
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _statusController.dispose();
    _unlockOrientation();
    super.dispose();
  }
}

class FaceGuidePainter extends CustomPainter {
  final bool faceInPosition;
  final bool showEars;
  final CameraLensDirection? cameraDirection;

  FaceGuidePainter({
    required this.faceInPosition,
    required this.showEars,
    this.cameraDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = faceInPosition ? Colors.green.withOpacity(0.7) : Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
      
    // Check if we need to apply rotation for back camera
    final isBackCamera = cameraDirection == CameraLensDirection.back;
    
    if (isBackCamera) {
      // Save the current canvas state
      canvas.save();
      
      // Rotate canvas 270 degrees clockwise around the center for back camera
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(270 * math.pi / 180);
      canvas.translate(-size.width / 2, -size.height / 2);
    }

    // Draw oval face guide
    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.height * 0.8,
    );

    canvas.drawOval(ovalRect, paint);

    if (showEars && faceInPosition) {
      // Draw left ear
      final leftEarRect = Rect.fromCenter(
        center: Offset(size.width * 0.15, size.height * 0.3),
        width: size.width * 0.15,
        height: size.height * 0.25,
      );
      canvas.drawOval(leftEarRect, paint);

      // Draw right ear
      final rightEarRect = Rect.fromCenter(
        center: Offset(size.width * 0.85, size.height * 0.3),
        width: size.width * 0.15,
        height: size.height * 0.25,
      );
      canvas.drawOval(rightEarRect, paint);
    }

    // Draw subtle glow effect when face is in position
    if (faceInPosition) {
      final glowPaint = Paint()
        ..color = Colors.green.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      final glowRect = ovalRect.inflate(10);
      canvas.drawOval(glowRect, glowPaint);
    }
    
    // Restore canvas state if we rotated it
    if (isBackCamera) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
class CheckInModel {
  final bool success;
  final int status;
  final String message;
  final CheckInData? data;

  CheckInModel({
    required this.success,
    required this.status,
    required this.message,
    this.data,
  });

  factory CheckInModel.fromJson(Map<String, dynamic> json) {
    return CheckInModel(
      success: json['success'] ?? false,
      status: json['status'] ?? 400,
      message: json['message'] ?? 'Unknown error',
      data: json['data'] != null ? CheckInData.fromJson(json['data']) : null,
    );
  }
}

class CheckInData {
  final String id;
  final String studentId;
  final String studentName;
  final String classroomId;
  final String attendanceId;
  final String checkInTime;
  final String? checkOutTime;
  final String attendanceStartTime;
  final String attendanceEndTime;
  final String status;
  final int attendedMinutes;
  final String? deviceType;
  final String? deviceIdentifier;

  CheckInData({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.classroomId,
    required this.attendanceId,
    required this.checkInTime,
    this.checkOutTime,
    required this.attendanceStartTime,
    required this.attendanceEndTime,
    required this.status,
    required this.attendedMinutes,
    this.deviceType,
    this.deviceIdentifier,
  });

  factory CheckInData.fromJson(Map<String, dynamic> json) {
    return CheckInData(
      id: json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? '',
      classroomId: json['classroomId'] ?? '',
      attendanceId: json['attendanceId'] ?? '',
      checkInTime: json['checkInTime'] ?? '',
      checkOutTime: json['checkOutTime'],
      attendanceStartTime: json['attendanceStartTime'] ?? '',
      attendanceEndTime: json['attendanceEndTime'] ?? '',
      status: json['status'] ?? '',
      attendedMinutes: json['attendedMinutes'] ?? 0,
      deviceType: json['deviceType'],
      deviceIdentifier: json['deviceIdentifier'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'classroomId': classroomId,
      'attendanceId': attendanceId,
      'checkInTime': checkInTime,
      'checkOutTime': checkOutTime,
      'attendanceStartTime': attendanceStartTime,
      'attendanceEndTime': attendanceEndTime,
      'status': status,
      'attendedMinutes': attendedMinutes,
      'deviceType': deviceType,
      'deviceIdentifier': deviceIdentifier,
    };
  }
}

  class FacialCheckInModel {
    final bool success;
    final int status;
    final String message;
    final FacialCheckInData? data;

    FacialCheckInModel({
      required this.success,
      required this.status,
      required this.message,
      this.data,
    });

    factory FacialCheckInModel.fromJson(Map<String, dynamic> json) {
      return FacialCheckInModel(
        success: json['success'] ?? false,
        status: json['status'] ?? 500,
        message: json['message'] ?? 'Unknown error',
        data: json['data'] != null ? FacialCheckInData.fromJson(json['data']) : null,
      );
    }
  }

    class FacialCheckInData {
    final String? id;
    final String? studentId;
    final String? studentName;
    final String? checkInTime;
    final String? status;
    final String? attendanceId;

    FacialCheckInData({
      this.id,
      this.studentId,
      this.studentName,
      this.checkInTime,
      this.status,
      this.attendanceId,
    });

    factory FacialCheckInData.fromJson(Map<String, dynamic> json) {
      return FacialCheckInData(
        id: json['id'],
        studentId: json['studentId'],
        studentName: json['studentName'],
        checkInTime: json['checkInTime'],
        status: json['status'],
        attendanceId: json['attendanceId'],
      );
    }
  }

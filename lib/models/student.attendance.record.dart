class StudentAttendanceRecord {
  String? id;
  String? studentId;
  String? studentName;
  String? studentCode;
  String? attendanceId;
  String? status;
  String? checkType;
  String? checkInTime;
  String? checkOutTime;
  String? deviceType;
  String? recordedAt;
  String? attendanceDate;
  bool? isLate;
  bool? isEarlyLeave;
  int? durationMinutes;
  bool? update;

  StudentAttendanceRecord({
    this.id,
    this.studentId,
    this.studentName,
    this.studentCode,
    this.attendanceId,
    this.status,
    this.checkType,
    this.checkInTime,
    this.checkOutTime,
    this.deviceType,
    this.recordedAt,
    this.attendanceDate,
    this.isLate,
    this.isEarlyLeave,
    this.durationMinutes,
    this.update,
  });

  StudentAttendanceRecord.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    studentId = json['studentId'];
    studentName = json['studentName'];
    studentCode = json['studentCode'];
    attendanceId = json['attendanceId'];
    status = json['status'];
    checkType = json['checkType'];
    checkInTime = json['checkInTime'];
    checkOutTime = json['checkOutTime'];
    deviceType = json['deviceType'];
    recordedAt = json['recordedAt'];
    attendanceDate = json['attendanceDate'];
    isLate = json['isLate'];
    isEarlyLeave = json['isEarlyLeave'];
    durationMinutes = json['durationMinutes'];
    update = json['update'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['studentId'] = studentId;
    data['studentName'] = studentName;
    data['studentCode'] = studentCode;
    data['attendanceId'] = attendanceId;
    data['status'] = status;
    data['checkType'] = checkType;
    data['checkInTime'] = checkInTime;
    data['checkOutTime'] = checkOutTime;
    data['deviceType'] = deviceType;
    data['recordedAt'] = recordedAt;
    data['attendanceDate'] = attendanceDate;
    data['isLate'] = isLate;
    data['isEarlyLeave'] = isEarlyLeave;
    data['durationMinutes'] = durationMinutes;
    data['update'] = update;
    return data;
  }
}

class StudentAttendanceResponse {
  int? status;
  bool? success;
  String? message;
  List<StudentAttendanceRecord>? data;

  StudentAttendanceResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  StudentAttendanceResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = <StudentAttendanceRecord>[];
      json['data'].forEach((v) {
        data!.add(StudentAttendanceRecord.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}



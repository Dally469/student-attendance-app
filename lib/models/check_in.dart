class CheckInModel {
  int? statusCode;
  bool? success;
  String? message;
  CheckInData? data;

  CheckInModel({this.statusCode, this.success, this.message, this.data});

  CheckInModel.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? CheckInData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['statusCode'] = statusCode;
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class CheckInData {
  String? id;
  String? studentId;
  String? studentName;
  String? checkInTime;
  String? checkOutTime;
  String? status;
  String? attendanceId;
  String? deviceType;
  String? deviceIdentifier;

  CheckInData({
    this.id,
    this.studentId,
    this.studentName,
    this.checkInTime,
    this.checkOutTime,
    this.status,
    this.attendanceId,
    this.deviceType,
    this.deviceIdentifier,
  });

  CheckInData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    studentId = json['studentId'];
    studentName = json['studentName'];
    checkInTime = json['checkInTime'];
    checkOutTime = json['checkOutTime'];
    status = json['status'];
    attendanceId = json['attendanceId'];
    deviceType = json['deviceType'];
    deviceIdentifier = json['deviceIdentifier'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['studentId'] = studentId;
    data['studentName'] = studentName;
    data['checkInTime'] = checkInTime;
    data['checkOutTime'] = checkOutTime;
    data['status'] = status;
    data['attendanceId'] = attendanceId;
    data['deviceType'] = deviceType;
    data['deviceIdentifier'] = deviceIdentifier;
    return data;
  }
}

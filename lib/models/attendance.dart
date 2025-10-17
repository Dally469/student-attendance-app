class AttendanceModel {
  int? status;
  bool? success;
  String? message;
  Data? data;

  AttendanceModel({this.status, this.success, this.message, this.data});

  AttendanceModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['success'] = success;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class Data {
  String? id;
  String? classroomId;
  String? classroomName;
  String? attendanceDate;
  String? mode;
  String? deviceType;
  String? createdAt;
  String? updatedAt;
  String? schoolId;

  Data({
    this.id,
    this.classroomId,
    this.classroomName,
    this.attendanceDate,
    this.mode,
    this.deviceType,
    this.createdAt,
    this.updatedAt,
    this.schoolId,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    classroomId = json['classroomId'];
    classroomName = json['classroomName'];
    attendanceDate = json['attendanceDate'];
    mode = json['mode'];
    deviceType = json['deviceType'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    schoolId = json['schoolId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['classroomId'] = classroomId;
    data['classroomName'] = classroomName;
    data['attendanceDate'] = attendanceDate;
    data['mode'] = mode;
    data['deviceType'] = deviceType;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['schoolId'] = schoolId;
    return data;
  }
}

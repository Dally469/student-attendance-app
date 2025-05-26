class CheckInModel {
  bool? success;
  String? message;
  CheckInData? data;

  CheckInModel({this.success, this.message, this.data});

  CheckInModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? CheckInData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
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
  String? status;
  String? attendanceId;

  CheckInData({
    this.id,
    this.studentId,
    this.studentName,
    this.checkInTime,
    this.status,
    this.attendanceId,
  });

  CheckInData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    studentId = json['studentId'];
    studentName = json['studentName'];
    checkInTime = json['checkInTime'];
    status = json['status'];
    attendanceId = json['attendanceId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['studentId'] = studentId;
    data['studentName'] = studentName;
    data['checkInTime'] = checkInTime;
    data['status'] = status;
    data['attendanceId'] = attendanceId;
    return data;
  }
}

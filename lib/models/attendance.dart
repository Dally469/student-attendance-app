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
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
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
  String? classroom;
  String? attendanceDate;

  Data({this.id, this.classroom, this.attendanceDate});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    classroom = json['classroom'];
    attendanceDate = json['attendanceDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = id;
    data['classroom'] = classroom;
    data['attendanceDate'] = attendanceDate;
    return data;
  }
}

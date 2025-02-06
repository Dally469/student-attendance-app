class AttendanceModel {
  String? id;
  String? classroom;
  DateTime? attendanceDate;
  bool? success;
  String? message;

  AttendanceModel({
    this.id,
    this.classroom,
    this.attendanceDate,
    this.success,
    this.message,
  });

  AttendanceModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    classroom = json['classroom'];
    attendanceDate = json['attendanceDate'] != null
        ? DateTime.parse(json['attendanceDate'])
        : null;
    success = json['success'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['classroom'] = classroom;
    data['attendanceDate'] = attendanceDate?.toIso8601String();
    data['success'] = success;
    data['message'] = message;
    return data;
  }
}

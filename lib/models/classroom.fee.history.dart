class ClassroomFeesHistory {
  int? status;
  bool? success;
  String? message;
  List<ClassroomFeesData>? data;

  ClassroomFeesHistory({this.status, this.success, this.message, this.data});

  ClassroomFeesHistory.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = <ClassroomFeesData>[];
      json['data'].forEach((v) {
        data!.add(ClassroomFeesData.fromJson(v));
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

class ClassroomFeesData {
  String? id;
  String? studentId;
  String? studentName;
  String? studentCode;
  String? feeTypeId;
  String? feeTypeName;
  double? amountDue; // Changed to double?
  double? amountPaid; // Changed to double?
  double? amountOutstanding; // Changed to double?
  String? dueDate;
  String? status;
  String? academicYear;
  String? term;
  String? createdAt;
  String? updatedAt;
  String? schoolId;

  ClassroomFeesData({
    this.id,
    this.studentId,
    this.studentName,
    this.studentCode,
    this.feeTypeId,
    this.feeTypeName,
    this.amountDue,
    this.amountPaid,
    this.amountOutstanding,
    this.dueDate,
    this.status,
    this.academicYear,
    this.term,
    this.createdAt,
    this.updatedAt,
    this.schoolId,
  });

  ClassroomFeesData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    studentId = json['studentId'];
    studentName = json['studentName'];
    studentCode = json['studentCode'];
    feeTypeId = json['feeTypeId'];
    feeTypeName = json['feeTypeName'];
    amountDue = (json['amountDue'] is int)
        ? (json['amountDue'] as int).toDouble()
        : json['amountDue'] as double?;
    amountPaid = (json['amountPaid'] is int)
        ? (json['amountPaid'] as int).toDouble()
        : json['amountPaid'] as double?;
    amountOutstanding = (json['amountOutstanding'] is int)
        ? (json['amountOutstanding'] as int).toDouble()
        : json['amountOutstanding'] as double?;
    dueDate = json['dueDate'];
    status = json['status'];
    academicYear = json['academicYear'];
    term = json['term'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    schoolId = json['school_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['studentId'] = studentId;
    data['studentName'] = studentName;
    data['studentCode'] = studentCode;
    data['feeTypeId'] = feeTypeId;
    data['feeTypeName'] = feeTypeName;
    data['amountDue'] = amountDue;
    data['amountPaid'] = amountPaid;
    data['amountOutstanding'] = amountOutstanding;
    data['dueDate'] = dueDate;
    data['status'] = status;
    data['academicYear'] = academicYear;
    data['term'] = term;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['school_id'] = schoolId;
    return data;
  }
}
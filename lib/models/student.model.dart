class StudentModel {
  int? status;
  bool success;
  String? message;
  List<StudentData>? data;

  StudentModel({
    this.status,
    required this.success,
    this.message,
    this.data,
  });

  // Updated `fromJson` with corrected forEach usage
  StudentModel.fromJson(Map<String, dynamic> json)
      : status = json['status'],
        success = json['success'] ?? false,
        message = json['message'],
        data = (json['data'] as List<dynamic>?)
            ?.map((item) => StudentData.fromJson(item))
            .toList();

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'success': success,
      'message': message,
      'data': data?.map((student) => student.toJson()).toList(),
    };
  }
}

class StudentData {
  String? id;
  String? code;
  String? name;
  String? gender;
  String? parentContact;
  String? level;
  String? classroomId;
  String? classroom;
  String? departmentId;
  String? department;
  String? profileImage;
  String? schoolId;
  String? school;
  String? status;
  String? cardId;
  bool? isCardAvailable;
  bool? cardAvailable;

  StudentData({
    this.id,
    this.code,
    this.name,
    this.gender,
    this.parentContact,
    this.level,
    this.classroomId,
    this.classroom,
    this.departmentId,
    this.department,
    this.profileImage,
    this.schoolId,
    this.school,
    this.status,
    this.cardId,
    this.isCardAvailable,
    this.cardAvailable,
  });

  // Updated `fromJson`
  StudentData.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        code = json['code'],
        name = json['name'],
        gender = json['gender'],
        parentContact = json['parentContact'],
        level = json['level'],
        classroomId = json['classroom_id'],
        classroom = json['classroom'],
        departmentId = json['department_id'],
        department = json['department'],
        profileImage = json['profileImage'],
        schoolId = json['school_id'],
        school = json['school'],
        status = json['status'],
        cardId = json['cardId'],
        isCardAvailable = json['isCardAvailable'],
        cardAvailable = json['cardAvailable'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'gender': gender,
      'parentContact': parentContact,
      'level': level,
      'classroom_id': classroomId,
      'classroom': classroom,
      'department_id': departmentId,
      'department': department,
      'profileImage': profileImage,
      'school_id': schoolId,
      'school': school,
      'status': status,
      'cardId': cardId,
      'isCardAvailable': isCardAvailable,
      'cardAvailable': cardAvailable,
    };
  }
}

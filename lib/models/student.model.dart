class StudentModel {
  int? status;
  bool success = false;
  String? message;
  List<StudentData>? data;

  StudentModel({this.status,required this.success, this.message, this.data});

  StudentModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    success = json['success'] ?? false;
    message = json['message'];
    if (json['data'] != null) {
      data = <StudentData>[];
      json['data'].forEach((v) {
        data!.add(StudentData.fromJson(v));
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

  StudentData(
      {this.id,
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
      this.cardAvailable});

  StudentData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    code = json['code'];
    name = json['name'];
    gender = json['gender'];
    parentContact = json['parentContact'];
    level = json['level'];
    classroomId = json['classroom_id'];
    classroom = json['classroom'];
    departmentId = json['department_id'];
    department = json['department'];
    profileImage = json['profileImage'];
    schoolId = json['school_id'];
    school = json['school'];
    status = json['status'];
    cardId = json['cardId'];
    isCardAvailable = json['isCardAvailable'];
    cardAvailable = json['cardAvailable'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['code'] = code;
    data['name'] = name;
    data['gender'] = gender;
    data['parentContact'] = parentContact;
    data['level'] = level;
    data['classroom_id'] = classroomId;
    data['classroom'] = classroom;
    data['department_id'] = departmentId;
    data['department'] = department;
    data['profileImage'] = profileImage;
    data['school_id'] = schoolId;
    data['school'] = school;
    data['status'] = status;
    data['cardId'] = cardId;
    data['isCardAvailable'] = isCardAvailable;
    data['cardAvailable'] = cardAvailable;
    return data;
  }
}

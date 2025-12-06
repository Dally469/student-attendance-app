class StudentModel {
  int? status;
  bool? success;
  String? message;
  List<StudentData>? data;

  StudentModel({this.status, this.success, this.message, this.data});

  StudentModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = <StudentData>[];
      json['data'].forEach((v) {
        data!.add(new StudentData.fromJson(v));
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
  String? schoolPhone;
  String? accountMomoPhone;
  String? status;
  String? cardId;
  bool? isCardAvailable;
  String? faceEmbedding;
  bool? hasFacialData;
  String? captureQuality;
  String? faceCaptureDate;
  String? faceDeviceInfo;
  String? faceEmbeddingsCount;
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
      this.schoolPhone,
      this.accountMomoPhone,
      this.status,
      this.cardId,
      this.isCardAvailable,
      this.faceEmbedding,
      this.hasFacialData,
      this.captureQuality,
      this.faceCaptureDate,
      this.faceDeviceInfo,
      this.faceEmbeddingsCount,
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
    schoolId = json['schoolId'];
    school = json['school'];
    schoolPhone = json['schoolPhone'];
    accountMomoPhone = json['accountMomoPhone'];
    status = json['status'];
    cardId = json['cardId'];
    isCardAvailable = json['isCardAvailable'];
    faceEmbedding = json['faceEmbedding'];
    hasFacialData = json['hasFacialData'];
    captureQuality = json['captureQuality'];
    faceCaptureDate = json['faceCaptureDate'];
    faceDeviceInfo = json['faceDeviceInfo'];
    faceEmbeddingsCount = json['faceEmbeddingsCount'];
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
    data['schoolId'] = schoolId;
    data['school'] = school;
    data['schoolPhone'] = schoolPhone;
    data['accountMomoPhone'] = accountMomoPhone;
    data['status'] = status;
    data['cardId'] = cardId;
    data['isCardAvailable'] = isCardAvailable;
    data['faceEmbedding'] = faceEmbedding;
    data['hasFacialData'] = hasFacialData;
    data['captureQuality'] = captureQuality;
    data['faceCaptureDate'] = faceCaptureDate;
    data['faceDeviceInfo'] = faceDeviceInfo;
    data['faceEmbeddingsCount'] = faceEmbeddingsCount;
    data['cardAvailable'] = cardAvailable;
    return data;
  }
}

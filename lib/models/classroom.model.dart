class SchoolClassroomModel {
  int? status;
  bool success = false;
  String? message;
  List<Data>? data;

  SchoolClassroomModel({this.status, required this.success, this.message, this.data});

  SchoolClassroomModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    success = json['success'] ?? false;
    message = json['message'];
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(Data.fromJson(v));
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

class Data {
  String? id;
  School? school;
  String? name;

  Data({this.id, this.school, this.name});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    school =
        json['school'] != null ? School.fromJson(json['school']) : null;
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (school != null) {
      data['school'] = school!.toJson();
    }
    data['name'] = name;
    return data;
  }
}

class School {
  String? id;
  String? name;
  String? phone;
  String? email;
  String? logo;
  String? status;
  String? slogan;

  School(
      {this.id,
      this.name,
      this.phone,
      this.email,
      this.logo,
      this.status,
      this.slogan});

  School.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    phone = json['phone'];
    email = json['email'];
    logo = json['logo'];
    status = json['status'];
    slogan = json['slogan'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['phone'] = phone;
    data['email'] = email;
    data['logo'] = logo;
    data['status'] = status;
    data['slogan'] = slogan;
    return data;
  }
}

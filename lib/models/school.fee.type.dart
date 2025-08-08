class SchoolFeeTypeModel {
  int? status;
  bool? success;
  String? message;
  List<FeesData>? data;

  SchoolFeeTypeModel({this.status, this.success, this.message, this.data});

  SchoolFeeTypeModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = <FeesData>[];
      json['data'].forEach((v) {
        data!.add(FeesData.fromJson(v));
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

class FeesData {
  String? id;
  String? name;
  double? amount; // Changed from int? to double?
  School? school;
  String? description;
  bool? active;
  String? academicYear;
  String? term;

  FeesData({
    this.id,
    this.name,
    this.amount,
    this.school,
    this.description,
    this.active,
    this.academicYear,
    this.term,
  });

  FeesData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    // Handle both int and double values for amount
    amount = (json['amount'] is int)
        ? (json['amount'] as int).toDouble()
        : json['amount'] is double
            ? json['amount']
            : null;
    school = json['school'] != null ? School.fromJson(json['school']) : null;
    description = json['description'];
    active = json['active'];
    academicYear = json['academicYear'];
    term = json['term'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['amount'] = amount;
    if (school != null) {
      data['school'] = school!.toJson();
    }
    data['description'] = description;
    data['active'] = active;
    data['academicYear'] = academicYear;
    data['term'] = term;
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

  School({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.logo,
    this.status,
    this.slogan,
  });

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
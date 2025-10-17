class SchoolModel {
  int? status;
  bool? success;
  String? message;
  List<SchoolData>? data;

  SchoolModel({this.status, this.success, this.message, this.data});

  SchoolModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = <SchoolData>[];
      json['data'].forEach((v) {
        // ignore: unnecessary_new
        data!.add(new SchoolData.fromJson(v));
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

class SchoolData {
  String? id;
  String? name;
  String? phone;
  String? email;
  String? logo;
  String? status;
  String? slogan;

  SchoolData(
      {this.id,
      this.name,
      this.phone,
      this.email,
      this.logo,
      this.status,
      this.slogan});

  SchoolData.fromJson(Map<String, dynamic> json) {
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

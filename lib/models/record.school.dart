class RecordSchoolModel {
  int? status;
  bool? success;
  String? message;
  Data? data;

  RecordSchoolModel({this.status, this.success, this.message, this.data});

  RecordSchoolModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    success = json['success'];
    message = json['message'];
    // ignore: unnecessary_new
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
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
  String? name;
  String? phone;
  String? email;
  String? logo;
  String? status;
  String? slogan;

  Data(
      {this.id,
      this.name,
      this.phone,
      this.email,
      this.logo,
      this.status,
      this.slogan});

  Data.fromJson(Map<String, dynamic> json) {
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

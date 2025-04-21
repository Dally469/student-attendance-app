class UserLoginModel {
  int? status;
  bool success = false;
  String? message;
  String? token;
  UserData? data;

  UserLoginModel(
      {this.status,
      required this.success,
      this.message,
      this.token,
      this.data});

  UserLoginModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    success = json['success'] ?? false;
    message = json['message'];
    token = json['token'];
    data = json['data'] != null ? UserData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['success'] = success;
    data['message'] = message;
    data['token'] = token;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class UserData {
  String? id;
  String? username;
  String? password;
  String? firstName;
  String? lastName;
  String? email;
  String? phone;
  String? role;
  School? school; // Added this field

  UserData(
      {this.id,
      this.username,
      this.password,
      this.firstName,
      this.lastName,
      this.email,
      this.phone,
      this.role,
      this.school // Added this field
      });

  UserData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
    password = json['password'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    email = json['email'];
    phone = json['phone'];
    role = json['role'];
    school = json['school'] != null
        ? School.fromJson(json['school'])
        : null; // Added this line
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['username'] = username;
    data['password'] = password;
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['email'] = email;
    data['phone'] = phone;
    data['role'] = role;
    if (this.school != null) {
      data['school'] = this.school!.toJson(); // Added this
    }
    return data;
  }
}

// Added a new class for the School data
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

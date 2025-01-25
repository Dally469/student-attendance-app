class UserLoginModel {
  int? status;
  bool success = false;
  String? message;
  String? token;
  UserData? data;

  UserLoginModel(
      {this.status,  required this.success, this.message, this.token, this.data});

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

  UserData(
      {this.id,
      this.username,
      this.password,
      this.firstName,
      this.lastName,
      this.email,
      this.phone,
      this.role});

  UserData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    username = json['username'];
    password = json['password'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    email = json['email'];
    phone = json['phone'];
    role = json['role'];
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
    return data;
  }
}

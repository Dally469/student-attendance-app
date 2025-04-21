class SchoolClassroomModel {
  final int status;
  final bool success;
  final String message;
  final List<Classroom> data;

  SchoolClassroomModel({
    required this.status,
    required this.success,
    required this.message,
    required this.data,
  });

  factory SchoolClassroomModel.fromJson(Map<String, dynamic> json) {
    return SchoolClassroomModel(
      status: json['status'],
      success: json['success'],
      message: json['message'],
      data: (json['data'] as List)
          .map((item) => Classroom.fromJson(item))
          .toList(),
    );
  }
}

class Classroom {
  final String id;
  final School school;
  final String name;

  Classroom({
    required this.id,
    required this.school,
    required this.name,
  });

  factory Classroom.fromJson(Map<String, dynamic> json) {
    return Classroom(
      id: json['id'],
      school: School.fromJson(json['school']),
      name: json['name'],
    );
  }
}

class School {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String logo;
  final String status;
  final String slogan;

  School({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.logo,
    required this.status,
    required this.slogan,
  });

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      logo: json['logo'],
      status: json['status'],
      slogan: json['slogan'],
    );
  }
}

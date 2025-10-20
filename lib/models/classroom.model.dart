class SchoolClassroomModel {
  int? status;
  bool? success;
  String? message;
  Data? data;

  SchoolClassroomModel({this.status, this.success, this.message, this.data});

  SchoolClassroomModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    success = json['success'];
    message = json['message'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
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
  int? totalItems;
  int? size;
  int? totalPages;
  List<Classrooms>? classrooms;
  int? currentPage;

  Data(
      {this.totalItems,
      this.size,
      this.totalPages,
      this.classrooms,
      this.currentPage});

  Data.fromJson(Map<String, dynamic> json) {
    totalItems = json['totalItems'];
    size = json['size'];
    totalPages = json['totalPages'];
    if (json['classrooms'] != null) {
      classrooms = <Classrooms>[];
      json['classrooms'].forEach((v) {
        classrooms!.add(Classrooms.fromJson(v));
      });
    }
    currentPage = json['currentPage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['totalItems'] = totalItems;
    data['size'] = size;
    data['totalPages'] = totalPages;
    if (classrooms != null) {
      data['classrooms'] = classrooms!.map((v) => v.toJson()).toList();
    }
    data['currentPage'] = currentPage;
    return data;
  }
}

class Classrooms {
  String? name;
  String? id;
  Department? department;
  Statistics? statistics;

  Classrooms({this.name, this.id, this.department, this.statistics});

  Classrooms.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    id = json['id'];
    department = json['department'] != null
        ? Department.fromJson(json['department'])
        : null;
    statistics = json['statistics'] != null
        ? Statistics.fromJson(json['statistics'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['id'] = id;
    if (department != null) {
      data['department'] = department!.toJson();
    }
    if (statistics != null) {
      data['statistics'] = statistics!.toJson();
    }
    return data;
  }
}

class Department {
  String? id;
  String? name;

  Department({this.id, this.name});

  Department.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    return data;
  }
}

class Statistics {
  int? maleCount;
  int? totalStudents;
  int? femaleCount;

  Statistics({this.maleCount, this.totalStudents, this.femaleCount});

  Statistics.fromJson(Map<String, dynamic> json) {
    maleCount = json['maleCount'];
    totalStudents = json['totalStudents'];
    femaleCount = json['femaleCount'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['maleCount'] = maleCount;
    data['totalStudents'] = totalStudents;
    data['femaleCount'] = femaleCount;
    return data;
  }
}

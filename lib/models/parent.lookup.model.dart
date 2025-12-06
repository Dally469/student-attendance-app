import 'student.model.dart';

class ParentLookupModel {
  int? status;
  bool? success;
  String? message;
  ParentLookupData? data;

  ParentLookupModel({this.status, this.success, this.message, this.data});

  ParentLookupModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    success = json['success'] ?? false;
    message = json['message'];
    // Handle case where data is null, empty array, or a Map
    if (json['data'] != null) {
      if (json['data'] is List && (json['data'] as List).isEmpty) {
        // Empty array means no students found
        data = ParentLookupData(
          expiresIn: null,
          token: null,
          students: <StudentWithFees>[],
        );
      } else {
        data = ParentLookupData.fromJson(json['data']);
      }
    } else {
      data = null;
    }
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

class ParentLookupData {
  String? expiresIn;
  String? token;
  List<StudentWithFees>? students;

  ParentLookupData({this.expiresIn, this.token, this.students});

  ParentLookupData.fromJson(dynamic json) {
    // Handle case where data is an empty array []
    if (json is List) {
      expiresIn = null;
      token = null;
      students = <StudentWithFees>[];
      return;
    }

    // Handle case where data is a Map with the expected structure
    if (json is Map<String, dynamic>) {
      expiresIn = json['expiresIn'];
      token = json['token'];
      if (json['students'] != null) {
        students = <StudentWithFees>[];
        json['students'].forEach((v) {
          students!.add(StudentWithFees.fromJson(v));
        });
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['expiresIn'] = expiresIn;
    data['token'] = token;
    if (students != null) {
      data['students'] = students!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class StudentWithFees {
  StudentData? student;
  List<StudentFee>? unpaidFees;
  FeeSummary? feeSummary;
  bool? hasUnpaidFees;

  StudentWithFees(
      {this.student, this.unpaidFees, this.feeSummary, this.hasUnpaidFees});

  StudentWithFees.fromJson(Map<String, dynamic> json) {
    student =
        json['student'] != null ? StudentData.fromJson(json['student']) : null;
    if (json['unpaidFees'] != null) {
      unpaidFees = <StudentFee>[];
      json['unpaidFees'].forEach((v) {
        unpaidFees!.add(StudentFee.fromJson(v));
      });
    }
    feeSummary = json['feeSummary'] != null
        ? FeeSummary.fromJson(json['feeSummary'])
        : null;
    hasUnpaidFees = json['hasUnpaidFees'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (student != null) {
      data['student'] = student!.toJson();
    }
    if (unpaidFees != null) {
      data['unpaidFees'] = unpaidFees!.map((v) => v.toJson()).toList();
    }
    if (feeSummary != null) {
      data['feeSummary'] = feeSummary!.toJson();
    }
    data['hasUnpaidFees'] = hasUnpaidFees;
    return data;
  }
}

class StudentFee {
  String? id;
  String? studentId;
  String? studentName;
  String? studentCode;
  String? feeTypeId;
  String? feeTypeName;
  double? amountDue;
  double? amountPaid;
  double? amountOutstanding;
  String? dueDate;
  String? status;
  String? academicYear;
  String? term;
  String? createdAt;
  String? updatedAt;
  String? schoolId;
  List<Payment>? payments;

  StudentFee({
    this.id,
    this.studentId,
    this.studentName,
    this.studentCode,
    this.feeTypeId,
    this.feeTypeName,
    this.amountDue,
    this.amountPaid,
    this.amountOutstanding,
    this.dueDate,
    this.status,
    this.academicYear,
    this.term,
    this.createdAt,
    this.updatedAt,
    this.schoolId,
    this.payments,
  });

  StudentFee.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    studentId = json['studentId'];
    studentName = json['studentName'];
    studentCode = json['studentCode'];
    feeTypeId = json['feeTypeId'];
    feeTypeName = json['feeTypeName'];
    amountDue = (json['amountDue'] is int)
        ? (json['amountDue'] as int).toDouble()
        : json['amountDue'] as double?;
    amountPaid = (json['amountPaid'] is int)
        ? (json['amountPaid'] as int).toDouble()
        : json['amountPaid'] as double?;
    amountOutstanding = (json['amountOutstanding'] is int)
        ? (json['amountOutstanding'] as int).toDouble()
        : json['amountOutstanding'] as double?;
    dueDate = json['dueDate'];
    status = json['status'];
    academicYear = json['academicYear'];
    term = json['term'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    schoolId = json['school_id'];
    if (json['payments'] != null) {
      payments = <Payment>[];
      json['payments'].forEach((v) {
        payments!.add(Payment.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['studentId'] = studentId;
    data['studentName'] = studentName;
    data['studentCode'] = studentCode;
    data['feeTypeId'] = feeTypeId;
    data['feeTypeName'] = feeTypeName;
    data['amountDue'] = amountDue;
    data['amountPaid'] = amountPaid;
    data['amountOutstanding'] = amountOutstanding;
    data['dueDate'] = dueDate;
    data['status'] = status;
    data['academicYear'] = academicYear;
    data['term'] = term;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['school_id'] = schoolId;
    if (payments != null) {
      data['payments'] = payments!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Payment {
  String? id;
  String? studentFeeId;
  String? studentId;
  String? studentName;
  String? studentCode;
  String? feeTypeName;
  double? amount;
  String? paymentMethod;
  String? referenceNumber;
  String? receivedBy;
  String? remarks;
  String? paymentDate;
  String? schoolId;
  String? mopayTransactionId;

  Payment({
    this.id,
    this.studentFeeId,
    this.studentId,
    this.studentName,
    this.studentCode,
    this.feeTypeName,
    this.amount,
    this.paymentMethod,
    this.referenceNumber,
    this.receivedBy,
    this.remarks,
    this.paymentDate,
    this.schoolId,
    this.mopayTransactionId,
  });

  Payment.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    studentFeeId = json['studentFeeId'];
    studentId = json['studentId'];
    studentName = json['studentName'];
    studentCode = json['studentCode'];
    feeTypeName = json['feeTypeName'];
    amount = (json['amount'] is int)
        ? (json['amount'] as int).toDouble()
        : json['amount'] as double?;
    paymentMethod = json['paymentMethod'];
    referenceNumber = json['referenceNumber'];
    receivedBy = json['receivedBy'];
    remarks = json['remarks'];
    paymentDate = json['paymentDate'];
    schoolId = json['school_id'];
    mopayTransactionId = json['mopayTransactionId'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['studentFeeId'] = studentFeeId;
    data['studentId'] = studentId;
    data['studentName'] = studentName;
    data['studentCode'] = studentCode;
    data['feeTypeName'] = feeTypeName;
    data['amount'] = amount;
    data['paymentMethod'] = paymentMethod;
    data['referenceNumber'] = referenceNumber;
    data['receivedBy'] = receivedBy;
    data['remarks'] = remarks;
    data['paymentDate'] = paymentDate;
    data['school_id'] = schoolId;
    data['mopayTransactionId'] = mopayTransactionId;
    return data;
  }
}

class FeeSummary {
  String? studentId;
  String? studentName;
  String? studentCode;
  double? totalDue;
  double? totalPaid;
  double? totalOutstanding;
  int? feesCount;
  int? paidFeesCount;
  int? unpaidFeesCount;
  int? partiallyPaidFeesCount;
  String? academicYear;
  String? term;
  List<StudentFee>? allFees;

  FeeSummary({
    this.studentId,
    this.studentName,
    this.studentCode,
    this.totalDue,
    this.totalPaid,
    this.totalOutstanding,
    this.feesCount,
    this.paidFeesCount,
    this.unpaidFeesCount,
    this.partiallyPaidFeesCount,
    this.academicYear,
    this.term,
    this.allFees,
  });

  FeeSummary.fromJson(Map<String, dynamic> json) {
    studentId = json['studentId'];
    studentName = json['studentName'];
    studentCode = json['studentCode'];
    totalDue = (json['totalDue'] is int)
        ? (json['totalDue'] as int).toDouble()
        : json['totalDue'] as double?;
    totalPaid = (json['totalPaid'] is int)
        ? (json['totalPaid'] as int).toDouble()
        : json['totalPaid'] as double?;
    totalOutstanding = (json['totalOutstanding'] is int)
        ? (json['totalOutstanding'] as int).toDouble()
        : json['totalOutstanding'] as double?;
    feesCount = json['feesCount'];
    paidFeesCount = json['paidFeesCount'];
    unpaidFeesCount = json['unpaidFeesCount'];
    partiallyPaidFeesCount = json['partiallyPaidFeesCount'];
    academicYear = json['academicYear'];
    term = json['term'];
    if (json['allFees'] != null) {
      allFees = <StudentFee>[];
      json['allFees'].forEach((v) {
        allFees!.add(StudentFee.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['studentId'] = studentId;
    data['studentName'] = studentName;
    data['studentCode'] = studentCode;
    data['totalDue'] = totalDue;
    data['totalPaid'] = totalPaid;
    data['totalOutstanding'] = totalOutstanding;
    data['feesCount'] = feesCount;
    data['paidFeesCount'] = paidFeesCount;
    data['unpaidFeesCount'] = unpaidFeesCount;
    data['partiallyPaidFeesCount'] = partiallyPaidFeesCount;
    data['academicYear'] = academicYear;
    data['term'] = term;
    if (allFees != null) {
      data['allFees'] = allFees!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

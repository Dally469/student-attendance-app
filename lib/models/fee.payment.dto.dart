class PaymentResponseModel {
  final int status;
  final bool success;
  final String message;
  final PaymentData? data;

  PaymentResponseModel({
    required this.status,
    required this.success,
    required this.message,
    this.data,
  });

  factory PaymentResponseModel.fromJson(Map<String, dynamic> json) {
    return PaymentResponseModel(
      status: json['status'] ?? 0,
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? PaymentData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }

  @override
  String toString() {
    return 'PaymentResponseModel(status: $status, success: $success, message: $message, data: $data)';
  }
}

// payment_data_model.dart
class PaymentData {
  final int? id;
  final int? studentFeeId;
  final int? studentId;
  final String? studentName;
  final String? studentCode;
  final String? feeTypeName;
  final double? amount;
  final String? paymentMethod;
  final String? referenceNumber;
  final String? receivedBy;
  final String? remarks;
  final DateTime? paymentDate;
  final int? schoolId;

  PaymentData({
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
  });

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      id: json['id'],
      studentFeeId: json['studentFeeId'],
      studentId: json['studentId'],
      studentName: json['studentName'],
      studentCode: json['studentCode'],
      feeTypeName: json['feeTypeName'],
      amount: json['amount']?.toDouble(),
      paymentMethod: json['paymentMethod'],
      referenceNumber: json['referenceNumber'],
      receivedBy: json['receivedBy'],
      remarks: json['remarks'],
      paymentDate: json['paymentDate'] != null 
          ? DateTime.tryParse(json['paymentDate'].toString()) 
          : null,
      schoolId: json['school_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentFeeId': studentFeeId,
      'studentId': studentId,
      'studentName': studentName,
      'studentCode': studentCode,
      'feeTypeName': feeTypeName,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'referenceNumber': referenceNumber,
      'receivedBy': receivedBy,
      'remarks': remarks,
      'paymentDate': paymentDate?.toIso8601String(),
      'school_id': schoolId,
    };
  }

  // Copy with method for immutable updates
  PaymentData copyWith({
    int? id,
    int? studentFeeId,
    int? studentId,
    String? studentName,
    String? studentCode,
    String? feeTypeName,
    double? amount,
    String? paymentMethod,
    String? referenceNumber,
    String? receivedBy,
    String? remarks,
    DateTime? paymentDate,
    int? schoolId,
  }) {
    return PaymentData(
      id: id ?? this.id,
      studentFeeId: studentFeeId ?? this.studentFeeId,
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      studentCode: studentCode ?? this.studentCode,
      feeTypeName: feeTypeName ?? this.feeTypeName,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      receivedBy: receivedBy ?? this.receivedBy,
      remarks: remarks ?? this.remarks,
      paymentDate: paymentDate ?? this.paymentDate,
      schoolId: schoolId ?? this.schoolId,
    );
  }

  @override
  String toString() {
    return 'PaymentData(id: $id, studentFeeId: $studentFeeId, studentId: $studentId, studentName: $studentName, studentCode: $studentCode, feeTypeName: $feeTypeName, amount: $amount, paymentMethod: $paymentMethod, referenceNumber: $referenceNumber, receivedBy: $receivedBy, remarks: $remarks, paymentDate: $paymentDate, schoolId: $schoolId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentData &&
        other.id == id &&
        other.studentFeeId == studentFeeId &&
        other.studentId == studentId &&
        other.studentName == studentName &&
        other.studentCode == studentCode &&
        other.feeTypeName == feeTypeName &&
        other.amount == amount &&
        other.paymentMethod == paymentMethod &&
        other.referenceNumber == referenceNumber &&
        other.receivedBy == receivedBy &&
        other.remarks == remarks &&
        other.paymentDate == paymentDate &&
        other.schoolId == schoolId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      studentFeeId,
      studentId,
      studentName,
      studentCode,
      feeTypeName,
      amount,
      paymentMethod,
      referenceNumber,
      receivedBy,
      remarks,
      paymentDate,
      schoolId,
    );
  }
}

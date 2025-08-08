
class StudentFeeDTO {
  final String id;
  final String studentId;
  final String feeTypeId;
  final double amountDue;
  final String dueDate;
  final String academicYear;
  final String term;
  final String status;

  StudentFeeDTO({
    required this.id,
    required this.studentId,
    required this.feeTypeId,
    required this.amountDue,
    required this.dueDate,
    required this.academicYear,
    required this.term,
    required this.status,
  });

  factory StudentFeeDTO.fromJson(Map<String, dynamic> json) {
    return StudentFeeDTO(
      id: json['id'] ?? '',
      studentId: json['studentId'] ?? '',
      feeTypeId: json['feeTypeId'] ?? '',
      amountDue: (json['amountDue'] ?? 0.0).toDouble(),
      dueDate: json['dueDate'] ?? '',
      academicYear: json['academicYear'] ?? '',
      term: json['term'] ?? '',
      status: json['status'] ?? 'UNPAID',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'feeTypeId': feeTypeId,
      'amountDue': amountDue,
      'dueDate': dueDate,
      'academicYear': academicYear,
      'term': term,
    };
  }
}
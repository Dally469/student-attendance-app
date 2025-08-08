class FeePaymentDTO {
  final String id;
  final String feeId;
  final double amount;
  final String paymentMethod;
  final String referenceNumber;
  final String receivedBy;
  final String remarks;
  final String paymentDate;

  FeePaymentDTO({
    required this.id,
    required this.feeId,
    required this.amount,
    required this.paymentMethod,
    required this.referenceNumber,
    required this.receivedBy,
    required this.remarks,
    required this.paymentDate,
  });

  factory FeePaymentDTO.fromJson(Map<String, dynamic> json) {
    return FeePaymentDTO(
      id: json['id'] ?? '',
      feeId: json['feeId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      referenceNumber: json['referenceNumber'] ?? '',
      receivedBy: json['receivedBy'] ?? '',
      remarks: json['remarks'] ?? '',
      paymentDate: json['paymentDate'] ?? '',
    );
  }
}
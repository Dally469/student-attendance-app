// SMS Balance Model
class SMSBalanceModel {
  final int status;
  final bool success;
  final String message;
  final SMSBalanceData? data;

  SMSBalanceModel({
    required this.status,
    required this.success,
    required this.message,
    this.data,
  });

  factory SMSBalanceModel.fromJson(Map<String, dynamic> json) {
    return SMSBalanceModel(
      status: json['status'] ?? 0,
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? SMSBalanceData.fromJson(json['data']) : null,
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
}

class SMSBalanceData {
  final double currentBalance;
  final double totalTopUps;
  final double totalUsage;
  final String? lastTopUpDate;
  final String? lastUsageDate;

  SMSBalanceData({
    required this.currentBalance,
    required this.totalTopUps,
    required this.totalUsage,
    this.lastTopUpDate,
    this.lastUsageDate,
  });

  factory SMSBalanceData.fromJson(Map<String, dynamic> json) {
    return SMSBalanceData(
      currentBalance: (json['currentBalance'] ?? 0.0).toDouble(),
      totalTopUps: (json['totalTopUps'] ?? 0.0).toDouble(),
      totalUsage: (json['totalUsage'] ?? 0.0).toDouble(),
      lastTopUpDate: json['lastTopUpDate'],
      lastUsageDate: json['lastUsageDate'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentBalance': currentBalance,
      'totalTopUps': totalTopUps,
      'totalUsage': totalUsage,
      'lastTopUpDate': lastTopUpDate,
      'lastUsageDate': lastUsageDate,
    };
  }

  String get formattedBalance => currentBalance.toStringAsFixed(0);
  String get formattedTotalTopUps => totalTopUps.toStringAsFixed(0);
  String get formattedTotalUsage => totalUsage.toStringAsFixed(0);
}

// SMS Transaction Models
class SMSTransactionHistoryModel {
  final int status;
  final bool success;
  final String message;
  final SMSTransactionData? data;

  SMSTransactionHistoryModel({
    required this.status,
    required this.success,
    required this.message,
    this.data,
  });

  factory SMSTransactionHistoryModel.fromJson(Map<String, dynamic> json) {
    return SMSTransactionHistoryModel(
      status: json['status'] ?? 0,
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? SMSTransactionData.fromJson(json['data']) : null,
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
}

class SMSTransactionData {
  final List<SMSTransaction> content;
  final int totalElements;
  final int totalPages;
  final int size;
  final int number;

  SMSTransactionData({
    required this.content,
    required this.totalElements,
    required this.totalPages,
    required this.size,
    required this.number,
  });

  factory SMSTransactionData.fromJson(Map<String, dynamic> json) {
    return SMSTransactionData(
      content: (json['content'] as List<dynamic>? ?? [])
          .map((item) => SMSTransaction.fromJson(item))
          .toList(),
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      size: json['size'] ?? 10,
      number: json['number'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content.map((item) => item.toJson()).toList(),
      'totalElements': totalElements,
      'totalPages': totalPages,
      'size': size,
      'number': number,
    };
  }

  bool get hasMorePages => number < totalPages - 1;
  bool get isFirstPage => number == 0;
  bool get isLastPage => number == totalPages - 1;
}

class SMSTransaction {
  final String id;
  final String transactionType;
  final double amount;
  final double previousBalance;
  final double newBalance;
  final String description;
  final String? paymentMethod;
  final String? paymentReference;
  final String status;
  final String createdAt;
  final String? processedAt;

  SMSTransaction({
    required this.id,
    required this.transactionType,
    required this.amount,
    required this.previousBalance,
    required this.newBalance,
    required this.description,
    this.paymentMethod,
    this.paymentReference,
    required this.status,
    required this.createdAt,
    this.processedAt,
  });

  factory SMSTransaction.fromJson(Map<String, dynamic> json) {
    return SMSTransaction(
      id: json['id'] ?? '',
      transactionType: json['transactionType'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      previousBalance: (json['previousBalance'] ?? 0.0).toDouble(),
      newBalance: (json['newBalance'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      paymentMethod: json['paymentMethod'],
      paymentReference: json['paymentReference'],
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '',
      processedAt: json['processedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transactionType': transactionType,
      'amount': amount,
      'previousBalance': previousBalance,
      'newBalance': newBalance,
      'description': description,
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'status': status,
      'createdAt': createdAt,
      'processedAt': processedAt,
    };
  }

  // Helper getters
  bool get isTopUp => transactionType.toUpperCase() == 'TOP_UP';
  bool get isUsage => transactionType.toUpperCase() == 'USAGE';
  bool get isCompleted => status.toUpperCase() == 'COMPLETED';
  bool get isPending => status.toUpperCase() == 'PENDING';

  String get formattedAmount {
    final prefix = isTopUp ? '+' : '-';
    return '$prefix${amount.abs().toStringAsFixed(0)}';
  }

  DateTime get createdAtDate {
    try {
      return DateTime.parse(createdAt);
    } catch (e) {
      return DateTime.now();
    }
  }

  DateTime? get processedAtDate {
    if (processedAt == null) return null;
    try {
      return DateTime.parse(processedAt!);
    } catch (e) {
      return null;
    }
  }

  String get formattedDate {
    final date = createdAtDate;
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get typeIcon {
    return isTopUp ? '⬆️' : '⬇️';
  }

  String get statusIcon {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return '✅';
      case 'PENDING':
        return '⏳';
      case 'FAILED':
        return '❌';
      default:
        return '❓';
    }
  }
}

// SMS Top-up DTO
class SMSTopUpDTO {
  final double amount;
  final String paymentMethod;
  final String paymentReference;
  final String? description;

  SMSTopUpDTO({
    required this.amount,
    required this.paymentMethod,
    required this.paymentReference,
    this.description,
  });

  factory SMSTopUpDTO.fromJson(Map<String, dynamic> json) {
    return SMSTopUpDTO(
      amount: (json['amount'] ?? 0.0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      paymentReference: json['paymentReference'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'description': description,
    };
  }
}

// SMS Bulk Response Model
class SMSBulkResponseModel {
  final int status;
  final bool success;
  final String message;
  final SMSBulkData? data;

  SMSBulkResponseModel({
    required this.status,
    required this.success,
    required this.message,
    this.data,
  });

  factory SMSBulkResponseModel.fromJson(Map<String, dynamic> json) {
    return SMSBulkResponseModel(
      status: json['status'] ?? 0,
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? SMSBulkData.fromJson(json['data']) : null,
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
}

class SMSBulkData {
  final int sentCount;
  final int failedCount;
  final double creditUsed;
  final String? referenceId;
  final List<String>? failedRecipients;

  SMSBulkData({
    required this.sentCount,
    required this.failedCount,
    required this.creditUsed,
    this.referenceId,
    this.failedRecipients,
  });

  factory SMSBulkData.fromJson(Map<String, dynamic> json) {
    return SMSBulkData(
      sentCount: json['sentCount'] ?? 0,
      failedCount: json['failedCount'] ?? 0,
      creditUsed: (json['creditUsed'] ?? 0.0).toDouble(),
      referenceId: json['referenceId'],
      failedRecipients: (json['failedRecipients'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sentCount': sentCount,
      'failedCount': failedCount,
      'creditUsed': creditUsed,
      'referenceId': referenceId,
      'failedRecipients': failedRecipients,
    };
  }

  int get totalAttempts => sentCount + failedCount;
  double get successRate => totalAttempts > 0 ? (sentCount / totalAttempts) * 100 : 0.0;
  bool get hasFailures => failedCount > 0;
}

// SMS Usage Statistics Model
class SMSUsageStatsModel {
  final int status;
  final bool success;
  final String message;
  final SMSUsageStatsData? data;

  SMSUsageStatsModel({
    required this.status,
    required this.success,
    required this.message,
    this.data,
  });

  factory SMSUsageStatsModel.fromJson(Map<String, dynamic> json) {
    return SMSUsageStatsModel(
      status: json['status'] ?? 0,
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? SMSUsageStatsData.fromJson(json['data']) : null,
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
}

class SMSUsageStatsData {
  final double totalSent;
  final double totalCostSent;
  final double totalTopUps;
  final double totalCostTopUps;
  final int totalTransactions;
  final String? periodStart;
  final String? periodEnd;
  final List<SMSDailyUsage>? dailyUsage;

  SMSUsageStatsData({
    required this.totalSent,
    required this.totalCostSent,
    required this.totalTopUps,
    required this.totalCostTopUps,
    required this.totalTransactions,
    this.periodStart,
    this.periodEnd,
    this.dailyUsage,
  });

  factory SMSUsageStatsData.fromJson(Map<String, dynamic> json) {
    return SMSUsageStatsData(
      totalSent: (json['totalSent'] ?? 0.0).toDouble(),
      totalCostSent: (json['totalCostSent'] ?? 0.0).toDouble(),
      totalTopUps: (json['totalTopUps'] ?? 0.0).toDouble(),
      totalCostTopUps: (json['totalCostTopUps'] ?? 0.0).toDouble(),
      totalTransactions: json['totalTransactions'] ?? 0,
      periodStart: json['periodStart'],
      periodEnd: json['periodEnd'],
      dailyUsage: (json['dailyUsage'] as List<dynamic>?)
          ?.map((item) => SMSDailyUsage.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSent': totalSent,
      'totalCostSent': totalCostSent,
      'totalTopUps': totalTopUps,
      'totalCostTopUps': totalCostTopUps,
      'totalTransactions': totalTransactions,
      'periodStart': periodStart,
      'periodEnd': periodEnd,
      'dailyUsage': dailyUsage?.map((item) => item.toJson()).toList(),
    };
  }

  double get netBalance => totalTopUps - totalSent;
  String get formattedTotalSent => totalSent.toStringAsFixed(0);
  String get formattedTotalTopUps => totalTopUps.toStringAsFixed(0);
  String get formattedNetBalance => netBalance.toStringAsFixed(0);
}

class SMSDailyUsage {
  final String date;
  final double sent;
  final double topUps;
  final int transactions;

  SMSDailyUsage({
    required this.date,
    required this.sent,
    required this.topUps,
    required this.transactions,
  });

  factory SMSDailyUsage.fromJson(Map<String, dynamic> json) {
    return SMSDailyUsage(
      date: json['date'] ?? '',
      sent: (json['sent'] ?? 0.0).toDouble(),
      topUps: (json['topUps'] ?? 0.0).toDouble(),
      transactions: json['transactions'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'sent': sent,
      'topUps': topUps,
      'transactions': transactions,
    };
  }

  DateTime get dateTime {
    try {
      return DateTime.parse(date);
    } catch (e) {
      return DateTime.now();
    }
  }

  String get formattedDate {
    final dt = dateTime;
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  double get netUsage => topUps - sent;
}

// SMS Bulk Request DTO
class SMSBulkDTO {
  final List<String> recipients;
  final String message;

  SMSBulkDTO({
    required this.recipients,
    required this.message,
  });

  factory SMSBulkDTO.fromJson(Map<String, dynamic> json) {
    return SMSBulkDTO(
      recipients: (json['recipients'] as List<dynamic>?)
          ?.map((item) => item.toString())
          .toList() ?? [],
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipients': recipients,
      'message': message,
    };
  }

  int get recipientCount => recipients.length;
  bool get isValid => recipients.isNotEmpty && message.trim().isNotEmpty;
  
  String get recipientSummary {
    if (recipients.isEmpty) return 'No recipients';
    if (recipients.length == 1) return '1 recipient';
    return '${recipients.length} recipients';
  }
}

// Payment Method Enum (for better type safety)
enum SMSPaymentMethod {
  creditCard('CREDIT_CARD'),
  debitCard('DEBIT_CARD'),
  mobileWallet('MOBILE_WALLET'),
  bankTransfer('BANK_TRANSFER'),
  cash('CASH'),
  other('OTHER');

  const SMSPaymentMethod(this.value);
  final String value;

  static SMSPaymentMethod fromString(String value) {
    return SMSPaymentMethod.values.firstWhere(
      (method) => method.value == value.toUpperCase(),
      orElse: () => SMSPaymentMethod.other,
    );
  }

  String get displayName {
    switch (this) {
      case SMSPaymentMethod.creditCard:
        return 'Credit Card';
      case SMSPaymentMethod.debitCard:
        return 'Debit Card';
      case SMSPaymentMethod.mobileWallet:
        return 'Mobile Wallet';
      case SMSPaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case SMSPaymentMethod.cash:
        return 'Cash';
      case SMSPaymentMethod.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case SMSPaymentMethod.creditCard:
        return '💳';
      case SMSPaymentMethod.debitCard:
        return '💳';
      case SMSPaymentMethod.mobileWallet:
        return '📱';
      case SMSPaymentMethod.bankTransfer:
        return '🏦';
      case SMSPaymentMethod.cash:
        return '💵';
      case SMSPaymentMethod.other:
        return '💰';
    }
  }
}

// Transaction Status Enum
enum SMSTransactionStatus {
  completed('COMPLETED'),
  pending('PENDING'),
  failed('FAILED'),
  cancelled('CANCELLED'),
  processing('PROCESSING');

  const SMSTransactionStatus(this.value);
  final String value;

  static SMSTransactionStatus fromString(String value) {
    return SMSTransactionStatus.values.firstWhere(
      (status) => status.value == value.toUpperCase(),
      orElse: () => SMSTransactionStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case SMSTransactionStatus.completed:
        return 'Completed';
      case SMSTransactionStatus.pending:
        return 'Pending';
      case SMSTransactionStatus.failed:
        return 'Failed';
      case SMSTransactionStatus.cancelled:
        return 'Cancelled';
      case SMSTransactionStatus.processing:
        return 'Processing';
    }
  }

  String get icon {
    switch (this) {
      case SMSTransactionStatus.completed:
        return '✅';
      case SMSTransactionStatus.pending:
        return '⏳';
      case SMSTransactionStatus.failed:
        return '❌';
      case SMSTransactionStatus.cancelled:
        return '🚫';
      case SMSTransactionStatus.processing:
        return '⏺️';
    }
  }

  bool get isCompleted => this == SMSTransactionStatus.completed;
  bool get isPending => this == SMSTransactionStatus.pending;
  bool get isFailed => this == SMSTransactionStatus.failed;
  bool get isProcessing => this == SMSTransactionStatus.processing;
}
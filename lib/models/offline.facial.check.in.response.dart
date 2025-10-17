

  // Model for offline facial check-in
  class OfflineFacialCheckIn {
    final String studentCode;
    final String classroomId;
    final String attendanceId;
    final String base64Embedding;
    final DateTime timestamp;
    bool synced;

    OfflineFacialCheckIn({
      required this.studentCode,
      required this.classroomId,
      required this.attendanceId,
      required this.base64Embedding,
      required this.timestamp,
      this.synced = false,
    });

    Map<String, dynamic> toJson() {
      return {
        'studentCode': studentCode,
        'classroomId': classroomId,
        'attendanceId': attendanceId,
        'base64Embedding': base64Embedding,
        'timestamp': timestamp.toIso8601String(),
        'synced': synced,
      };
    }

    factory OfflineFacialCheckIn.fromJson(Map<String, dynamic> json) {
      return OfflineFacialCheckIn(
        studentCode: json['studentCode'],
        classroomId: json['classroomId'],
        attendanceId: json['attendanceId'],
        base64Embedding: json['base64Embedding'],
        timestamp: DateTime.parse(json['timestamp']),
        synced: json['synced'] ?? false,
      );
    }
  }

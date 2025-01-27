class OfflineCheckIn {
  final String studentId;
  final String classroomId;
  final String attendanceId;
  final DateTime timestamp;
  final bool synced;

  OfflineCheckIn({
    required this.studentId,
    required this.classroomId,
    required this.attendanceId,
    required this.timestamp,
    this.synced = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'classroomId': classroomId,
      'attendanceId': attendanceId,
      'timestamp': timestamp.toIso8601String(),
      'synced': synced,
    };
  }

  factory OfflineCheckIn.fromJson(Map<String, dynamic> json) {
    return OfflineCheckIn(
      studentId: json['studentId'],
      classroomId: json['classroomId'],
      attendanceId: json['attendanceId'],
      timestamp: DateTime.parse(json['timestamp']),
      synced: json['synced'] ?? false,
    );
  }
}

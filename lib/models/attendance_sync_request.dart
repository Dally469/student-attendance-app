class AttendanceSyncRequest {
  final String classroomId;
  final String attendanceDate;
  final String syncTimestamp;
  final String deviceId;
  final List<AttendanceRecord> attendanceRecords;

  AttendanceSyncRequest({
    required this.classroomId,
    required this.attendanceDate,
    required this.syncTimestamp,
    required this.deviceId,
    required this.attendanceRecords,
  });

  Map<String, dynamic> toJson() {
    return {
      'classroomId': classroomId,
      'attendanceDate': attendanceDate,
      'syncTimestamp': syncTimestamp,
      'deviceId': deviceId,
      'attendanceRecords': attendanceRecords.map((record) => record.toJson()).toList(),
    };
  }
}

class AttendanceRecord {
  final String? studentId;
  final String? studentCode;
  final String status;
  final String recordedAt;
  final String? notes;

  AttendanceRecord({
    this.studentId,
    this.studentCode,
    required this.status,
    required this.recordedAt,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'status': status,
      'recordedAt': recordedAt,
    };

    // Only add fields if they are not null
    if (studentId != null) data['studentId'] = studentId;
    if (studentCode != null) data['studentCode'] = studentCode;
    if (notes != null) data['notes'] = notes;

    return data;
  }
}

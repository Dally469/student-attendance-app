
  // Model for facial sync request
  class FacialAttendanceSyncRequest {
    final String classroomId;
    final String attendanceDate;
    final String syncTimestamp;
    final String deviceId;
    final List<FacialAttendanceRecord> attendanceRecords;

    FacialAttendanceSyncRequest({
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


  class FacialAttendanceRecord {
    final String studentCode;
    final String base64Embedding;
    final String recordedAt;

    FacialAttendanceRecord({
      required this.studentCode,
      required this.base64Embedding,
      required this.recordedAt,
    });

    Map<String, dynamic> toJson() {
      return {
        'studentCode': studentCode,
        'base64Embedding': base64Embedding,
        'recordedAt': recordedAt,
      };
    }
  }
/// Response for GET /api/attendance/settings
class AttendanceSettingsResponse {
  int? status;
  bool? success;
  String? message;
  AttendanceSettingsData? data;

  AttendanceSettingsResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  AttendanceSettingsResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    success = json['success'];
    message = json['message'];
    data = json['data'] != null
        ? AttendanceSettingsData.fromJson(json['data'] as Map<String, dynamic>)
        : null;
  }
}

class AttendanceSettingsData {
  List<AttendanceSetting>? settings;
  List<AttendanceEvent>? events;

  AttendanceSettingsData({this.settings, this.events});

  AttendanceSettingsData.fromJson(Map<String, dynamic> json) {
    if (json['settings'] != null) {
      if (json['settings'] is List) {
        final list = <AttendanceSetting>[];
        for (final e in json['settings'] as List) {
          if (e is Map<String, dynamic>) {
            try {
              list.add(AttendanceSetting.fromJson(e));
            } catch (_) {}
          }
        }
        settings = list.isEmpty ? null : list;
      } else if (json['settings'] is Map<String, dynamic>) {
        settings = [AttendanceSetting.fromJson(json['settings'] as Map<String, dynamic>)];
      } else {
        settings = null;
      }
    } else {
      settings = null;
    }
    events = json['events'] != null
        ? (json['events'] as List)
            .map((e) => AttendanceEvent.fromJson(e as Map<String, dynamic>))
            .toList()
        : null;
  }
}

class AttendanceSetting {
  String? id;
  String? schoolId;
  String? attendanceMode;
  bool? schoolWideAttendance;
  bool? applyToAllClassrooms;
  String? attendanceStartTime;
  String? attendanceEndTime;
  int? minClockInOutIntervalMinutes;
  String? timezone;
  String? deviceType;

  AttendanceSetting({
    this.id,
    this.schoolId,
    this.attendanceMode,
    this.schoolWideAttendance,
    this.applyToAllClassrooms,
    this.attendanceStartTime,
    this.attendanceEndTime,
    this.minClockInOutIntervalMinutes,
    this.timezone,
    this.deviceType,
  });

  AttendanceSetting.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    schoolId = json['schoolId'];
    attendanceMode = json['attendanceMode'];
    schoolWideAttendance = json['schoolWideAttendance'];
    applyToAllClassrooms = json['applyToAllClassrooms'];
    attendanceStartTime = json['attendanceStartTime'];
    attendanceEndTime = json['attendanceEndTime'];
    minClockInOutIntervalMinutes = json['minClockInOutIntervalMinutes'];
    timezone = json['timezone'];
    deviceType = json['deviceType'];
  }
}

class AttendanceEvent {
  String? id;
  String? schoolId;
  String? name;
  String? eventType;
  String? startDate;
  String? endDate;
  String? createdAt;

  AttendanceEvent({
    this.id,
    this.schoolId,
    this.name,
    this.eventType,
    this.startDate,
    this.endDate,
    this.createdAt,
  });

  AttendanceEvent.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    schoolId = json['schoolId'];
    name = json['name'];
    eventType = json['eventType'];
    startDate = json['startDate'];
    endDate = json['endDate'];
    createdAt = json['createdAt'];
  }
}

/// Response for GET /api/attendance/events
class AttendanceEventsResponse {
  int? status;
  bool? success;
  String? message;
  List<AttendanceEvent>? data;

  AttendanceEventsResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  AttendanceEventsResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    success = json['success'];
    message = json['message'];
    if (json['data'] != null) {
      data = (json['data'] as List)
          .map((e) => AttendanceEvent.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }
}

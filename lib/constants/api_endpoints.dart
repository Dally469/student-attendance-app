import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API Endpoints Constants
/// Centralized location for all API endpoint paths
class ApiEndpoints {
  ApiEndpoints._(); // Private constructor to prevent instantiation

  // Base URL
  static String get baseUrl => dotenv.get('mainUrl');

  // Auth Endpoints
  static String get login => '$baseUrl/auth/login';
  static String get parentLogin => '$baseUrl/auth/parent/login';

  // Student Endpoints
  static String get studentsSearchByPhoneOrCode =>
      '$baseUrl/api/students/search/by-phone-or-code';
  static String get studentsSearch => '$baseUrl/api/students/search';
  static String get studentsFilterByClassroom =>
      '$baseUrl/api/students/filter/classroom';
  static String assignCard(String studentId) =>
      '$baseUrl/api/students/$studentId/assign-card';

  // Classroom Endpoints
  static String get classrooms => '$baseUrl/api/classrooms';

  // Attendance Endpoints
  static String createAttendance(String classroomId) =>
      '$baseUrl/api/attendance/classroom/$classroomId';
  static String getAttendance(String attendanceId) =>
      '$baseUrl/api/attendance/$attendanceId';
  static String attendanceStudents(String attendanceId) =>
      '$baseUrl/api/attendance/$attendanceId/students';
  static String get studentAttendanceCheckIn =>
      '$baseUrl/api/student-attendance/check-in';
  /// Non-event: POST check-in. For CHECK_IN_OUT, if already checked in, can record check-out.
  static String attendanceCheckIn(String attendanceId, String studentId) =>
      '$baseUrl/api/attendance/check-in/$attendanceId/student/$studentId';
  static String get attendanceCheckOut => '$baseUrl/api/attendance/check-out';
  static String attendanceByClassroomAndDate(String classroomId, String date) =>
      '$baseUrl/api/attendance/classroom/$classroomId/date?date=$date';
  static String get attendanceSync => '$baseUrl/api/attendance/sync';
  static String get attendanceSettings => '$baseUrl/api/attendance/settings';
  static String get attendanceEvents => '$baseUrl/api/attendance/events';
  static String get attendanceCreate => '$baseUrl/api/attendance/create';
  static String get attendanceEventSheet => '$baseUrl/api/attendance/event/sheet';
  static String get attendanceScanCard => '$baseUrl/api/attendance/scan/card';

  // Payment Endpoints
  static String get payStudentFee => '$baseUrl/api/mopay/fees/pay-student';
  static String syncFeePayment(String transactionId) =>
      '$baseUrl/api/mopay/public/sync-fee-payment/$transactionId';
  static String checkPaymentStatus(String transactionId) =>
      '$baseUrl/api/mopay/status/$transactionId';
  static String updateFee(String transactionId) =>
      '$baseUrl/api/mopay/direct/update-fee/$transactionId';

  // Fee Endpoints
  static String getStudentFees(String studentId) =>
      '$baseUrl/api/student-fees/student/$studentId';
}

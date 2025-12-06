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
  static String get studentAttendanceCheckIn =>
      '$baseUrl/api/student-attendance/check-in';
  static String get attendanceCheckOut => '$baseUrl/api/attendance/check-out';
  static String attendanceByClassroomAndDate(String classroomId, String date) =>
      '$baseUrl/api/attendance/classroom/$classroomId/date?date=$date';
  static String get attendanceSync => '$baseUrl/api/attendance/sync';

  // Payment Endpoints
  static String get payStudentFee => '$baseUrl/api/mopay/fees/pay-student';
  static String checkPaymentStatus(String transactionId) =>
      '$baseUrl/api/mopay/status/$transactionId';
}

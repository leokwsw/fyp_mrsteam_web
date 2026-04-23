class MrSteamAPIs {
  static const String baseUrl = 'https://fyp-backend-zknqk6dfca-de.a.run.app';
  static const String v1 = '/api/v1';

  // Auth
  static const String login = '$v1/auth/login';
  static const String refreshToken = '$v1/auth/refresh';
  static const String logout = '$v1/auth/logout';
  static const String validateToken = '$v1/auth/validate';
  static const String changePassword = '$v1/auth/change-password';
  static const String forgotPassword = '$v1/auth/forgot-password';
  static const String verifyOtp = '$v1/auth/verify-otp';
  static const String resetPasswordWithToken = '$v1/auth/reset-password';

  // Users
  static const String users = '$v1/users';
  static const String profile = '$v1/profile';

  static String userById(String id) => '$v1/user/$id';
  static const String userSelf = '$v1/user';

  static String userActive(String id) => '$v1/$id/active';

  static String userResetPassword(String id) => '$v1/user/$id/reset-password';

  static String userForceResetPassword(String id) =>
      '$v1/user/$id/force-reset-password';

  // Files
  static const String uploadFile = '$v1/files/upload';

  static String downloadFile(String path) => '$v1/files/download/$path';

  static String signedFileUrl(String path) => '$v1/files/signed-url/$path';

  static String deleteFile(String path) => '$v1/files/$path';

  // System
  static const String systemMetrics = '$v1/system/metrics';
  static const String systemLogs = '$v1/system/logs';
  static const String systemStats = '$v1/system/stats';

  // Health
  static const String health = '$v1/health';
  static const String healthTime = '$v1/health/time';

  // School
  static const String school = '$v1/school';

  static String schoolById(String id) => '$v1/school/$id';

  // Course
  static const String course = '$v1/course';

  static String courseById(String id) => '$v1/course/$id';

  static String courseStatus(String id) => '$v1/course/$id/status';

  static String courseFiles(String id) => '$v1/course/$id/files';

  static String courseFileDownload(String id, num fileIndex) =>
      '$v1/course/$id/files/$fileIndex/download';

  static String courseFileSignedUrl(String id, num fileIndex) =>
      '$v1/course/$id/files/$fileIndex/signed-url';

  // Attendance
  static const String attendance = '$v1/attendance';

  static String attendanceById(String id) => '$v1/attendance/$id';
  static const String attendanceExport = '$v1/attendance/export';

  // Leave
  static const String leave = '$v1/leave';

  static String leaveById(String id) => '$v1/leave/$id';

  static String leaveApprove(String id) => '$v1/leave/$id/approve';
  static const String leaveExport = '$v1/leave/export';

  // Notification
  static const String registerDeviceToken = '$v1/notification/register-device';
  static const String notificationTestBroadcast =
      '$v1/notification/test/broadcast';
  static const String notification = '$v1/notification';
  static const String notificationUnreadCount = '$v1/notification/unread-count';

  static String notificationRead(String id) => '$v1/notification/$id/read';
  static const String notificationReadAll = '$v1/notification/read-all';

  // Notification Template
  static const String notificationTemplate = '$v1/notification-template';
  static const String notificationTemplateActive =
      '$v1/notification-template/active';

  static String notificationTemplateById(String id) =>
      '$v1/notification-template/$id';

  // Statistics
  static const String statisticsDashboard = '$v1/statistics/dashboard';
  static const String statisticsAttendance = '$v1/statistics/attendance';
  static const String statisticsLeave = '$v1/statistics/leave';
  static const String statisticsCourse = '$v1/statistics/course';
}

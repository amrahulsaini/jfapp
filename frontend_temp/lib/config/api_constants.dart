class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://jecrcfoundation.live/api';
  
  // Auth Endpoints
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String checkSession = '/auth/check-session';
  static const String logout = '/auth/logout';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  
  // Student Photo URL
  static String getStudentPhotoUrl(String rollNo) {
    return 'https://jecrcfoundation.live/student_photos/photo_$rollNo.jpg';
  }
  
  // User Endpoints
  static const String profile = '/users/profile';
  static const String updateProfile = '/users/profile';
  
  // Data Endpoints
  static const String publicData = '/data/public';
  static const String protectedData = '/data/protected';
  static const String createItem = '/data/items';
  
  // Health Check
  static const String health = '/health';
  
  // Email Domain
  static const String allowedEmailDomain = '@jecrc.ac.in';
  
  // Batches
  static const List<String> availableBatches = [
    '2024-2028',
    '2023-2027',
    '2025-2029',
  ];
  
  // Currently active batch (only this batch can login)
  static const String activeBatch = '2024-2028';
  
  // Check if batch is active
  static bool isBatchActive(String batch) {
    return batch == activeBatch;
  }
  
  // Session duration (30 days)
  static const int sessionDurationDays = 30;
  
  // Request Headers
  static Map<String, String> headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}

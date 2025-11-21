class ApiConstants {
  // Base URL - Change this to your production URL
  static const String baseUrl = 'https://jecrcfoundation.live/api';
  
  // Auth Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  
  // User Endpoints
  static const String profile = '/users/profile';
  static const String updateProfile = '/users/profile';
  
  // Data Endpoints
  static const String publicData = '/data/public';
  static const String protectedData = '/data/protected';
  static const String createItem = '/data/items';
  
  // Health Check
  static const String health = '/health';
  
  // Request Headers
  static Map<String, String> headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}

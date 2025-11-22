import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_constants.dart';
import '../models/api_response.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

class ApiService {
  final StorageService _storage = StorageService();

  // Get auth token
  Future<String?> _getToken() async {
    return await _storage.getToken();
  }

  // Register new user
  Future<ApiResponse<UserModel>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
        headers: ApiConstants.headers(),
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Save token
        await _storage.saveToken(data['token']);
        
        // Parse user
        final user = UserModel.fromJson(data['user']);
        
        return ApiResponse.success(
          message: data['message'],
          data: user,
        );
      } else {
        return ApiResponse.error(
          error: data['error'] ?? 'Registration failed',
        );
      }
    } catch (e) {
      return ApiResponse.error(error: 'Network error: ${e.toString()}');
    }
  }

  // Login user
  Future<ApiResponse<UserModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
        headers: ApiConstants.headers(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save token
        await _storage.saveToken(data['token']);
        
        // Parse user
        final user = UserModel.fromJson(data['user']);
        
        return ApiResponse.success(
          message: data['message'],
          data: user,
        );
      } else {
        return ApiResponse.error(
          error: data['error'] ?? 'Login failed',
        );
      }
    } catch (e) {
      return ApiResponse.error(error: 'Network error: ${e.toString()}');
    }
  }

  // Get user profile
  Future<ApiResponse<UserModel>> getProfile() async {
    try {
      final token = await _getToken();
      
      if (token == null) {
        return ApiResponse.error(error: 'No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profile}'),
        headers: ApiConstants.headers(token: token),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(data['user']);
        return ApiResponse.success(data: user);
      } else {
        return ApiResponse.error(
          error: data['error'] ?? 'Failed to fetch profile',
        );
      }
    } catch (e) {
      return ApiResponse.error(error: 'Network error: ${e.toString()}');
    }
  }

  // Update profile
  Future<ApiResponse<UserModel>> updateProfile({
    required String name,
  }) async {
    try {
      final token = await _getToken();
      
      if (token == null) {
        return ApiResponse.error(error: 'No authentication token found');
      }

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateProfile}'),
        headers: ApiConstants.headers(token: token),
        body: jsonEncode({'name': name}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(data['user']);
        return ApiResponse.success(
          message: data['message'],
          data: user,
        );
      } else {
        return ApiResponse.error(
          error: data['error'] ?? 'Failed to update profile',
        );
      }
    } catch (e) {
      return ApiResponse.error(error: 'Network error: ${e.toString()}');
    }
  }

  // Send OTP to email
  Future<ApiResponse<Map<String, dynamic>>> sendOtp({
    required String email,
    required String batch,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.sendOtp}'),
        headers: ApiConstants.headers(),
        body: jsonEncode({
          'email': email,
          'batch': batch,
        }),
      );

      // Check if response is valid JSON
      if (response.body.isEmpty) {
        return ApiResponse.error(error: 'Server returned empty response');
      }

      // Try to parse JSON, handle HTML error pages
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (e) {
        return ApiResponse.error(error: 'Unable to reach server. Please check if backend is running.');
      }

      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(
          message: data['message'],
          data: data['data'],
        );
      } else {
        return ApiResponse.error(
          error: data['message'] ?? 'Failed to send OTP',
        );
      }
    } catch (e) {
      return ApiResponse.error(error: 'Connection error. Please check your internet and try again.');
    }
  }

  // Verify OTP and get session token
  Future<ApiResponse<Map<String, dynamic>>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyOtp}'),
        headers: ApiConstants.headers(),
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Save session token
        await _storage.saveToken(data['data']['sessionToken']);
        
        return ApiResponse.success(
          message: data['message'],
          data: data['data'],
        );
      } else {
        return ApiResponse.error(
          error: data['message'] ?? 'Invalid OTP',
        );
      }
    } catch (e) {
      return ApiResponse.error(error: 'Network error: ${e.toString()}');
    }
  }

  // Check session validity
  Future<ApiResponse<Map<String, dynamic>>> checkSession() async {
    try {
      final token = await _getToken();
      
      if (token == null) {
        return ApiResponse.error(error: 'No session token found');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.checkSession}'),
        headers: ApiConstants.headers(token: token),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return ApiResponse.success(
          message: data['message'],
          data: data['data'],
        );
      } else {
        // Session expired, clear token
        await _storage.deleteToken();
        return ApiResponse.error(
          error: data['message'] ?? 'Session expired',
        );
      }
    } catch (e) {
      return ApiResponse.error(error: 'Network error: ${e.toString()}');
    }
  }

  // Logout
  Future<ApiResponse<void>> logout() async {
    try {
      final token = await _getToken();
      
      if (token != null) {
        await http.post(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logout}'),
          headers: ApiConstants.headers(token: token),
        );
      }

      // Clear local storage
      await _storage.deleteToken();

      return ApiResponse.success(message: 'Logged out successfully');
    } catch (e) {
      await _storage.deleteToken();
      return ApiResponse.error(error: 'Error logging out: ${e.toString()}');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null;
  }
}

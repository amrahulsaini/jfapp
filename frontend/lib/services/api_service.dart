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

  // Logout
  Future<void> logout() async {
    await _storage.deleteToken();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null;
  }
}

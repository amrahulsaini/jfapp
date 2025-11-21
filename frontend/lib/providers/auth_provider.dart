import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();

  UserModel? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  // Check authentication status on app start
  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();

    final isLoggedIn = await _apiService.isLoggedIn();
    
    if (isLoggedIn) {
      // Fetch user profile
      final response = await _apiService.getProfile();
      if (response.success && response.data != null) {
        _user = response.data;
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
      }
    } else {
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Login
  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final response = await _apiService.login(
      email: email,
      password: password,
    );

    if (response.success && response.data != null) {
      _user = response.data;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return null; // Success
    } else {
      _isLoading = false;
      notifyListeners();
      return response.error ?? 'Login failed';
    }
  }

  // Register
  Future<String?> register(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();

    final response = await _apiService.register(
      email: email,
      password: password,
      name: name,
    );

    if (response.success && response.data != null) {
      _user = response.data;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return null; // Success
    } else {
      _isLoading = false;
      notifyListeners();
      return response.error ?? 'Registration failed';
    }
  }

  // Update profile
  Future<String?> updateProfile(String name) async {
    _isLoading = true;
    notifyListeners();

    final response = await _apiService.updateProfile(name: name);

    if (response.success && response.data != null) {
      _user = response.data;
      _isLoading = false;
      notifyListeners();
      return null; // Success
    } else {
      _isLoading = false;
      notifyListeners();
      return response.error ?? 'Update failed';
    }
  }

  // Logout
  Future<void> logout() async {
    await _apiService.logout();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}

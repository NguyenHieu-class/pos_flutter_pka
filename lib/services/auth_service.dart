import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'api_service.dart';

/// Service managing authentication workflow and persisted session state.
class AuthService {
  AuthService._() {
    _api.onUnauthorized = _handleUnauthorized;
  }

  static final AuthService instance = AuthService._();

  final ApiService _api = ApiService.instance;
  final ValueNotifier<User?> currentUser = ValueNotifier<User?>(null);

  static const _tokenKey = 'pos_token';
  static const _userKey = 'pos_user';

  Future<User?> loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (token == null || token.isEmpty || userJson == null) {
      return null;
    }
    try {
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      final user = User.fromJson(map, token: token);
      _applySession(user);
      return user;
    } catch (error) {
      debugPrint('Failed to parse stored user: $error');
      await logout();
      return null;
    }
  }

  Future<User> login(String username, String password) async {
    final result = await _api.post(
      '/auth/login',
      {
        'username': username,
        'password': password,
      },
      auth: false,
    );

    if (result is! Map<String, dynamic>) {
      throw ApiException('Phản hồi không hợp lệ từ máy chủ');
    }

    final token = (result['token'] ?? result['access_token']) as String?;
    if (token == null) {
      throw ApiException('Không nhận được token xác thực');
    }
    final userMap = (result['user'] as Map<String, dynamic>?) ?? result;
    final user = User.fromJson(userMap, token: token);
    await _persistSession(user);
    _applySession(user);
    return user;
  }

  Future<void> logout() async {
    _api.updateToken(null);
    currentUser.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<void> _persistSession(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, user.token ?? '');
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  void _applySession(User user) {
    _api.updateToken(user.token);
    currentUser.value = user;
  }

  Future<void> _handleUnauthorized() async {
    if (currentUser.value != null) {
      await logout();
    }
  }
}

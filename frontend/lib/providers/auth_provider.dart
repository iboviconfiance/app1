import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _user;
  String? _token;
  bool _loading = false;
  bool _initialized = false;

  bool get isAuthenticated => _token != null;
  Map<String, dynamic>? get user => _user;
  ApiService get api => _api;
  bool get loading => _loading;
  bool get initialized => _initialized;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    final userJson = prefs.getString('user');
    if (userJson != null) _user = jsonDecode(userJson);
    if (_token != null) _api.setToken(_token);
    _initialized = true;
    notifyListeners();
  }

  Future<void> login(String telephone, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.post('/auth/login', {'telephone': telephone, 'password': password});
      await _saveSession(res['data']);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await _api.post('/auth/register', data);
      await _saveSession(res['data']);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> forgotPassword(String telephone) async {
    await _api.post('/auth/forgot-password', {'telephone': telephone});
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _api.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final res = await _api.get('/users/profile');
    _user = res['data'];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(_user));
    notifyListeners();
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    _token = data['token'];
    _user = data['user'];
    _api.setToken(_token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setString('user', jsonEncode(_user));
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _loading = false;
  bool _initialized = false;

  User? get user => _user;
  bool get isLoading => _loading;
  bool get isAuthenticated => _user != null;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    final token = await ApiClient.getToken();
    // Discard the token created by earlier mock-data builds. It is not valid
    // against the production API and would otherwise keep the user "logged in".
    if (!AppConstants.useMockData && token?.startsWith('mock-token-') == true) {
      await ApiClient.clearToken();
      await _clearPersisted();
    } else if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('user_id');
      final fullName = prefs.getString('user_full_name') ?? '';
      final username = prefs.getString('user_username') ?? '';
      final email = prefs.getString('user_email') ?? '';
      final role = prefs.getString('user_role') ?? 'User';
      if (id != null) {
        _user = User(
          id: id,
          fullName: fullName,
          username: username,
          email: email,
          role: role,
        );
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await AuthService.login(email, password);
      await ApiClient.saveToken(res.token);
      await _persist(res.user);
      _user = res.user;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final res = await AuthService.register(
        fullName: fullName,
        username: username,
        email: email,
        password: password,
      );
      await ApiClient.saveToken(res.token);
      await _persist(res.user);
      _user = res.user;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiClient.clearToken();
    await _clearPersisted();
    _user = null;
    notifyListeners();
  }

  void updateUser(User user) {
    _user = user;
    _persist(user);
    notifyListeners();
  }

  Future<void> _persist(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user.id);
    await prefs.setString('user_full_name', user.fullName);
    await prefs.setString('user_username', user.username);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_role', user.role);
  }

  Future<void> _clearPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_full_name');
    await prefs.remove('user_username');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
  }
}

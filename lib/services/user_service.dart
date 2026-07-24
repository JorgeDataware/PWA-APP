import '../core/constants.dart';
import '../core/mock_data.dart';
import '../models/user.dart';
import 'api_client.dart';

class UserService {
  static Future<List<User>> getUsers() async {
    if (AppConstants.useMockData) return MockData.users();
    final data = await ApiClient.get('/api/web/users') as List;
    return data.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<User> getUserById(int id) async {
    if (AppConstants.useMockData) return MockData.userById(id);
    final data = await ApiClient.get('/api/web/users/$id');
    return User.fromJson(data as Map<String, dynamic>);
  }

  static Future<User> createUser({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required int role,
    bool mustChangePassword = false,
  }) async {
    if (AppConstants.useMockData) {
      return MockData.createUser(
        fullName: fullName,
        username: username,
        email: email,
        password: password,
        role: role,
      );
    }
    final data = await ApiClient.post('/api/web/users', {
      'fullName': fullName,
      'username': username,
      'email': email,
      'password': password,
      'role': role,
      'mustChangePassword': mustChangePassword,
    });
    return User.fromJson(data as Map<String, dynamic>);
  }

  static Future<User> updateUser(
    int id, {
    String? fullName,
    String? username,
    String? email,
    String? password,
    int? role,
    bool? mustChangePassword,
  }) async {
    if (AppConstants.useMockData) {
      return MockData.updateUser(
        id,
        fullName: fullName,
        username: username,
        email: email,
        password: password,
        role: role,
      );
    }
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    if (password != null && password.isNotEmpty) body['password'] = password;
    if (role != null) body['role'] = role;
    if (mustChangePassword != null) {
      body['mustChangePassword'] = mustChangePassword;
    }
    final data = await ApiClient.put('/api/web/users/$id', body);
    return User.fromJson(data as Map<String, dynamic>);
  }

  static Future<User> setUserStatus(int id, bool isActive) async {
    if (AppConstants.useMockData) {
      throw UnsupportedError(
        'El estado de usuarios no está disponible con datos de prueba.',
      );
    }
    final data = await ApiClient.patch('/api/web/users/$id/status', {
      'isActive': isActive,
    });
    return User.fromJson(data as Map<String, dynamic>);
  }

  static Future<User> getProfile() async {
    if (AppConstants.useMockData) return MockData.profile();
    final data = await ApiClient.get('/api/profile');
    return User.fromJson(data as Map<String, dynamic>);
  }

  static Future<User> updateProfile({
    String? fullName,
    String? username,
    String? email,
    String? password,
  }) async {
    if (AppConstants.useMockData) {
      return MockData.updateProfile(
        fullName: fullName,
        username: username,
        email: email,
        password: password,
      );
    }
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    if (password != null && password.isNotEmpty) body['password'] = password;
    final data = await ApiClient.put('/api/profile', body);
    return User.fromJson(data as Map<String, dynamic>);
  }
}

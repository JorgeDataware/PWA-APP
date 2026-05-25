import '../models/user.dart';
import 'api_client.dart';

class UserService {
  static Future<List<User>> getUsers() async {
    final data = await ApiClient.get('/api/web/users') as List;
    return data.map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<User> getUserById(int id) async {
    final data = await ApiClient.get('/api/web/users/$id');
    return User.fromJson(data as Map<String, dynamic>);
  }

  static Future<User> createUser({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required int role,
  }) async {
    final data = await ApiClient.post('/api/web/users', {
      'fullName': fullName,
      'username': username,
      'email': email,
      'password': password,
      'role': role,
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
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    if (password != null && password.isNotEmpty) body['password'] = password;
    if (role != null) body['role'] = role;
    final data = await ApiClient.put('/api/web/users/$id', body);
    return User.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deleteUser(int id) async {
    await ApiClient.delete('/api/web/users/$id');
  }

  static Future<User> getProfile() async {
    final data = await ApiClient.get('/api/profile');
    return User.fromJson(data as Map<String, dynamic>);
  }

  static Future<User> updateProfile({
    String? fullName,
    String? username,
    String? email,
    String? password,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (username != null) body['username'] = username;
    if (email != null) body['email'] = email;
    if (password != null && password.isNotEmpty) body['password'] = password;
    final data = await ApiClient.put('/api/profile', body);
    return User.fromJson(data as Map<String, dynamic>);
  }
}

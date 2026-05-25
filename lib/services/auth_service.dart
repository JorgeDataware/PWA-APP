import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  static Future<LoginResponse> login(String email, String password) async {
    final data = await ApiClient.post(
      '/api/auth/login',
      {'email': email, 'password': password},
      auth: false,
    );
    return LoginResponse.fromJson(data as Map<String, dynamic>);
  }

  static Future<LoginResponse> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.post(
      '/api/auth/register',
      {
        'fullName': fullName,
        'username': username,
        'email': email,
        'password': password,
      },
      auth: false,
    );
    return LoginResponse.fromJson(data as Map<String, dynamic>);
  }
}

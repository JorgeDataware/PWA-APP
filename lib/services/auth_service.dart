import '../core/constants.dart';
import '../core/mock_data.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  static Future<LoginResponse> login(String email, String password) async {
    if (AppConstants.useMockData) return MockData.login(email, password);
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
    if (AppConstants.useMockData) {
      return MockData.register(
        fullName: fullName,
        username: username,
        email: email,
        password: password,
      );
    }
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

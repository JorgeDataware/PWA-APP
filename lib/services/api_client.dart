import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}

class ApiClient {
  static const _tokenKey = 'auth_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  static Uri _uri(String path) =>
      Uri.parse('${AppConstants.baseUrl}$path');

  static Future<dynamic> get(String path) async {
    final res = await http.get(_uri(path), headers: await _headers());
    return _handle(res);
  }

  static Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final res = await http.post(
      _uri(path),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  static Future<dynamic> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await http.put(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  static Future<void> delete(String path) async {
    final res = await http.delete(_uri(path), headers: await _headers());
    _handleNoContent(res);
  }

  static dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty || res.body == 'null') return null;
      return jsonDecode(res.body);
    }
    throw ApiException(
      statusCode: res.statusCode,
      message: _extractError(res),
    );
  }

  static void _handleNoContent(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        statusCode: res.statusCode,
        message: _extractError(res),
      );
    }
  }

  static String _extractError(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map) {
        if (body['errors'] != null) {
          final errors = body['errors'];
          if (errors is Map) {
            return errors.values
                .expand((v) => v is List ? v : [v])
                .join(', ');
          }
          return errors.toString();
        }
        if (body['message'] != null) return body['message'].toString();
        if (body['title'] != null) return body['title'].toString();
      }
    } catch (_) {}
    return switch (res.statusCode) {
      400 => 'Datos inválidos o ya en uso',
      401 => 'Credenciales incorrectas',
      403 => 'Sin permisos para esta acción',
      404 => 'Recurso no encontrado',
      500 => 'Error interno del servidor',
      _ => 'Error ${res.statusCode}',
    };
  }
}

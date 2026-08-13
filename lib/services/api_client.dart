import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  /// Correlation code returned by the API (`X-Trace-Id`). The same value is in
  /// the server log and in the audit trail, so a user can report it and an
  /// administrator can find the exact failed operation in `/admin/dashboard`.
  final String? traceId;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.traceId,
  });

  /// Only server-side failures are worth showing a code for: a validation
  /// error is actionable on its own, a 500 is not.
  bool get isServerFailure => statusCode >= 500;

  @override
  String toString() => traceId != null && isServerFailure
      ? '$message (código: $traceId)'
      : message;
}

class ApiClient {
  static const _tokenKey = 'auth_token';

  /// Applied to every request so a slow/unresponsive backend fails fast
  /// with a clear error instead of leaving the UI stuck on a loading
  /// spinner indefinitely (e.g. a Render free-tier cold start that never
  /// completes, or a network with no connectivity at all).
  static const _timeout = Duration(seconds: 15);

  static const _timeoutMessage =
      'El servidor tardó demasiado en responder. Intenta de nuevo.';

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

  static Future<Map<String, String>> _headers({
    bool auth = true,
    bool jsonContent = false,
  }) async {
    final h = <String, String>{};
    if (jsonContent) h['Content-Type'] = 'application/json';
    if (auth) {
      final token = await getToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  static Uri _uri(String path) => Uri.parse('${AppConstants.baseUrl}$path');

  static Future<dynamic> get(String path) async {
    final res = await http
        .get(_uri(path), headers: await _headers())
        .timeout(_timeout, onTimeout: _throwTimeout);
    return _handle(res);
  }

  static Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final res = await http
        .post(
          _uri(path),
          headers: await _headers(auth: auth, jsonContent: true),
          body: jsonEncode(body),
        )
        .timeout(_timeout, onTimeout: _throwTimeout);
    return _handle(res);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await http
        .put(
          _uri(path),
          headers: await _headers(jsonContent: true),
          body: jsonEncode(body),
        )
        .timeout(_timeout, onTimeout: _throwTimeout);
    return _handle(res);
  }

  static Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final res = await http
        .patch(
          _uri(path),
          headers: await _headers(jsonContent: true),
          body: jsonEncode(body),
        )
        .timeout(_timeout, onTimeout: _throwTimeout);
    return _handle(res);
  }

  static Future<void> delete(String path) async {
    final res = await http
        .delete(_uri(path), headers: await _headers())
        .timeout(_timeout, onTimeout: _throwTimeout);
    _handleNoContent(res);
  }

  static Never _throwTimeout() => throw const ApiException(
        statusCode: 408,
        message: _timeoutMessage,
      );

  static dynamic _handle(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty || res.body == 'null') return null;
      return jsonDecode(res.body);
    }
    throw ApiException(
      statusCode: res.statusCode,
      message: _extractError(res),
      traceId: _extractTraceId(res),
    );
  }

  static void _handleNoContent(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(
        statusCode: res.statusCode,
        message: _extractError(res),
        traceId: _extractTraceId(res),
      );
    }
  }

  /// The API sends the code both as a header and, for unhandled exceptions, in
  /// the body. The header is authoritative; the body is the fallback.
  static String? _extractTraceId(http.Response res) {
    final header = res.headers['x-trace-id'];
    if (header != null && header.isNotEmpty) return header;
    try {
      final body = jsonDecode(res.body);
      if (body is Map && body['traceId'] != null) {
        return body['traceId'].toString();
      }
    } catch (_) {}
    return null;
  }

  static String _extractError(http.Response res) {
    try {
      final body = jsonDecode(res.body);
      if (body is Map) {
        if (body['errors'] != null) {
          final errors = body['errors'];
          if (errors is Map) {
            return errors.values.expand((v) => v is List ? v : [v]).join(', ');
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

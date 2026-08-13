import 'package:flutter_test/flutter_test.dart';
import 'package:pwa_app/models/audit_log.dart';
import 'package:pwa_app/services/api_client.dart';

void main() {
  group('AuditLog.fromJson', () {
    test('parses a successful entry', () {
      final entry = AuditLog.fromJson({
        'id': 12,
        'occurredAt': '2026-08-13T18:05:00Z',
        'traceId': '0HNE1A2B3C4D5',
        'userId': 1,
        'username': 'admin',
        'role': 'Admin',
        'method': 'POST',
        'path': '/api/web/news',
        'action': 'Publicación de noticia',
        'statusCode': 201,
        'success': true,
        'durationMs': 142,
        'ipAddress': '127.0.0.1',
        'error': null,
      });

      expect(entry.id, 12);
      expect(entry.traceId, '0HNE1A2B3C4D5');
      expect(entry.success, isTrue);
      expect(entry.error, isNull);
      expect(entry.actorLabel, 'admin');
    });

    test('parses an anonymous failed entry (login rechazado)', () {
      final entry = AuditLog.fromJson({
        'id': 13,
        'occurredAt': '2026-08-13T18:07:00Z',
        'traceId': '0HNE1A2B3C4D6',
        'userId': null,
        'username': null,
        'role': null,
        'method': 'POST',
        'path': '/api/auth/login',
        'action': 'Inicio de sesión',
        'statusCode': 401,
        'success': false,
        'durationMs': 88,
        'error': 'Credenciales inválidas o sesión expirada',
      });

      expect(entry.success, isFalse);
      expect(entry.statusCode, 401);
      expect(entry.error, isNotNull);
      // Sin usuario autenticado la traza sigue siendo atribuible: queda el
      // código, la ruta y la hora.
      expect(entry.actorLabel, 'Anónimo');
    });

    test('falls back to the user id when there is no username', () {
      final entry = AuditLog.fromJson({
        'id': 14,
        'occurredAt': '2026-08-13T18:09:00Z',
        'traceId': 'X',
        'userId': 7,
        'method': 'DELETE',
        'path': '/api/web/news/3',
        'action': 'Eliminación de noticia',
        'statusCode': 403,
        'success': false,
        'durationMs': 20,
      });

      expect(entry.actorLabel, 'Usuario 7');
    });
  });

  group('ApiException con código de rastreo', () {
    test('muestra el código sólo en fallas del servidor', () {
      const serverFailure = ApiException(
        statusCode: 500,
        message: 'Error interno del servidor',
        traceId: 'ABC123',
      );

      expect(serverFailure.isServerFailure, isTrue);
      expect(serverFailure.toString(), contains('ABC123'));
      expect(serverFailure.toString(), startsWith('Error interno del servidor'));
    });

    test('no ensucia el mensaje de un error de validación', () {
      const validationFailure = ApiException(
        statusCode: 400,
        message: 'Datos inválidos o ya en uso',
        traceId: 'ABC123',
      );

      expect(validationFailure.isServerFailure, isFalse);
      expect(validationFailure.toString(), 'Datos inválidos o ya en uso');
    });

    test('sigue funcionando sin código de rastreo', () {
      const noTrace = ApiException(statusCode: 500, message: 'Falla');
      expect(noTrace.toString(), 'Falla');
    });
  });
}

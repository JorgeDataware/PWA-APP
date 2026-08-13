import '../core/constants.dart';
import '../core/mock_data.dart';
import '../models/audit_log.dart';
import 'api_client.dart';

/// Reads the API audit trail. Admin only — the endpoints reject any other role.
class AuditService {
  /// Most recent operations first. With [onlyFailures] the API returns just the
  /// ones that did not succeed, which is the view used to investigate an
  /// incident.
  static Future<List<AuditLog>> getRecent({
    int limit = 50,
    bool onlyFailures = false,
  }) async {
    if (AppConstants.useMockData) {
      return MockData.auditLogs(limit: limit, onlyFailures: onlyFailures);
    }
    final data = await ApiClient.get(
      '/api/web/audit?limit=$limit&onlyFailures=$onlyFailures',
    ) as List;
    return data
        .map((e) => AuditLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Looks up a single operation by the code shown to the user when a request
  /// fails (`ApiException.traceId`).
  static Future<AuditLog> getByTraceId(String traceId) async {
    if (AppConstants.useMockData) return MockData.auditLogByTraceId(traceId);
    final data = await ApiClient.get('/api/web/audit/$traceId');
    return AuditLog.fromJson(data as Map<String, dynamic>);
  }
}

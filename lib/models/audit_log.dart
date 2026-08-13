/// One entry of the API audit trail: an operation that changed state (or tried
/// to), successful or failed. Mirrors `AuditLogDto` of the backend.
class AuditLog {
  final int id;
  final DateTime occurredAt;
  final String traceId;
  final int? userId;
  final String? username;
  final String? role;
  final String method;
  final String path;
  final String action;
  final int statusCode;
  final bool success;
  final int durationMs;
  final String? ipAddress;
  final String? error;

  const AuditLog({
    required this.id,
    required this.occurredAt,
    required this.traceId,
    this.userId,
    this.username,
    this.role,
    required this.method,
    required this.path,
    required this.action,
    required this.statusCode,
    required this.success,
    required this.durationMs,
    this.ipAddress,
    this.error,
  });

  /// Who performed the action, ready to display. Anonymous requests (a failed
  /// login, for instance) have no user attached.
  String get actorLabel => username ?? (userId != null ? 'Usuario $userId' : 'Anónimo');

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
        id: (json['id'] as num).toInt(),
        occurredAt: DateTime.parse(json['occurredAt'] as String),
        traceId: json['traceId'] as String? ?? '',
        userId: (json['userId'] as num?)?.toInt(),
        username: json['username'] as String?,
        role: json['role'] as String?,
        method: json['method'] as String? ?? '',
        path: json['path'] as String? ?? '',
        action: json['action'] as String? ?? '',
        statusCode: (json['statusCode'] as num?)?.toInt() ?? 0,
        success: json['success'] as bool? ?? false,
        durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
        ipAddress: json['ipAddress'] as String?,
        error: json['error'] as String?,
      );
}

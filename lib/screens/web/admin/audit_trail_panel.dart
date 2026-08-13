import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../models/audit_log.dart';
import '../../../services/audit_service.dart';

/// Shows the tail of the API audit trail inside the admin dashboard, with a
/// switch to narrow it down to failed operations. This is the "pruebas
/// auditables en caso de falla" view: every entry carries the trace code that
/// the client shows to the user when a request fails, so a reported incident
/// can be matched to the exact operation, actor and timestamp.
class AuditTrailPanel extends StatefulWidget {
  const AuditTrailPanel({super.key});

  @override
  State<AuditTrailPanel> createState() => _AuditTrailPanelState();
}

class _AuditTrailPanelState extends State<AuditTrailPanel> {
  List<AuditLog>? _entries;
  bool _loading = true;
  bool _onlyFailures = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await AuditService.getRecent(
        limit: 15,
        onlyFailures: _onlyFailures,
      );
      if (mounted) {
        setState(() {
          _entries = entries;
          _error = null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _toggleFilter(bool value) {
    setState(() {
      _onlyFailures = value;
      _loading = true;
      _entries = null;
      _error = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registro de auditoría',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Operaciones que modificaron datos, exitosas y fallidas',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                tooltip: 'Actualizar registro',
                onPressed: _loading ? null : _load,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: _onlyFailures,
                onChanged: _loading ? null : _toggleFilter,
              ),
              const SizedBox(width: 4),
              const Text('Sólo fallas', style: TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _PanelMessage(
              icon: Icons.error_outline,
              color: AppTheme.error,
              message: _error!,
              onRetry: _load,
            )
          else if (_entries!.isEmpty)
            _PanelMessage(
              icon: Icons.check_circle_outline,
              color: AppTheme.success,
              message: _onlyFailures
                  ? 'Sin operaciones fallidas registradas'
                  : 'Aún no hay operaciones registradas',
            )
          else
            Column(
              children: [
                for (final entry in _entries!) _AuditRow(entry: entry),
              ],
            ),
        ],
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  final AuditLog entry;

  const _AuditRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final color = entry.success ? AppTheme.success : AppTheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              entry.success ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.action,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.statusCode}',
                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.actorLabel} · ${formatDateRelative(entry.occurredAt)} · ${entry.durationMs} ms',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                if (entry.error != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    entry.error!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 3),
                SelectableText(
                  'código: ${entry.traceId}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelMessage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  final VoidCallback? onRetry;

  const _PanelMessage({
    required this.icon,
    required this.color,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            TextButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ],
      ),
    );
  }
}

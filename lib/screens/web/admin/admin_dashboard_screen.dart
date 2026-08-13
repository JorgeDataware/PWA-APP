import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/dashboard_metrics.dart';
import '../../../core/theme.dart';
import '../../../core/utils.dart';
import '../../../models/news.dart';
import '../../../models/user.dart';
import '../../../services/news_service.dart';
import '../../../services/user_service.dart';

/// Admin landing page: the figures of the site at a glance (content volume,
/// publishing cadence, user base) computed from the endpoints the app
/// already consumes — see [DashboardMetrics].
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  DashboardMetrics? _metrics;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Both lists are independent, so they're fetched concurrently.
      final results = await Future.wait([
        NewsService.getWebNews(),
        UserService.getUsers(),
      ]);
      if (!mounted) return;
      setState(() {
        _metrics = DashboardMetrics(
          news: results[0] as List<News>,
          users: results[1] as List<User>,
        );
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _reload() {
    setState(() { _loading = true; _error = null; _metrics = null; });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _reload,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _reload)
              : _DashboardBody(metrics: _metrics!),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final DashboardMetrics metrics;

  const _DashboardBody({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final last = metrics.lastPublishedAt;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatGrid(
            columns: isDesktop ? 4 : 2,
            tiles: [
              _StatTile(
                label: 'Noticias publicadas',
                value: '${metrics.totalNews}',
                icon: Icons.newspaper,
                caption: '${metrics.newsLast7Days} en los últimos 7 días',
              ),
              _StatTile(
                label: 'Publicaciones (30 días)',
                value: '${metrics.newsLast30Days}',
                icon: Icons.calendar_month,
                caption: last != null
                    ? 'Última: ${formatDateRelative(last)}'
                    : 'Sin publicaciones',
              ),
              _StatTile(
                label: 'Usuarios registrados',
                value: '${metrics.totalUsers}',
                icon: Icons.people,
                caption: '${metrics.adminUsers} administrador(es)',
              ),
              _StatTile(
                label: 'Usuarios activos',
                value: '${metrics.activeUsers}',
                icon: Icons.verified_user,
                caption: metrics.inactiveUsers > 0
                    ? '${metrics.inactiveUsers} deshabilitado(s)'
                    : 'Ninguno deshabilitado',
                valueColor:
                    metrics.inactiveUsers > 0 ? AppTheme.textPrimary : AppTheme.success,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _Panel(
            title: 'Publicaciones por mes',
            subtitle: 'Últimos 6 meses',
            child: _MonthlyBarChart(data: metrics.publicationsByMonth()),
          ),
          const SizedBox(height: 20),
          isDesktop
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _AuthorsPanel(metrics: metrics)),
                      const SizedBox(width: 20),
                      Expanded(child: _LatestNewsPanel(metrics: metrics)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _AuthorsPanel(metrics: metrics),
                    const SizedBox(height: 20),
                    _LatestNewsPanel(metrics: metrics),
                  ],
                ),
          const SizedBox(height: 20),
          _Panel(
            title: 'Usuarios por rol',
            child: Column(
              children: [
                _RoleRow(label: 'Administradores', count: metrics.usersWithRole('Admin')),
                _RoleRow(label: 'Usuarios', count: metrics.usersWithRole('User')),
                _RoleRow(label: 'Invitados', count: metrics.usersWithRole('Guest')),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go('/admin/news'),
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Administrar noticias'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.go('/admin/users'),
                icon: const Icon(Icons.people_outline, size: 18),
                label: const Text('Administrar usuarios'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat tiles
// ---------------------------------------------------------------------------

class _StatGrid extends StatelessWidget {
  final int columns;
  final List<_StatTile> tiles;

  const _StatGrid({required this.columns, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 16.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: tiles
              .map((t) => SizedBox(width: width > 0 ? width : constraints.maxWidth, child: t))
              .toList(),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String caption;
  final Color? valueColor;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.caption,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
              Icon(icon, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Charts
// ---------------------------------------------------------------------------

/// Single-series bar chart. One hue for the whole series (magnitude, not
/// identity), values labelled directly on top of each bar so no y-axis or
/// gridlines are needed.
class _MonthlyBarChart extends StatelessWidget {
  final List<MonthlyCount> data;

  const _MonthlyBarChart({required this.data});

  static const double _plotHeight = 150;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const _PanelEmpty(message: 'Sin datos para graficar');
    }
    final max = data.map((d) => d.count).reduce((a, b) => a > b ? a : b);

    return Semantics(
      label: 'Publicaciones por mes: '
          '${data.map((d) => '${DateFormat('MMMM yyyy', 'es').format(d.month)}: ${d.count}').join(', ')}',
      child: SizedBox(
        height: _plotHeight + 46,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < data.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _Bar(
                  entry: data[i],
                  max: max,
                  plotHeight: _plotHeight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final MonthlyCount entry;
  final int max;
  final double plotHeight;

  const _Bar({required this.entry, required this.max, required this.plotHeight});

  @override
  Widget build(BuildContext context) {
    // An empty month still shows a hairline so the gap reads as "zero"
    // rather than as missing data.
    final ratio = max == 0 ? 0.0 : entry.count / max;
    final height = entry.count == 0 ? 2.0 : (plotHeight * ratio).clamp(6.0, plotHeight);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '${entry.count}',
          style: TextStyle(
            color: entry.count == 0 ? AppTheme.textSecondary : AppTheme.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: entry.count == 0 ? AppTheme.divider : AppTheme.primary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          DateFormat('MMM', 'es').format(entry.month),
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _AuthorsPanel extends StatelessWidget {
  final DashboardMetrics metrics;

  const _AuthorsPanel({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final authors = metrics.topAuthors();
    return _Panel(
      title: 'Autores más activos',
      subtitle: '${metrics.distinctAuthors} autor(es) con publicaciones',
      child: authors.isEmpty
          ? const _PanelEmpty(message: 'Aún no hay publicaciones')
          : Column(
              children: [
                for (final a in authors)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AuthorBar(entry: a, max: authors.first.count),
                  ),
              ],
            ),
    );
  }
}

class _AuthorBar extends StatelessWidget {
  final AuthorCount entry;
  final int max;

  const _AuthorBar({required this.entry, required this.max});

  @override
  Widget build(BuildContext context) {
    final ratio = max == 0 ? 0.0 : entry.count / max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entry.author,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${entry.count}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: AppTheme.divider,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
      ],
    );
  }
}

class _LatestNewsPanel extends StatelessWidget {
  final DashboardMetrics metrics;

  const _LatestNewsPanel({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final latest = metrics.latestNews();
    return _Panel(
      title: 'Últimas publicaciones',
      child: latest.isEmpty
          ? const _PanelEmpty(message: 'Aún no hay publicaciones')
          : Column(
              children: [
                for (final n in latest)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      n.title,
                      style: const TextStyle(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${n.authorName} · ${formatDate(n.publishedAt)}',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 18, color: AppTheme.textSecondary),
                    onTap: () => context.push('/news/${n.id}'),
                  ),
              ],
            ),
    );
  }
}

class _RoleRow extends StatelessWidget {
  final String label;
  final int count;

  const _RoleRow({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(
            '$count',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared chrome
// ---------------------------------------------------------------------------

class _Panel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _Panel({required this.title, this.subtitle, required this.child});

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
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PanelEmpty extends StatelessWidget {
  final String message;

  const _PanelEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 40),
            const SizedBox(height: 12),
            Text(
              error,
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

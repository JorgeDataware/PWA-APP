import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../models/news.dart';
import '../../services/news_service.dart';
import '../../widgets/news_card.dart';

class WearableNewsListScreen extends StatefulWidget {
  const WearableNewsListScreen({super.key});

  @override
  State<WearableNewsListScreen> createState() => _WearableNewsListScreenState();
}

class _WearableNewsListScreenState extends State<WearableNewsListScreen> {
  List<News>? _news;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final news = await NewsService.getWearableNews();
      if (mounted) {
        setState(() {
          _news = news;
          _error = null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        centerTitle: true,
        title: const Text(
          'TechNews',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: () {
              setState(() { _loading = true; _error = null; _news = null; });
              _load();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorState(error: _error!, onRetry: () {
                    setState(() { _loading = true; _error = null; });
                    _load();
                  })
                : _news == null || _news!.isEmpty
                    ? const _EmptyState()
                    : _NewsList(
                        news: _news!,
                        onNewsClosed: _load,
                      ),
      ),
    );
  }
}

class _NewsList extends StatelessWidget {
  final List<News> news;
  final Future<void> Function() onNewsClosed;

  const _NewsList({required this.news, required this.onNewsClosed});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // Extra clearance prevents content from entering the curved screen edges.
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      itemCount: news.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => WearableNewsCard(
        news: news[i],
        onTap: () {
          context.push('/news/${news[i].id}').then((_) => onNewsClosed());
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, color: AppTheme.error, size: 32),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 32),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Reintentar', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, color: AppTheme.textSecondary, size: 36),
          SizedBox(height: 8),
          Text(
            'Sin noticias',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

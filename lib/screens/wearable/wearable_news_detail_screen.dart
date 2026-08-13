import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/news.dart';
import '../../services/news_service.dart';
import '../web/wearable_preview_screen.dart';

class WearableNewsDetailScreen extends StatefulWidget {
  final int newsId;
  const WearableNewsDetailScreen({super.key, required this.newsId});

  @override
  State<WearableNewsDetailScreen> createState() => _WearableNewsDetailScreenState();
}

class _WearableNewsDetailScreenState extends State<WearableNewsDetailScreen> {
  News? _news;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final news = await NewsService.getWearableNewsById(widget.newsId);
      if (mounted) setState(() { _news = news; _loading = false; });
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 18),
          onPressed: () => closeWearableNewsDetail(context),
        ),
        title: const Text('Noticia', style: TextStyle(fontSize: 14)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.error, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : _news != null
                    ? _NewsDetail(news: _news!)
                    : const SizedBox(),
      ),
    );
  }
}

class _NewsDetail extends StatelessWidget {
  final News news;
  const _NewsDetail({required this.news});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Keep text and controls within the usable area of a round display.
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (news.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  news.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.cardBg,
                    child: const Center(
                      child: Icon(Icons.broken_image_outlined, color: AppTheme.textSecondary, size: 28),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            news.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  news.authorName,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.schedule, size: 12, color: AppTheme.textSecondary),
              const SizedBox(width: 3),
              Text(
                formatDate(news.publishedAt),
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Visita la versión web para leer el artículo completo.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

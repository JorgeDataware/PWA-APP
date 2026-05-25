import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/news.dart';
import '../../services/news_service.dart';
import '../../services/favorites_service.dart';

class NewsDetailScreen extends StatefulWidget {
  final int newsId;
  const NewsDetailScreen({super.key, required this.newsId});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  News? _news;
  bool _loading = true;
  bool _isFavorite = false;
  bool _favoriteLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final news = await NewsService.getWebNewsById(widget.newsId);
      final favorites = await FavoritesService.getFavorites();
      if (mounted) {
        setState(() {
          _news = news;
          _isFavorite = favorites.any((f) => f.newsId == widget.newsId);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() => _favoriteLoading = true);
    try {
      if (_isFavorite) {
        await FavoritesService.removeFavorite(widget.newsId);
      } else {
        await FavoritesService.addFavorite(widget.newsId);
      }
      if (mounted) setState(() => _isFavorite = !_isFavorite);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _favoriteLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/news'),
        ),
        title: const Text('Noticia'),
        actions: [
          if (_news != null)
            _favoriteLoading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.bookmark : Icons.bookmark_border,
                      color: _isFavorite ? AppTheme.accent : null,
                    ),
                    tooltip: _isFavorite ? 'Quitar favorito' : 'Agregar a favoritos',
                    onPressed: _toggleFavorite,
                  ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.error, size: 56),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : _news == null
                  ? const SizedBox()
                  : _ArticleView(news: _news!, isDesktop: isDesktop),
    );
  }
}

class _ArticleView extends StatelessWidget {
  final News news;
  final bool isDesktop;

  const _ArticleView({required this.news, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isDesktop ? 820 : double.infinity),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (news.imageUrl != null)
                AspectRatio(
                  aspectRatio: isDesktop ? 21 / 9 : 16 / 9,
                  child: Image.network(
                    news.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.cardBg,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppTheme.textSecondary,
                          size: 56,
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(isDesktop ? 40 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      news.title,
                      style: TextStyle(
                        fontSize: isDesktop ? 32 : 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: const Border(
                          left: BorderSide(color: AppTheme.primary, width: 3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_outlined,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            news.authorName,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formatDate(news.publishedAt),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (news.content != null && news.content!.isNotEmpty)
                      Text(
                        news.content!,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: isDesktop ? 17 : 15,
                          height: 1.8,
                          letterSpacing: 0.1,
                        ),
                      )
                    else
                      const Text(
                        'Contenido no disponible.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

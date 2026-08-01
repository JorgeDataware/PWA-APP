import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/utils.dart';
import '../../models/news.dart';
import '../../providers/auth_provider.dart';
import '../../services/news_service.dart';
import '../../services/favorites_service.dart';
import '../../widgets/news_card.dart';
import '../../widgets/app_footer.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  List<News>? _news;
  Set<int> _favoriteIds = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
    try {
      final news = await NewsService.getWebNews();
      final favoriteIds = isAuthenticated
          ? (await FavoritesService.getFavorites()).map((f) => f.newsId).toSet()
          : <int>{};
      if (mounted) {
        setState(() {
          _news = news;
          _favoriteIds = favoriteIds;
          _error = null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _promptLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Inicia sesión para guardar noticias en favoritos'),
        action: SnackBarAction(label: 'Iniciar sesión', onPressed: () => context.go('/login')),
      ),
    );
  }

  Future<void> _toggleFavorite(int newsId) async {
    final isFav = _favoriteIds.contains(newsId);
    setState(() {
      if (isFav) {
        _favoriteIds.remove(newsId);
      } else {
        _favoriteIds.add(newsId);
      }
    });
    try {
      if (isFav) {
        await FavoritesService.removeFavorite(newsId);
      } else {
        await FavoritesService.addFavorite(newsId);
      }
    } catch (e) {
      setState(() {
        if (isFav) {
          _favoriteIds.add(newsId);
        } else {
          _favoriteIds.remove(newsId);
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final crossAxisCount = isDesktop ? 2 : 1;
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.rss_feed_rounded, color: AppTheme.primary, size: 22),
            const SizedBox(width: 8),
            const Text('TechNews'),
          ],
        ),
        actions: [
          if (!isAuthenticated) ...[
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Iniciar sesión'),
            ),
            if (isDesktop)
              OutlinedButton(
                onPressed: () => context.go('/register'),
                child: const Text('Registrarse'),
              ),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () {
              setState(() { _loading = true; _error = null; _news = null; });
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: () {
                  setState(() { _loading = true; _error = null; });
                  _load();
                })
              : _news == null || _news!.isEmpty
                  ? const _EmptyView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: crossAxisCount == 1
                          ? _ListView(
                              news: _news!,
                              favoriteIds: _favoriteIds,
                              isAuthenticated: isAuthenticated,
                              onToggleFavorite: _toggleFavorite,
                              onPromptLogin: _promptLogin,
                              onNewsClosed: _load,
                            )
                          : _GridView(
                              news: _news!,
                              favoriteIds: _favoriteIds,
                              isAuthenticated: isAuthenticated,
                              onToggleFavorite: _toggleFavorite,
                              onPromptLogin: _promptLogin,
                              onNewsClosed: _load,
                            ),
                    ),
    );
  }
}

class _ListView extends StatelessWidget {
  final List<News> news;
  final Set<int> favoriteIds;
  final bool isAuthenticated;
  final void Function(int) onToggleFavorite;
  final VoidCallback onPromptLogin;
  final Future<void> Function() onNewsClosed;

  const _ListView({
    required this.news,
    required this.favoriteIds,
    required this.isAuthenticated,
    required this.onToggleFavorite,
    required this.onPromptLogin,
    required this.onNewsClosed,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.separated(
            itemCount: news.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => NewsCard(
              news: news[i],
              isFavorite: favoriteIds.contains(news[i].id),
              favoriteLocked: !isAuthenticated,
              onFavoriteToggle: isAuthenticated ? () => onToggleFavorite(news[i].id) : onPromptLogin,
              onTap: () {
                context.push('/news/${news[i].id}').then((_) => onNewsClosed());
              },
            ),
          ),
        ),
        const SliverToBoxAdapter(child: AppFooter()),
      ],
    );
  }
}

class _GridView extends StatelessWidget {
  final List<News> news;
  final Set<int> favoriteIds;
  final bool isAuthenticated;
  final void Function(int) onToggleFavorite;
  final VoidCallback onPromptLogin;
  final Future<void> Function() onNewsClosed;

  const _GridView({
    required this.news,
    required this.favoriteIds,
    required this.isAuthenticated,
    required this.onToggleFavorite,
    required this.onPromptLogin,
    required this.onNewsClosed,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => NewsCard(
                news: news[i],
                isFavorite: favoriteIds.contains(news[i].id),
                favoriteLocked: !isAuthenticated,
                onFavoriteToggle: isAuthenticated ? () => onToggleFavorite(news[i].id) : onPromptLogin,
                onTap: () {
                  context.push('/news/${news[i].id}').then((_) => onNewsClosed());
                },
              ),
              childCount: news.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: AppFooter()),
      ],
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppTheme.textSecondary, size: 64),
            const SizedBox(height: 16),
            const Text(
              'No se pudo cargar las noticias',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(180, 48)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.newspaper, color: AppTheme.textSecondary, size: 64),
          SizedBox(height: 16),
          Text(
            'No hay noticias disponibles',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

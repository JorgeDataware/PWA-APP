import '../models/audit_log.dart';
import '../models/favorite.dart';
import '../models/news.dart';
import '../models/user.dart';
import '../services/api_client.dart';

/// In-memory data store used when [AppConstants.useMockData] is enabled.
///
/// Lets the app run as a pure front-end (no backend) with default
/// credentials and seeded demo content. State lives for the duration of
/// the session and resets on a full reload.
class MockData {
  MockData._();

  /// Simulated network latency so loading states are still visible.
  static Future<void> _delay() =>
      Future.delayed(const Duration(milliseconds: 350));

  // ---- Accounts -----------------------------------------------------------

  static final List<_Account> _accounts = [
    _Account(
      user: User(
        id: 1,
        fullName: 'Administrador',
        username: 'admin',
        email: 'admin@pwa-news.com',
        role: 'Admin',
        createdAt: DateTime(2025, 1, 10),
      ),
      password: 'Admin1234!',
    ),
    _Account(
      user: User(
        id: 2,
        fullName: 'Usuario Demo',
        username: 'usuario',
        email: 'user@pwa-news.com',
        role: 'User',
        createdAt: DateTime(2025, 3, 22),
      ),
      password: 'User1234!',
    ),
  ];

  /// Default credentials shown/pre-filled on the login screen.
  static const String defaultEmail = 'admin@pwa-news.com';
  static const String defaultPassword = 'Admin1234!';

  static int _userIdSeq = 3;

  /// Email of the account currently signed in (for profile endpoints).
  static String? _currentEmail;

  // ---- News ---------------------------------------------------------------

  static final List<News> _news = [
    News(
      id: 1,
      title: 'Flutter 3.9 llega con mejoras de rendimiento en web',
      authorId: 1,
      authorName: 'Administrador',
      content:
          'La nueva versión de Flutter trae optimizaciones significativas '
          'para el renderizado en navegadores, reduciendo el tamaño de los '
          'bundles y mejorando los tiempos de arranque. El equipo de Google '
          'destaca el soporte mejorado para wearables y pantallas pequeñas.',
      publishedAt: DateTime(2026, 6, 16, 9, 30),
      imageUrl: 'https://picsum.photos/seed/flutter/800/450',
    ),
    News(
      id: 2,
      title: 'La inteligencia artificial redefine el desarrollo de software',
      authorId: 1,
      authorName: 'Administrador',
      content:
          'Los asistentes de código basados en modelos de lenguaje se han '
          'convertido en herramientas cotidianas para millones de '
          'desarrolladores, acelerando tareas repetitivas y permitiendo '
          'enfocarse en la arquitectura y el diseño de producto.',
      publishedAt: DateTime(2026, 6, 15, 14, 0),
      imageUrl: 'https://picsum.photos/seed/ai/800/450',
    ),
    News(
      id: 3,
      title: 'Las PWA ganan terreno frente a las apps nativas',
      authorId: 2,
      authorName: 'Usuario Demo',
      content:
          'Las Progressive Web Apps ofrecen instalación sin tiendas, '
          'notificaciones push y funcionamiento offline. Cada vez más '
          'empresas las adoptan para reducir costos de mantenimiento en '
          'múltiples plataformas.',
      publishedAt: DateTime(2026, 6, 14, 11, 15),
      imageUrl: 'https://picsum.photos/seed/pwa/800/450',
    ),
    News(
      id: 4,
      title: 'Wearables: el nuevo frente de la computación personal',
      authorId: 1,
      authorName: 'Administrador',
      content:
          'Relojes inteligentes y dispositivos de pantalla reducida exigen '
          'interfaces repensadas. Diseñar para 320 píxeles o menos obliga a '
          'priorizar el contenido esencial y la legibilidad.',
      publishedAt: DateTime(2026, 6, 12, 8, 45),
      imageUrl: 'https://picsum.photos/seed/wearable/800/450',
    ),
    News(
      id: 5,
      title: 'Dart 3.9: tipos sellados y patrones más expresivos',
      authorId: 2,
      authorName: 'Usuario Demo',
      content:
          'La evolución del lenguaje Dart incorpora coincidencia de patrones '
          'y tipos sellados que facilitan modelar estados de forma segura, '
          'reduciendo errores en tiempo de ejecución.',
      publishedAt: DateTime(2026, 6, 10, 16, 20),
      imageUrl: 'https://picsum.photos/seed/dart/800/450',
    ),
    News(
      id: 6,
      title: 'Diseño oscuro: más que una moda estética',
      authorId: 1,
      authorName: 'Administrador',
      content:
          'El modo oscuro reduce la fatiga visual y, en pantallas OLED, '
          'ahorra batería. Su adopción masiva lo ha convertido en un '
          'estándar de accesibilidad en aplicaciones modernas.',
      publishedAt: DateTime(2026, 6, 8, 19, 0),
      imageUrl: 'https://picsum.photos/seed/darkmode/800/450',
    ),
  ];

  static int _newsIdSeq = 7;

  // ---- Favorites ----------------------------------------------------------

  static final List<Favorite> _favorites = [
    Favorite(
      id: 1,
      newsId: 1,
      newsTitle: 'Flutter 3.9 llega con mejoras de rendimiento en web',
      newsImageUrl: 'https://picsum.photos/seed/flutter/800/450',
      addedAt: DateTime(2026, 6, 16, 10, 0),
    ),
  ];

  static int _favoriteIdSeq = 2;

  // ---- Auth ---------------------------------------------------------------

  static Future<LoginResponse> login(String email, String password) async {
    await _delay();
    final account = _accounts.firstWhere(
      (a) =>
          a.user.email.toLowerCase() == email.toLowerCase() &&
          a.password == password,
      orElse: () => throw const ApiException(
        statusCode: 401,
        message: 'Credenciales incorrectas',
      ),
    );
    _currentEmail = account.user.email;
    return LoginResponse(
      token: 'mock-token-${account.user.id}',
      tokenType: 'Bearer',
      expiresIn: 3600,
      user: account.user,
    );
  }

  static Future<LoginResponse> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    await _delay();
    if (_accounts.any((a) => a.user.email.toLowerCase() == email.toLowerCase())) {
      throw const ApiException(
        statusCode: 400,
        message: 'El email ya está en uso',
      );
    }
    final user = User(
      id: _userIdSeq++,
      fullName: fullName,
      username: username,
      email: email,
      role: 'User',
      createdAt: DateTime.now(),
    );
    _accounts.add(_Account(user: user, password: password));
    _currentEmail = user.email;
    return LoginResponse(
      token: 'mock-token-${user.id}',
      tokenType: 'Bearer',
      expiresIn: 3600,
      user: user,
    );
  }

  // ---- News API -----------------------------------------------------------

  static Future<List<News>> news() async {
    await _delay();
    final copy = [..._news]
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return copy;
  }

  static Future<List<News>> searchNews(String query) async {
    await _delay();
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return [];
    final matches = _news
        .where((n) =>
            n.title.toLowerCase().contains(needle) ||
            (n.content?.toLowerCase().contains(needle) ?? false))
        .toList()
      ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    return matches;
  }

  static Future<News> newsById(int id) async {
    await _delay();
    return _news.firstWhere(
      (n) => n.id == id,
      orElse: () => throw const ApiException(
        statusCode: 404,
        message: 'Noticia no encontrada',
      ),
    );
  }

  static Future<News> createNews({
    required String title,
    required String content,
    String? imageUrl,
  }) async {
    await _delay();
    final author = _currentAccount?.user;
    final news = News(
      id: _newsIdSeq++,
      title: title,
      authorId: author?.id,
      authorName: author?.fullName ?? 'Administrador',
      content: content,
      publishedAt: DateTime.now(),
      imageUrl: imageUrl,
    );
    _news.insert(0, news);
    return news;
  }

  static Future<News> updateNews(
    int id, {
    String? title,
    String? content,
    String? imageUrl,
  }) async {
    await _delay();
    final idx = _news.indexWhere((n) => n.id == id);
    if (idx < 0) {
      throw const ApiException(
        statusCode: 404,
        message: 'Noticia no encontrada',
      );
    }
    final old = _news[idx];
    final updated = News(
      id: old.id,
      title: title ?? old.title,
      authorId: old.authorId,
      authorName: old.authorName,
      content: content ?? old.content,
      publishedAt: old.publishedAt,
      imageUrl: imageUrl ?? old.imageUrl,
    );
    _news[idx] = updated;
    return updated;
  }

  static Future<void> deleteNews(int id) async {
    await _delay();
    _news.removeWhere((n) => n.id == id);
    _favorites.removeWhere((f) => f.newsId == id);
  }

  // ---- Favorites API ------------------------------------------------------

  static Future<List<Favorite>> favorites() async {
    await _delay();
    return [..._favorites]
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  static Future<Favorite> addFavorite(int newsId) async {
    await _delay();
    final existing = _favorites.where((f) => f.newsId == newsId).toList();
    if (existing.isNotEmpty) return existing.first;
    final news = _news.firstWhere(
      (n) => n.id == newsId,
      orElse: () => throw const ApiException(
        statusCode: 404,
        message: 'Noticia no encontrada',
      ),
    );
    final fav = Favorite(
      id: _favoriteIdSeq++,
      newsId: news.id,
      newsTitle: news.title,
      newsImageUrl: news.imageUrl,
      addedAt: DateTime.now(),
    );
    _favorites.add(fav);
    return fav;
  }

  static Future<void> removeFavorite(int newsId) async {
    await _delay();
    _favorites.removeWhere((f) => f.newsId == newsId);
  }

  // ---- Users API ----------------------------------------------------------

  static Future<List<User>> users() async {
    await _delay();
    return _accounts.map((a) => a.user).toList();
  }

  static Future<User> userById(int id) async {
    await _delay();
    return _accounts
        .firstWhere(
          (a) => a.user.id == id,
          orElse: () => throw const ApiException(
            statusCode: 404,
            message: 'Usuario no encontrado',
          ),
        )
        .user;
  }

  static Future<User> createUser({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required int role,
  }) async {
    await _delay();
    if (_accounts.any((a) => a.user.email.toLowerCase() == email.toLowerCase())) {
      throw const ApiException(
        statusCode: 400,
        message: 'El email ya está en uso',
      );
    }
    final user = User(
      id: _userIdSeq++,
      fullName: fullName,
      username: username,
      email: email,
      role: role == 1 ? 'Admin' : 'User',
      createdAt: DateTime.now(),
    );
    _accounts.add(_Account(user: user, password: password));
    return user;
  }

  static Future<User> updateUser(
    int id, {
    String? fullName,
    String? username,
    String? email,
    String? password,
    int? role,
  }) async {
    await _delay();
    final account = _accountById(id);
    final updated = _copyUser(
      account.user,
      fullName: fullName,
      username: username,
      email: email,
      role: role == null ? null : (role == 1 ? 'Admin' : 'User'),
    );
    account.user = updated;
    if (password != null && password.isNotEmpty) account.password = password;
    return updated;
  }

  static Future<void> deleteUser(int id) async {
    await _delay();
    _accounts.removeWhere((a) => a.user.id == id);
  }

  // ---- Profile API --------------------------------------------------------

  static Future<User> profile() async {
    await _delay();
    return (_currentAccount ?? _accounts.first).user;
  }

  static Future<User> updateProfile({
    String? fullName,
    String? username,
    String? email,
    String? password,
  }) async {
    await _delay();
    final account = _currentAccount ?? _accounts.first;
    final updated = _copyUser(
      account.user,
      fullName: fullName,
      username: username,
      email: email,
    );
    account.user = updated;
    if (password != null && password.isNotEmpty) account.password = password;
    _currentEmail = updated.email;
    return updated;
  }

  // ---- Helpers ------------------------------------------------------------

  static _Account? get _currentAccount {
    if (_currentEmail == null) return null;
    final matches = _accounts.where(
      (a) => a.user.email.toLowerCase() == _currentEmail!.toLowerCase(),
    );
    return matches.isEmpty ? null : matches.first;
  }

  static _Account _accountById(int id) => _accounts.firstWhere(
        (a) => a.user.id == id,
        orElse: () => throw const ApiException(
          statusCode: 404,
          message: 'Usuario no encontrado',
        ),
      );

  static User _copyUser(
    User u, {
    String? fullName,
    String? username,
    String? email,
    String? role,
  }) =>
      User(
        id: u.id,
        fullName: fullName ?? u.fullName,
        username: username ?? u.username,
        email: email ?? u.email,
        role: role ?? u.role,
        createdAt: u.createdAt,
      );

  // ---- Audit trail --------------------------------------------------------

  /// Seeded audit entries, newest first, including two failed operations so
  /// the "sólo fallas" view has something to show without a backend.
  static List<AuditLog> _auditSeed() {
    final now = DateTime.now();
    return [
      AuditLog(
        id: 5,
        occurredAt: now.subtract(const Duration(minutes: 3)),
        traceId: 'MOCK-0000005',
        userId: 1,
        username: 'admin',
        role: 'Admin',
        method: 'POST',
        path: '/api/web/news',
        action: 'Publicación de noticia',
        statusCode: 201,
        success: true,
        durationMs: 142,
        ipAddress: '127.0.0.1',
      ),
      AuditLog(
        id: 4,
        occurredAt: now.subtract(const Duration(minutes: 12)),
        traceId: 'MOCK-0000004',
        method: 'POST',
        path: '/api/auth/login',
        action: 'Inicio de sesión',
        statusCode: 401,
        success: false,
        durationMs: 88,
        ipAddress: '127.0.0.1',
        error: 'Credenciales inválidas o sesión expirada',
      ),
      AuditLog(
        id: 3,
        occurredAt: now.subtract(const Duration(hours: 1)),
        traceId: 'MOCK-0000003',
        userId: 1,
        username: 'admin',
        role: 'Admin',
        method: 'PATCH',
        path: '/api/web/users/3/status',
        action: 'Cambio de estado de cuenta',
        statusCode: 200,
        success: true,
        durationMs: 96,
        ipAddress: '127.0.0.1',
      ),
      AuditLog(
        id: 2,
        occurredAt: now.subtract(const Duration(hours: 5)),
        traceId: 'MOCK-0000002',
        userId: 2,
        username: 'jperez',
        role: 'User',
        method: 'DELETE',
        path: '/api/web/news/7',
        action: 'Eliminación de noticia',
        statusCode: 403,
        success: false,
        durationMs: 61,
        ipAddress: '127.0.0.1',
        error: 'Permisos insuficientes',
      ),
      AuditLog(
        id: 1,
        occurredAt: now.subtract(const Duration(days: 1)),
        traceId: 'MOCK-0000001',
        userId: 1,
        username: 'admin',
        role: 'Admin',
        method: 'PUT',
        path: '/api/web/news/4',
        action: 'Edición de noticia',
        statusCode: 200,
        success: true,
        durationMs: 133,
        ipAddress: '127.0.0.1',
      ),
    ];
  }

  static Future<List<AuditLog>> auditLogs({
    int limit = 50,
    bool onlyFailures = false,
  }) async {
    await _delay();
    final entries = _auditSeed().where((a) => !onlyFailures || !a.success);
    return entries.take(limit).toList();
  }

  static Future<AuditLog> auditLogByTraceId(String traceId) async {
    await _delay();
    final match = _auditSeed().where((a) => a.traceId == traceId);
    if (match.isEmpty) {
      throw ApiException(
        statusCode: 404,
        message: 'No hay ninguna operación registrada con el código $traceId.',
      );
    }
    return match.first;
  }
}

class _Account {
  User user;
  String password;

  _Account({required this.user, required this.password});
}

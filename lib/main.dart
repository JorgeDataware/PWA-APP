import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/utils.dart';
import 'core/app_mode.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/web/news_list_screen.dart';
import 'screens/web/news_detail_screen.dart';
import 'screens/web/favorites_screen.dart';
import 'screens/web/profile_screen.dart';
import 'screens/web/admin/admin_news_screen.dart';
import 'screens/web/admin/admin_users_screen.dart';
import 'screens/wearable/wearable_news_list_screen.dart';
import 'screens/wearable/wearable_news_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  await AppMode.initialize();
  final authProvider = AuthProvider();
  await authProvider.initialize();
  runApp(TechNewsApp(authProvider: authProvider));
}

class TechNewsApp extends StatefulWidget {
  final AuthProvider authProvider;

  const TechNewsApp({super.key, required this.authProvider});

  @override
  State<TechNewsApp> createState() => _TechNewsAppState();
}

class _TechNewsAppState extends State<TechNewsApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter(widget.authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.authProvider,
      child: MaterialApp.router(
        title: 'TechNews',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: _router,
      ),
    );
  }

  GoRouter _buildRouter(AuthProvider auth) {
    return GoRouter(
      refreshListenable: auth,
      initialLocation: '/news',
      redirect: (context, state) {
        if (AppMode.isWearable) {
          return state.matchedLocation.startsWith('/news') ? null : '/news';
        }
        final authenticated = auth.isAuthenticated;
        final path = state.matchedLocation;
        final isAuthPath = path == '/login' || path == '/register';

        if (!authenticated && !isAuthPath) return '/login';
        if (authenticated && isAuthPath) return '/news';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) => AppShell(navigationShell: shell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/news',
                  builder: (context, state) => context.isWearable
                      ? const WearableNewsListScreen()
                      : const NewsListScreen(),
                  routes: [
                    GoRoute(
                      path: ':id',
                      builder: (context, state) {
                        final id = int.parse(state.pathParameters['id']!);
                        return context.isWearable
                            ? WearableNewsDetailScreen(newsId: id)
                            : NewsDetailScreen(newsId: id);
                      },
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/favorites',
                  builder: (context, state) => const FavoritesScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin/news',
                  builder: (context, state) => const AdminNewsScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/admin/users',
                  builder: (context, state) => const AdminUsersScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/utils.dart';
import '../providers/auth_provider.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    if (context.isWearable) {
      return _WearableShell(child: navigationShell);
    }
    if (context.isDesktop) {
      return _DesktopShell(navigationShell: navigationShell);
    }
    return _MobileShell(navigationShell: navigationShell);
  }
}

class _WearableShell extends StatelessWidget {
  final Widget child;
  const _WearableShell({required this.child});

  @override
  Widget build(BuildContext context) => child;
}

class _MobileShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _MobileShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isAdmin = user?.isAdmin ?? false;

    final tabs = _buildTabs(isAdmin);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.divider, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _safeIndex(navigationShell.currentIndex, tabs.length),
          onTap: (i) => navigationShell.goBranch(i),
          items: tabs.map((t) => BottomNavigationBarItem(icon: t.icon, label: t.label)).toList(),
        ),
      ),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _DesktopShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isAdmin = user?.isAdmin ?? false;
    final tabs = _buildTabs(isAdmin);

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 220,
            color: AppTheme.surface,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Icon(Icons.rss_feed_rounded, color: AppTheme.primary, size: 26),
                      const SizedBox(width: 10),
                      const Text(
                        'TechNews',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    user?.fullName ?? '',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(indent: 16, endIndent: 16),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: tabs.length,
                    itemBuilder: (context, i) {
                      final selected = navigationShell.currentIndex == i;
                      return _NavItem(
                        tab: tabs[i],
                        selected: selected,
                        onTap: () => navigationShell.goBranch(i),
                      );
                    },
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: AppTheme.error, size: 20),
                    title: const Text(
                      'Cerrar sesión',
                      style: TextStyle(color: AppTheme.error, fontSize: 14),
                    ),
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    onTap: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.tab, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          selected ? tab.activeIconData : tab.iconData,
          color: selected ? AppTheme.primary : AppTheme.textSecondary,
          size: 22,
        ),
        title: Text(
          tab.label,
          style: TextStyle(
            color: selected ? AppTheme.primary : AppTheme.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        selected: selected,
        selectedTileColor: AppTheme.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        dense: true,
        onTap: onTap,
      ),
    );
  }
}

class _Tab {
  final String label;
  final IconData iconData;
  final IconData activeIconData;

  Icon get icon => Icon(iconData);
  Icon get activeIcon => Icon(activeIconData);

  const _Tab({
    required this.label,
    required this.iconData,
    required this.activeIconData,
  });
}

List<_Tab> _buildTabs(bool isAdmin) {
  return [
    const _Tab(label: 'Noticias', iconData: Icons.newspaper_outlined, activeIconData: Icons.newspaper),
    const _Tab(label: 'Favoritos', iconData: Icons.bookmark_border, activeIconData: Icons.bookmark),
    const _Tab(label: 'Mi perfil', iconData: Icons.person_outline, activeIconData: Icons.person),
    if (isAdmin)
      const _Tab(label: 'Noticias (Admin)', iconData: Icons.edit_note_outlined, activeIconData: Icons.edit_note),
    if (isAdmin)
      const _Tab(label: 'Usuarios', iconData: Icons.people_outline, activeIconData: Icons.people),
  ];
}

int _safeIndex(int index, int length) {
  if (index >= length) return 0;
  return index;
}

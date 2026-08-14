import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';

/// Persistent footer shown at the bottom of the public-facing pages
/// (news list, article detail, login/register, legal pages). Not shown
/// in the wearable layout, where every pixel of vertical space matters.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  static const _socialLinks = <_SocialLink>[
    _SocialLink(icon: Icons.alternate_email, label: 'X / Twitter', url: 'https://twitter.com/technewsapp'),
    _SocialLink(icon: Icons.facebook, label: 'Facebook', url: 'https://facebook.com/technewsapp'),
    _SocialLink(icon: Icons.camera_alt_outlined, label: 'Instagram', url: 'https://instagram.com/technewsapp'),
    _SocialLink(icon: Icons.code, label: 'GitHub', url: 'https://github.com/technewsapp'),
  ];

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            runSpacing: 8,
            children: [
              _FooterLink(label: 'Acerca de', onTap: () => context.push('/about')),
              _FooterLink(label: 'Aviso de privacidad', onTap: () => context.push('/privacy')),
              _FooterLink(label: 'Términos y condiciones', onTap: () => context.push('/terms')),
              _FooterLink(label: 'Contacto', onTap: () => context.push('/contact')),
              _FooterLink(label: 'Ver en smartwatch', onTap: () => context.push('/wearable')),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            children: _socialLinks
                .map(
                  (s) => IconButton(
                    tooltip: s.label,
                    icon: Icon(s.icon, size: 20, color: AppTheme.textSecondary),
                    onPressed: () => _open(s.url),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Text(
            '© $year TechNews · Todos los derechos reservados',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SocialLink {
  final IconData icon;
  final String label;
  final String url;
  const _SocialLink({required this.icon, required this.label, required this.url});
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      ),
    );
  }
}

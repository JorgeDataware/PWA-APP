import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import 'legal_scaffold.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  Future<void> _openMail() async {
    final uri = Uri(scheme: 'mailto', path: 'contacto@technews.app');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return LegalScaffold(
      title: 'Contacto',
      children: [
        const Text(
          '¿Tienes dudas o comentarios?',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const BodyText(
          'Escríbenos y con gusto te responderemos. También puedes ejercer tus derechos ARCO '
          'sobre tus datos personales a través de este mismo medio.',
        ),
        const SectionTitle('Correo electrónico'),
        _ContactTile(
          icon: Icons.email_outlined,
          label: 'contacto@technews.app',
          onTap: _openMail,
        ),
        const SectionTitle('Horario de atención'),
        const BodyText('Lunes a viernes, 9:00 a 18:00 (hora del centro de México).'),
      ],
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

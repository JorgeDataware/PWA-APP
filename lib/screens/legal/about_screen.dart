import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'legal_scaffold.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScaffold(
      title: 'Acerca de',
      children: [
        Icon(Icons.rss_feed_rounded, color: AppTheme.primary, size: 48),
        SizedBox(height: 12),
        Text(
          'TechNews',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          'Blog de noticias tecnológicas para web y wearable.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        SectionTitle('Nuestra misión'),
        BodyText(
          'TechNews existe para acercar las noticias de tecnología más relevantes del día a '
          'cualquier dispositivo que uses: tu computadora, tu teléfono o tu reloj inteligente. '
          'Creemos que mantenerse informado no debería requerir abrir diez pestañas distintas.',
        ),
        SectionTitle('Qué encontrarás aquí'),
        BodyText(
          '• Artículos redactados y editados por nuestro equipo editorial.\n'
          '• Una versión ligera y de lectura rápida para dispositivos wearable.\n'
          '• La posibilidad de guardar tus artículos favoritos si creas una cuenta.',
        ),
        SectionTitle('El equipo'),
        BodyText(
          'TechNews es desarrollado y mantenido como un proyecto educativo dentro de la '
          'materia de Desarrollo para Dispositivos Inteligentes.',
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'legal_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScaffold(
      title: 'Aviso de privacidad',
      children: [
        Text(
          'Aviso de privacidad',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          'Última actualización: agosto 2026',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        SectionTitle('1. Responsable del tratamiento de datos'),
        BodyText(
          'TechNews (en adelante, "la aplicación") es responsable del tratamiento de los datos '
          'personales que nos proporcionas, de conformidad con la Ley Federal de Protección de '
          'Datos Personales en Posesión de los Particulares (LFPDPPP).',
        ),
        SectionTitle('2. Datos personales que recabamos'),
        BodyText(
          '• Datos de identificación: nombre completo y nombre de usuario.\n'
          '• Datos de contacto: correo electrónico.\n'
          '• Datos de la cuenta: contraseña (almacenada de forma cifrada) y rol de usuario.\n'
          '• Datos de uso: artículos marcados como favoritos y token de sesión.',
        ),
        SectionTitle('3. Finalidad del tratamiento'),
        BodyText(
          'Los datos anteriores se utilizan para: crear y autenticar tu cuenta, personalizar tu '
          'experiencia (por ejemplo, mostrar tus noticias favoritas), y permitir el uso de la '
          'aplicación desde distintos dispositivos (web y wearable). No utilizamos tus datos con '
          'fines publicitarios ni los compartimos con terceros.',
        ),
        SectionTitle('4. Dónde se almacenan tus datos'),
        BodyText(
          'El token de sesión y los datos básicos de tu cuenta se guardan localmente en tu '
          'dispositivo (almacenamiento local del navegador o de la app) para mantener tu sesión '
          'iniciada. El resto de tu información se resguarda en nuestra base de datos, protegida '
          'mediante conexión HTTPS.',
        ),
        SectionTitle('5. Plazo de conservación'),
        BodyText(
          'Los datos de sesión almacenados localmente (token y perfil en caché) se conservan '
          'mientras la sesión esté activa y se eliminan automáticamente 30 días después de su '
          'creación si no se ha vuelto a iniciar sesión, o de inmediato al cerrar sesión '
          'manualmente. Los datos de tu cuenta en el servidor se conservan mientras la cuenta '
          'permanezca activa.',
        ),
        SectionTitle('6. Derechos ARCO'),
        BodyText(
          'Tienes derecho a Acceder, Rectificar, Cancelar u Oponerte (derechos ARCO) al '
          'tratamiento de tus datos personales. Puedes ejercerlos actualizando tu información '
          'desde tu perfil, o escribiéndonos a través de la página de Contacto.',
        ),
        SectionTitle('7. Uso sin cuenta'),
        BodyText(
          'Puedes navegar y leer todas las noticias sin crear una cuenta ni iniciar sesión. En '
          'ese caso no recabamos ningún dato personal; únicamente no podrás guardar artículos '
          'en favoritos, función que requiere una cuenta.',
        ),
        SectionTitle('8. Cambios a este aviso'),
        BodyText(
          'Este aviso de privacidad puede actualizarse para reflejar cambios en la aplicación o '
          'en la legislación aplicable. La fecha de la última actualización se indica al inicio '
          'de este documento.',
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'legal_scaffold.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalScaffold(
      title: 'Términos y condiciones',
      children: [
        Text(
          'Términos y condiciones de uso',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          'Última actualización: agosto 2026',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        SectionTitle('1. Aceptación de los términos'),
        BodyText(
          'Al acceder o utilizar TechNews (en adelante, "la aplicación" o "el servicio"), ya sea '
          'desde el sitio web, la aplicación móvil o el dispositivo wearable, aceptas quedar '
          'sujeto a los presentes términos y condiciones. Si no estás de acuerdo con alguno de '
          'ellos, te pedimos no utilizar el servicio.',
        ),
        SectionTitle('2. Descripción del servicio'),
        BodyText(
          'TechNews es un portal de noticias de tecnología que permite consultar artículos desde '
          'distintos dispositivos. La lectura de noticias es de acceso libre y no requiere crear '
          'una cuenta. Algunas funciones adicionales —como guardar artículos en favoritos o '
          'administrar tu perfil— sí requieren registro e inicio de sesión.',
        ),
        SectionTitle('3. Registro y cuenta de usuario'),
        BodyText(
          'Para crear una cuenta debes proporcionar información veraz y mantenerla actualizada. '
          'Eres responsable de la confidencialidad de tu contraseña y de toda la actividad que '
          'ocurra bajo tu cuenta. Si detectas un uso no autorizado, debes notificarlo de '
          'inmediato a través de la página de Contacto.',
        ),
        SectionTitle('4. Uso aceptable'),
        BodyText(
          'Al utilizar TechNews te comprometes a NO:\n'
          '• Intentar acceder a cuentas, datos o áreas del sistema que no te correspondan.\n'
          '• Interferir con el funcionamiento del servicio, sus servidores o sus redes '
          '(por ejemplo, mediante peticiones automatizadas masivas o pruebas de intrusión no '
          'autorizadas).\n'
          '• Utilizar el contenido de la aplicación con fines comerciales sin autorización previa '
          'y por escrito.\n'
          '• Suplantar la identidad de otra persona o entidad.\n'
          '• Introducir código malicioso, scripts o datos diseñados para dañar el servicio o a '
          'otros usuarios.',
        ),
        SectionTitle('5. Propiedad intelectual'),
        BodyText(
          'Los artículos, textos, imágenes, marcas, logotipos y el código fuente de la aplicación '
          'están protegidos por la legislación aplicable en materia de derechos de autor y '
          'propiedad industrial. Puedes leer y compartir enlaces al contenido para uso personal '
          'y no comercial, pero no reproducirlo íntegramente ni redistribuirlo como propio sin '
          'autorización.',
        ),
        SectionTitle('6. Contenido publicado y moderación'),
        BodyText(
          'El contenido editorial es publicado por usuarios con rol de administrador. TechNews se '
          'reserva el derecho de editar, actualizar o retirar cualquier artículo en cualquier '
          'momento, por ejemplo para corregir errores o retirar información que haya dejado de '
          'ser exacta.',
        ),
        SectionTitle('7. Disponibilidad del servicio'),
        BodyText(
          'TechNews se ofrece "tal cual" y "según disponibilidad". No garantizamos que el servicio '
          'esté libre de interrupciones, errores o fallas, ni que esté disponible de forma '
          'ininterrumpida. Podemos realizar tareas de mantenimiento, actualizaciones o '
          'suspensiones temporales sin previo aviso.',
        ),
        SectionTitle('8. Limitación de responsabilidad'),
        BodyText(
          'El contenido publicado tiene fines informativos y no constituye asesoría profesional de '
          'ningún tipo. En la medida permitida por la ley, TechNews no será responsable por daños '
          'directos o indirectos derivados del uso o la imposibilidad de uso del servicio, ni por '
          'decisiones tomadas con base en la información publicada.',
        ),
        SectionTitle('9. Enlaces y servicios de terceros'),
        BodyText(
          'La aplicación puede incluir enlaces a sitios externos (por ejemplo, redes sociales) o '
          'mostrar imágenes alojadas por terceros. No controlamos dichos sitios ni sus políticas, '
          'por lo que no somos responsables de su contenido, disponibilidad ni de la forma en que '
          'traten tus datos.',
        ),
        SectionTitle('10. Suspensión o cancelación de la cuenta'),
        BodyText(
          'Podemos suspender o cancelar cuentas que incumplan estos términos, especialmente en '
          'casos de uso indebido del servicio o intentos de vulnerar su seguridad. Tú puedes '
          'solicitar la cancelación de tu cuenta en cualquier momento a través de la página de '
          'Contacto.',
        ),
        SectionTitle('11. Tratamiento de datos personales'),
        BodyText(
          'El tratamiento de tus datos personales se rige por nuestro Aviso de privacidad, '
          'disponible desde el pie de página de la aplicación. Te recomendamos revisarlo, ya que '
          'forma parte integral de estos términos.',
        ),
        SectionTitle('12. Modificaciones a los términos'),
        BodyText(
          'Podemos actualizar estos términos para reflejar cambios en la aplicación o en la '
          'legislación aplicable. La fecha de la última actualización se indica al inicio de este '
          'documento; el uso continuado del servicio después de una modificación implica su '
          'aceptación.',
        ),
        SectionTitle('13. Legislación aplicable'),
        BodyText(
          'Estos términos se rigen por las leyes de los Estados Unidos Mexicanos. Cualquier '
          'controversia relacionada con su interpretación o cumplimiento se someterá a los '
          'tribunales competentes de dicha jurisdicción.',
        ),
        SectionTitle('14. Contacto'),
        BodyText(
          'Si tienes dudas sobre estos términos y condiciones, puedes escribirnos a través de la '
          'página de Contacto de la aplicación.',
        ),
      ],
    );
  }
}

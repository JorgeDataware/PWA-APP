# Changelog

Todas las versiones relevantes de **TechNews PWA**.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/) y el
versionado sigue [Semantic Versioning](https://semver.org/lang/es/): `MAYOR.MENOR.PARCHE`.

Las versiones anteriores a la 1.4.0 se reconstruyeron a partir del historial de Git
(cada entrada cita los commits que la componen) porque el proyecto no llevaba
bitácora de versiones hasta ese momento. Las etiquetas de Git a partir de `v1.4.0`
se crean en el momento del release.

---

## [1.4.0] — 2026-08-13

Enlace explícito entre el sitio web y el smartwatch, y panel de control para
administradores.

### Agregado
- Página pública `/wearable`: la interfaz real del reloj renderizada dentro de un
  marco de smartwatch, accesible desde el botón ⌚ del encabezado y desde el pie de
  página. Permite mostrar la experiencia wearable desde un navegador de escritorio,
  sin dispositivo físico. (`lib/screens/web/wearable_preview_screen.dart`)
- Panel de control de administración en `/admin/dashboard`: indicadores de contenido
  y de usuarios, gráfica de publicaciones por mes, ranking de autores y últimas
  publicaciones. (`lib/screens/web/admin/admin_dashboard_screen.dart`)
- `DashboardMetrics`: cálculo de métricas aislado de la interfaz, con pruebas
  unitarias propias. (`lib/core/dashboard_metrics.dart`)
- Pestaña "Panel" en la navegación, visible solo para administradores.

### Cambiado
- Las pantallas wearable navegan mediante `openWearableNewsDetail` /
  `closeWearableNewsDetail`, que usan GoRouter en el dispositivo real y un
  `Navigator` anidado dentro de la vista previa web.

### Pruebas
- 52 pruebas en total; 22 nuevas (métricas del panel, vista previa wearable).

Commits: `16564cf`.

---

## [1.3.0] — 2026-08-03

Automatización de calidad y widget especializado.

### Agregado
- Pipeline de CI/CD en GitHub Actions: `flutter analyze`, `flutter test`, build web
  de release y despliegue a Vercel. El lint bloquea el despliegue ante cualquier
  hallazgo. (`.github/workflows/ci.yml`)
- Suite de pruebas inicial: modelos, utilidades, búsqueda, tarjeta de noticia,
  pantalla de login.
- `RoundedScrollIndicator`: indicador de desplazamiento en arco, diseñado para
  pantallas circulares. (`lib/widgets/rounded_scroll_indicator.dart`)
- Buscador de noticias con debounce en la lista web, respaldado por
  `GET /api/web/news/search`.

### Corregido
- CanvasKit se empaqueta localmente (`--no-web-resources-cdn`) en lugar de cargarse
  desde un CDN externo, lo que simplifica la CSP y elimina la dependencia de red.

Commits: `f45a86e`, `a5d7e8a`, `e14f693`, `8f09fde`, `52d44cf`, `2f7dc19`.

---

## [1.2.0] — 2026-07-23

Soporte para Wear OS.

### Agregado
- Pantallas dedicadas para reloj: lista y detalle de noticias.
  (`lib/screens/wearable/`)
- Detección nativa del dispositivo por `MethodChannel` (`com.technews/device`),
  basada en `PackageManager.hasSystemFeature(FEATURE_WATCH)`.
- Configuración de aplicación Wear OS autónoma en el manifiesto de Android
  (`android.hardware.type.watch`, `com.google.android.wearable.standalone`).
- Recarga manual desde la pantalla del reloj.

Commits: `939dd52`, `4c6124c`, `4443967`.

---

## [1.1.0] — 2026-06-12

Documentación técnica.

### Agregado
- Documento del enlace entre el sitio web y los dispositivos inteligentes.
- Documento del widget especializado para dispositivos inteligentes.
- Plan de pruebas y documentación de seguridad: checklist de PWA, OWASP Mobile
  Top 10 y plan de retención de datos. (`docs/`)

Commits: `2874b02`.

---

## [1.0.0] — 2026-05-26

Primera versión funcional.

### Agregado
- Aplicación Flutter con enrutamiento declarativo (`go_router`) y layout
  responsivo en tres formatos (escritorio, móvil y wearable).
- Autenticación con JWT, sesión persistente y roles (Admin / User / Guest).
- Noticias: listado, detalle, favoritos y perfil de usuario.
- Administración de noticias y de cuentas de usuario.
- Páginas informativas y legales: acerca de, aviso de privacidad y contacto.
- API en .NET con arquitectura por capas (Domain / Application / Infrastructure /
  Api), EF Core + Dapper sobre PostgreSQL y validación con FluentValidation.

Commits: `5aafd9c`, `f6726dd`, `b7577ad`.

---

[1.4.0]: https://github.com/JorgeDataware/PWA-APP/releases/tag/v1.4.0

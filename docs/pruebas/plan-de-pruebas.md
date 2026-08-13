# Plan y reporte de pruebas — TechNews (SA.4)

## Cómo correr las pruebas

```bash
cd PWA-APP
flutter test
```

Última ejecución: **52/52 pruebas pasan** (`flutter test`, ver [reporte](#reporte-de-resultados) abajo).
Duración total: ~4 segundos. Versión probada: **1.4.0** (ver
[versionado-y-release.md](../versionado-y-release.md)).

## Alcance

Las pruebas se dividen en tres capas:

- **Unitarias** (`test/unit/`): modelos de datos (`News`, `User`, `Favorite`) y utilidades puras (breakpoints
  responsivos, formateo de fechas). No dependen de red, UI ni plataforma.
- **De widgets** (`test/widget/`, `test/widget_test.dart`): construyen componentes reales de Flutter
  (`NewsCard`, `LoginScreen`, `AppFooter`) en un árbol de prueba y verifican render + interacción.
- **Manuales** (tabla al final): flujos que requieren un backend real, un navegador real o múltiples
  dispositivos, y que por eso no están automatizados todavía.

Deliberadamente **no** se automatizó un smoke test que arranque la app completa contra la API real — ver la
nota en `test/widget_test.dart` y el hallazgo P-01 más abajo.

## Casos de prueba (mínimo 8 requerido)

| # | Acción | Resultado esperado | Resultado real | Automatizada en |
|---|---|---|---|---|
| 1 | Parsear un JSON de noticia con todos los campos (forma de `/api/web/news`) | `News.fromJson` devuelve un objeto con `id`, `title`, `content`, `imageUrl` y `publishedAt` correctos | ✅ Pasa | `test/unit/models_test.dart` |
| 2 | Parsear un JSON de noticia con `imageUrl`/`content`/`authorId` nulos (forma de `/api/wearable/news`) | No lanza excepción; los campos opcionales quedan en `null` | ✅ Pasa | `test/unit/models_test.dart` |
| 3 | Pedir `contentPreview` de un artículo con contenido > 180 caracteres | Devuelve los primeros 180 caracteres + `"..."` | ✅ Pasa | `test/unit/models_test.dart` |
| 4 | Evaluar `context.isWearable/.isMobile/.isDesktop` a distintos anchos de pantalla (300px, 320px exacto, 500px, 1024px) | 300px y 320px → wearable; 500px → mobile; 1024px → desktop | ✅ Pasa | `test/unit/utils_test.dart` |
| 5 | Formatear una fecha con `formatDate`/`formatDateShort`/`formatDateRelative` | `"11 jun 2026"`, `"11/06/26"` y `"Hace 5 min"` respectivamente, según el caso | ✅ Pasa | `test/unit/utils_test.dart` |
| 6 | Renderizar `NewsCard` con `isFavorite: true` | Muestra el ícono `Icons.bookmark` (relleno), no `bookmark_border` | ✅ Pasa | `test/widget/news_card_test.dart` |
| 7 | Renderizar `NewsCard` con `favoriteLocked: true` (usuario invitado) y tocar el ícono de favorito | Muestra `Icons.bookmark_outline` y, al tocarlo, invoca el callback de "solicitar login" en vez de guardar el favorito | ✅ Pasa | `test/widget/news_card_test.dart` |
| 8 | Enviar el formulario de login con los campos vacíos | Se muestran dos mensajes "Requerido" (email y contraseña) y **no** se intenta llamar a `AuthProvider.login` | ✅ Pasa | `test/widget/login_screen_test.dart` |
| 9 | Renderizar `LoginScreen` | Aparece el enlace "Explorar noticias sin cuenta" (navegación de invitado) | ✅ Pasa | `test/widget/login_screen_test.dart` |
| 10 | Renderizar `AppFooter` | Muestra los tres enlaces legales (Acerca de / Aviso de privacidad / Contacto), los íconos sociales y la línea de copyright | ✅ Pasa | `test/widget_test.dart` |
| 11 | Cargar una `NewsCard` con una URL de imagen inválida | Se muestra el ícono de imagen rota (`errorBuilder`) en vez de romper el árbol de widgets | ✅ Pasa | `test/widget/news_card_test.dart` |
| 12 | Buscar por título y por contenido, sin distinguir mayúsculas, y con una consulta vacía | Devuelve coincidencias ordenadas por fecha descendente; lista vacía si la consulta está vacía o no hay coincidencias | ✅ Pasa | `test/unit/search_test.dart` |
| 13 | Calcular las ventanas de 7 y 30 días del panel con un `now` fijo | Sólo cuenta las noticias dentro de cada ventana | ✅ Pasa | `test/unit/dashboard_metrics_test.dart` |
| 14 | Agrupar publicaciones por mes cuando hay meses sin noticias y noticias fuera de la ventana | Devuelve 6 cubetas, la más antigua primero, con `0` en los meses vacíos y descartando lo anterior a la ventana | ✅ Pasa | `test/unit/dashboard_metrics_test.dart` |
| 15 | Ordenar el ranking de autores con un empate en número de artículos | Ordena por cantidad descendente y desempata alfabéticamente, de forma estable entre recargas | ✅ Pasa | `test/unit/dashboard_metrics_test.dart` |
| 16 | Pedir las últimas publicaciones del panel | Devuelve las más recientes primero, respeta el límite y **no** modifica la lista original | ✅ Pasa | `test/unit/dashboard_metrics_test.dart` |
| 17 | Separar usuarios activos, inactivos y por rol | `activeUsers + inactiveUsers = totalUsers`; el conteo por rol es independiente del estado activo | ✅ Pasa | `test/unit/dashboard_metrics_test.dart` |
| 18 | Renderizar `AdminDashboardScreen` mientras carga | Muestra el título "Panel de control", el indicador de carga y el botón de actualizar | ✅ Pasa | `test/widget/admin_dashboard_screen_test.dart` |
| 19 | Renderizar la vista previa de smartwatch (`/wearable`) | Se dibuja el marco del reloj con su encabezado y un `Navigator` anidado propio | ✅ Pasa | `test/widget/wearable_preview_screen_test.dart` |
| 20 | Verificar el tamaño de la pantalla simulada del reloj | Es ≤ 320 dp, es decir dentro del breakpoint wearable, para que se rendericen las pantallas de reloj | ✅ Pasa | `test/widget/wearable_preview_screen_test.dart` |
| 21 | Consultar `WearablePreviewScope` dentro y fuera del marco del reloj | `true` dentro del marco (navegación anidada) y `false` fuera (navegación con GoRouter) | ✅ Pasa | `test/widget/wearable_preview_screen_test.dart` |
| 22 | Renderizar el indicador de desplazamiento circular antes y después del layout del scroll | No dibuja nada sin clientes de scroll; dibuja el arco una vez que hay contenido | ✅ Pasa | `test/widget/rounded_scroll_indicator_test.dart` |

22 casos automatizados (supera el mínimo de 8 pedido por la rúbrica), más los manuales de la siguiente
sección.

## Reporte de resultados

```
$ flutter test
00:00 +8: models_test.dart
00:00 +8: utils_test.dart
00:01 +5: search_test.dart
00:01 +14: dashboard_metrics_test.dart
00:02 +3: login_screen_test.dart
00:02 +6: news_card_test.dart
00:03 +2: rounded_scroll_indicator_test.dart
00:03 +4: wearable_preview_screen_test.dart
00:03 +1: admin_dashboard_screen_test.dart
00:04 +1: widget_test.dart (AppFooter)
00:04 +52: All tests passed!
```

Total: **52 pruebas, 52 exitosas, 0 fallidas** (`flutter analyze`: `No issues found!`).

## Hallazgo encontrado y corregido durante esta ronda (P-01)

Al escribir un smoke test que montaba la app completa (`TechNewsApp`), la prueba se colgaba durante los 10
minutos de timeout del framework en vez de fallar rápido. Causa raíz: `ApiClient` (`lib/services/api_client.dart`)
no aplicaba ningún timeout a sus llamadas HTTP — si el backend no responde (cold start de Render, red caída,
sandbox sin salida de red), la promesa nunca resuelve y la UI queda con el spinner de carga girando
indefinidamente, sin mensaje de error ni forma de reintentar.

**Corrección aplicada:** se agregó `.timeout(Duration(seconds: 15))` a los cinco métodos de `ApiClient`
(`get`/`post`/`put`/`patch`/`delete`), que ahora lanzan `ApiException(statusCode: 408, message: '...')` si el
servidor no responde a tiempo — la UI existente ya sabe mostrar ese mensaje porque reutiliza el mismo camino
de manejo de errores.

## Pruebas manuales (no automatizadas)

| # | Acción | Resultado esperado | Por qué es manual |
|---|---|---|---|
| M1 | Navegar a `/news` sin haber iniciado sesión | Se ven las noticias; el ícono de favorito está presente pero deshabilitado/con prompt de login | Requiere backend real con datos y verificación visual de layout |
| M2 | Iniciar sesión, marcar una noticia como favorita, cerrarla y volver a abrir la app | La noticia sigue marcada como favorita | Requiere backend real y persistencia de sesión entre recargas |
| M3 | Desactivar la red (DevTools → Network → Offline) y recargar la PWA ya instalada | La app carga su estructura desde el service worker en vez de una pantalla en blanco | Requiere un navegador real con Service Worker activo, no reproducible en `flutter test` |
| M4 | Redimensionar la ventana del navegador entre 1920px, 700px y 300px de ancho | La navegación cambia entre sidebar / bottom nav / vista wearable sin recargar la página | Verificación visual de layout en tiempo real |
| M5 | Iniciar sesión como usuario `Admin` vs. usuario `User` | Solo `Admin` ve las pestañas "Noticias (Admin)" y "Usuarios" | Requiere backend con cuentas de ambos roles |
| M6 | Simular que el backend tarda más de 15 segundos en responder | Aparece el mensaje "El servidor tardó demasiado en responder. Intenta de nuevo." en vez de un spinner infinito | Verificado por inspección de código tras el fix de P-01; pendiente de automatizar con un cliente HTTP inyectable |
| M7 | Registrar una cuenta nueva y verificar que aparece en `/admin/users` como Admin | El nuevo usuario existe con rol `User` por defecto | Requiere backend real, es un flujo de integración de dos pantallas |

## Pruebas en emulador (simulador de la app)

### Matriz de dispositivos

| Entorno | Dispositivo / AVD | Resolución | Sistema | Qué se verifica |
|---|---|---|---|---|
| Reloj | `Wear_OS_XL_Round` (`sdk_gwear_x86_64`) | 480 × 480 | Wear OS, Android 17 | Pantallas de reloj, indicador de desplazamiento circular, app autónoma (sin teléfono emparejado) |
| Navegador escritorio | Chrome, ventana ≥ 1280 px | — | — | Navegación lateral, panel de control, vista previa `/wearable` |
| Navegador móvil | Chrome, ventana ≤ 768 px | — | — | Barra de navegación inferior |
| Navegador estrecho | Chrome, ventana ≤ 320 px | — | — | Cambio automático a layout wearable por breakpoint |

### Procedimiento en el emulador Wear OS

```bash
emulator -avd Wear_OS_XL_Round
```

```bash
cd PWA-APP && flutter build apk --release
```

```bash
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-release.apk
```

```bash
adb -s emulator-5554 shell am start -n com.example.pwa_app/.MainActivity
```

Captura de evidencia (una imagen por pantalla, guardadas en `docs/pruebas/evidencias/`):

```bash
adb -s emulator-5554 exec-out screencap -p > docs/pruebas/evidencias/wear-lista.png
```

### Casos a verificar en el emulador

| # | Acción | Resultado esperado |
|---|---|---|
| E1 | Abrir la app en el reloj | Entra directo a la lista de noticias, **sin** pantalla de login (app autónoma) |
| E2 | Desplazar la lista | Aparece el indicador de desplazamiento en arco, pegado al borde curvo |
| E3 | Tocar una noticia | Abre el detalle en formato de reloj; el botón de regreso vuelve a la lista |
| E4 | Activar el modo avión y tocar actualizar | Se muestra el estado de error con botón "Reintentar", no un spinner infinito |

### Estado de la evidencia

Las capturas están **pendientes**: en el equipo donde se preparó la versión 1.4.0,
Gradle falla antes de compilar el APK con `java.io.IOException: Unable to establish
loopback connection`, tanto con el demonio activo como con `--no-daemon`. Se
descartó que fuera un problema del proyecto o del JDK — la misma JVM
(`temurin-21.0.10`) abre y acepta conexiones a `127.0.0.1` sin problema en una
prueba aislada, y limpiar `~/.gradle/native` no lo corrige. Apunta a software de
seguridad del equipo interceptando el socket local de Gradle. Las pruebas
automatizadas y el análisis estático no dependen de Gradle y sí se ejecutaron
(52/52).

## Pendientes para elevar la cobertura (no bloquean SA)

- Hacer `ApiClient` inyectable (`http.Client` como parámetro) para poder simular respuestas del backend
  (éxito, 401, 500, timeout) en pruebas de widgets sin red real — habilitaría automatizar M1, M2, M6 y M7.
- Agregar pruebas de integración (`integration_test/`) para los flujos M2–M4, que si requieren un navegador
  real.

# Plan y reporte de pruebas — TechNews (SA.4)

## Cómo correr las pruebas

```bash
cd PWA-APP
flutter test
```

Última ejecución: **26/26 pruebas pasan** (`flutter test`, ver [reporte](#reporte-de-resultados) abajo).
Duración total: ~2 segundos.

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

11 casos automatizados (supera el mínimo de 8 pedido por la rúbrica), más los manuales de la siguiente
sección.

## Reporte de resultados

```
$ flutter test
00:00 +8: models_test.dart — 8/8
00:00 +8: utils_test.dart — 8/8
00:01 +9: login_screen_test.dart — 3/3
00:01 +3: news_card_test.dart — 6/6
00:01 +1: widget_test.dart (AppFooter) — 1/1
00:02 +26: All tests passed!
```

Total: **26 pruebas, 26 exitosas, 0 fallidas.**

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

## Pendientes para elevar la cobertura (no bloquean SA)

- Hacer `ApiClient` inyectable (`http.Client` como parámetro) para poder simular respuestas del backend
  (éxito, 401, 500, timeout) en pruebas de widgets sin red real — habilitaría automatizar M1, M2, M6 y M7.
- Agregar pruebas de integración (`integration_test/`) para los flujos M2–M4, que si requieren un navegador
  real.

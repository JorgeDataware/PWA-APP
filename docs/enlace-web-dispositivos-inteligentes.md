# Enlace entre sitio web y dispositivos inteligentes: TechNews PWA

## Introducción

Una PWA (Progressive Web App) no es solo un sitio web accesible desde el navegador: es una
aplicación que puede detectar el contexto del dispositivo que la renderiza y adaptar tanto su
árbol de widgets como sus llamadas de datos de forma independiente. Este documento describe,
a partir del código de **TechNews**, los elementos concretos que forman ese enlace y cómo la
estructura del repositorio facilita el despliegue hacia dispositivos inteligentes (wearables,
smartwatches, pantallas de baja resolución).

---

## 1. El "DOM" en Flutter Web: el árbol de widgets

En una aplicación web tradicional el navegador construye un **DOM** (Document Object Model):
una jerarquía de nodos HTML que representa la interfaz. En Flutter Web el equivalente es el
**árbol de widgets**. Flutter compila a JavaScript y dibuja todo en un `<canvas>` HTML, por
lo que el DOM real es mínimo (un solo elemento raíz); la estructura lógica de la interfaz
vive en el árbol de widgets de Dart.

```
MaterialApp.router          ← raíz de la aplicación
  └─ GoRouter               ← enrutador declarativo
       └─ StatefulShellRoute ← contenedor de navegación persistente
            ├─ AppShell      ← decide qué shell renderizar
            │    ├─ _WearableShell   ← sin barra de navegación
            │    ├─ _MobileShell     ← BottomNavigationBar
            │    └─ _DesktopShell    ← NavigationRail lateral
            └─ [pantallas según rama activa]
```

> **Analogía DOM:** cada uno de los widgets de hoja (`Text`, `Icon`, `Image.network`) es
> equivalente a un nodo `<span>`, `<i>` o `<img>` del DOM. Los widgets contenedor
> (`Column`, `Row`, `Padding`) son equivalentes a `<div>` y `<section>`.

---

## 2. Punto de entrada del enlace: el sistema de breakpoints

El vínculo entre la versión web estándar y la versión para dispositivo inteligente se
establece en un único archivo:

**`lib/core/utils.dart`**

```dart
// Extensiones sobre BuildContext — disponibles en cualquier widget del árbol
extension ContextExtensions on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;

  // Umbral wearable: ≤ 320 px (tamaño típico de smartwatch)
  bool get isWearable => screenWidth <= AppConstants.wearableBreakpoint;

  // Umbral móvil: ≤ 768 px
  bool get isMobile => screenWidth <= AppConstants.tabletBreakpoint;

  // Escritorio: > 768 px
  bool get isDesktop => screenWidth > AppConstants.tabletBreakpoint;
}
```

Estos tres getters son el **interruptor** que determina qué rama del árbol de widgets se
construye. `MediaQuery.of(context).size.width` lee el ancho del viewport exactamente como
CSS lee `window.innerWidth`; solo que aquí la lógica vive en Dart, no en una media query.

Los umbrales están centralizados en `lib/core/constants.dart`:

```dart
class AppConstants {
  static const String baseUrl = 'http://localhost:5273';
  static const double wearableBreakpoint = 320.0;  // px — smartwatch
  static const double tabletBreakpoint   = 768.0;  // px — tablet/escritorio
}
```

---

## 3. Elementos que conforman el enlace

### 3.1 Shell adaptativo (`lib/screens/shell_screen.dart`)

Él `AppShell` es el **primer nodo del árbol** que toma decisiones de dispositivo. Actúa
como un `switch` estructural:

```dart
class AppShell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (context.isWearable) return _WearableShell(child: navigationShell);
    if (context.isDesktop)  return _DesktopShell(navigationShell: navigationShell);
    return _MobileShell(navigationShell: navigationShell);
  }
}
```

| Shell | Navegación | Elemento equivalente en HTML |
|---|---|---|
| `_WearableShell` | Sin barra — solo contenido | `<main>` sin `<nav>` |
| `_MobileShell` | `BottomNavigationBar` | `<nav>` en `position: fixed; bottom: 0` |
| `_DesktopShell` | Sidebar de 220 px | `<aside>` + `<nav>` lateral |

El `_WearableShell` es deliberadamente mínimo: envuelve el contenido sin añadir ninguna
decoración de navegación, porque un smartwatch no tiene espacio para ello.

### 3.2 Enrutamiento dual por pantalla (`lib/main.dart`)

El router aplica el mismo breakpoint dentro de cada `GoRoute.builder`:

```dart
GoRoute(
  path: '/news',
  builder: (context, state) => context.isWearable
      ? const WearableNewsListScreen()   // pantalla compacta
      : const NewsListScreen(),           // pantalla completa
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
```

La misma URL `/news` entrega dos implementaciones completamente distintas según el ancho
del viewport. Esto es equivalente a la técnica de **responsive templates** en frameworks
web, pero resuelto a nivel de árbol de widgets, no de CSS.

### 3.3 Widgets de tarjeta diferenciados (`lib/widgets/news_card.dart`)

El mismo archivo define dos clases de tarjeta:

| Widget | Uso | Diferencias clave |
|---|---|---|
| `NewsCard` | Web / móvil | Imagen 16:9 completa, texto de 3 líneas, botón de favorito, `fontSize: 17` |
| `WearableNewsCard` | Wearable (≤ 320 px) | Thumbnail cuadrado 56×56 px, título de 2 líneas, `fontSize: 13`, sin favorito |

```dart
// NewsCard — versión web
Padding(
  padding: const EdgeInsets.all(16),         // márgenes generosos
  child: Text(news.title,
    style: const TextStyle(fontSize: 17, ...),
    maxLines: 3,
  ),
);

// WearableNewsCard — versión wearable
Padding(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), // compacto
  child: Text(news.title,
    style: const TextStyle(fontSize: 13, ...),
    maxLines: 2,
  ),
);
```

La reducción tipográfica no es cosmética: en un smartwatch de 320 px, `fontSize: 17` con
`maxLines: 3` puede ocupar más del 40 % de la pantalla visible.

### 3.4 Endpoints de API diferenciados (`lib/services/news_service.dart`)

El enlace no es solo visual; también es de **datos**. El backend expone dos grupos de
endpoints:

```dart
// Web — artículo completo con contenido
static Future<List<News>> getWebNews() async =>
    ApiClient.get('/api/web/news');

// Wearable — versión reducida (sólo cabecera + metadata)
static Future<List<News>> getWearableNews() async =>
    ApiClient.get('/api/wearable/news');
```

Esto implementa el patrón **BFF (Backend For Frontend)**: el servidor devuelve solo los
campos que cada superficie puede mostrar. El wearable nunca descarga el `content` completo
de los artículos, lo que reduce el consumo de datos y acelera la carga en redes lentas
(Bluetooth, WiFi de baja señal comunes en smartwatches).

La pantalla de detalle wearable lo confirma explícitamente:

```dart
// lib/screens/wearable/wearable_news_detail_screen.dart
const Text(
  'Visita la versión web para leer el artículo completo.',
  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11),
);
```

El wearable actúa como **punto de descubrimiento**: muestra el titular y redirige al usuario
a la experiencia completa.

### 3.5 Formateo de fechas adaptado (`lib/core/utils.dart`)

```dart
// Web — fecha legible larga: "11 jun 2026"
String formatDate(DateTime date) =>
    DateFormat('dd MMM yyyy', 'es').format(date.toLocal());

// Wearable — fecha corta: "11/06/26"
String formatDateShort(DateTime date) =>
    DateFormat('dd/MM/yy').format(date.toLocal());
```

`WearableNewsCard` usa `formatDateShort`; `NewsCard` usa `formatDateRelative`. Esta
distinción evita que cadenas largas rompan el layout en pantallas pequeñas.

### 3.6 AppBar reducida en wearable

```dart
// WearableNewsListScreen — toolbarHeight compacto
AppBar(
  toolbarHeight: 40,   // vs. 56 px por defecto en Material 3
  title: const Text('TechNews', style: TextStyle(fontSize: 15)),
  ...
);

// WearableNewsDetailScreen — aún más compacto
AppBar(
  toolbarHeight: 36,
  title: const Text('Noticia', style: TextStyle(fontSize: 13)),
  ...
);
```

Cada píxel vertical importa en un smartwatch. Reducir el `AppBar` de 56 a 36 px libera el
35 % de altura vertical para el contenido.

---

## 4. Flujo completo de un request wearable

```
[Smartwatch browser / viewport ≤ 320 px]
        │
        ▼
  Flutter Web JS bundle cargado
        │
        ▼
  main() → AuthProvider.initialize()
        │
        ▼
  GoRouter.redirect() → verifica autenticación
        │
        ▼
  Route '/news' → context.isWearable == true
        │
        ├─► AppShell → _WearableShell (sin nav)
        │
        └─► WearableNewsListScreen
              │
              ▼
        NewsService.getWearableNews()
              │  GET /api/wearable/news
              ▼
        [JSON reducido: id, title, authorName, publishedAt, imageUrl]
              │
              ▼
        WearableNewsCard × N
          - Thumbnail 56×56 px
          - Título 2 líneas, fontSize 13
          - Fecha corta dd/MM/yy
```

---

## 5. ¿Cómo aprovechar las funciones del repositorio para el despliegue en dispositivos inteligentes?

### 5.1 El breakpoint como interruptor de despliegue

La función `context.isWearable` es el punto de control más poderoso del repositorio. Para
agregar soporte a un nuevo dispositivo (p. ej. una pantalla de auto con 480 px de ancho)
basta con:

1. Agregar una constante en `AppConstants`:
   ```dart
   static const double autoBreakpoint = 480.0;
   ```
2. Extender `ContextExtensions`:
   ```dart
   bool get isAuto => screenWidth > wearableBreakpoint && screenWidth <= autoBreakpoint;
   ```
3. Agregar un shell y pantallas específicas siguiendo el mismo patrón.

Todo lo demás —router, servicios, tema— ya está diseñado para aceptar esa variante sin
modificaciones.

### 5.2 Reutilización del modelo de datos

El modelo `News` (`lib/models/news.dart`) es neutro respecto al dispositivo. No contiene
lógica de presentación; solo datos. Esto permite que `WearableNewsCard` y `NewsCard` lean
exactamente los mismos campos (`title`, `imageUrl`, `authorName`, `publishedAt`) y decidan
cuánto mostrar de forma independiente. Para un nuevo dispositivo no se necesita un modelo
nuevo, solo un widget de presentación nuevo.

### 5.3 `ApiClient` como capa de transporte reutilizable

`ApiClient` (`lib/services/api_client.dart`) abstrae completamente HTTP: adjunta el token
JWT, serializa JSON, maneja errores y los traduce a mensajes en español. Cualquier pantalla
nueva para cualquier dispositivo llama a `ApiClient.get(path)` sin repetir esa lógica. Para
escalar a un endpoint de wearable con autenticación diferente (p. ej. OAuth de reloj),
solo hay que modificar `_headers()` en un único lugar.

### 5.4 El tema oscuro como estándar de pantallas OLED

`AppTheme.dark` usa `background: Color(0xFF0A0E1A)` (casi negro puro). Las pantallas OLED
de smartwatches apagan físicamente los píxeles negros, reduciendo el consumo de batería.
El repositorio ya sirve un tema óptimo para wearables sin ningún cambio adicional.

### 5.5 `StatefulShellRoute` y preservación de estado

El `StatefulShellRoute.indexedStack` en `main.dart` mantiene el estado de cada rama de
navegación vivo en memoria aunque el usuario cambie de pestaña. En un smartwatch donde
recargar datos consume batería y tiempo de espera, este mecanismo garantiza que la lista de
noticias ya cargada no se descarta al navegar al detalle y volver.

### 5.6 Despliegue: `flutter build web`

La compilación produce un bundle estático en `build/web/` que puede servirse desde
cualquier CDN o servidor de archivos:

```bash
flutter build web --release

# El output en build/web/ contiene:
#   index.html          ← punto de entrada PWA
#   flutter.js          ← loader del engine
#   main.dart.js        ← código de la app compilado
#   assets/             ← fuentes e imágenes
#   manifest.json       ← metadatos de instalación PWA (generado automáticamente)
#   flutter_service_worker.js  ← service worker para caché offline
```

El `manifest.json` y el service worker son generados por Flutter automáticamente al hacer
`build web`. Son los archivos que permiten que la PWA aparezca en el menú "Agregar a
pantalla de inicio" de un smartwatch con navegador (p. ej. Samsung Galaxy Watch con
Tizen Browser, o wearables con Wear OS y Chrome).

Para personalizar el `manifest.json` (nombre, color de tema, íconos para reloj) se edita
`web/manifest.json` en la raíz del proyecto. Flutter lo copia al directorio de salida
durante la compilación.

---

## Resumen

| Elemento del repositorio | Función en el enlace web ↔ dispositivo inteligente |
|---|---|
| `AppConstants.wearableBreakpoint` | Define el umbral de detección del dispositivo |
| `context.isWearable` | Interruptor que bifurca el árbol de widgets |
| `_WearableShell` | Shell sin navegación para pantallas pequeñas |
| `WearableNewsListScreen` / `WearableNewsDetailScreen` | Experiencia completa diseñada para ≤ 320 px |
| `WearableNewsCard` | Widget de tarjeta compacto (thumb 56 px, tipo 13 px) |
| `NewsService.getWearableNews()` | Endpoint BFF que entrega sólo los datos necesarios |
| `formatDateShort()` | Fecha en formato mínimo para evitar overflow en pantalla pequeña |
| `AppTheme.dark` con colores casi negros | Optimización de batería en pantallas OLED |
| `StatefulShellRoute.indexedStack` | Preserva estado para reducir recarga de datos |
| `flutter build web` + `manifest.json` | Produce el artefacto instalable como PWA en el dispositivo |

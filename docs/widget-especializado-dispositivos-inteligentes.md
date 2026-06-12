# Widget especializado para enlazar TechNews con dispositivos inteligentes

## Introducción

Un **widget de enlace** (en el contexto de dispositivos inteligentes, también llamado
*companion widget*, *glance widget* o *tile*) es una unidad de interfaz autónoma y
persistente que se instala en el sistema operativo del dispositivo —no dentro de la app—
y muestra información actualizada del sitio web sin que el usuario tenga que abrir ninguna
aplicación.

Este documento propone el diseño de dos variantes del widget TechNews: una para
**wearable (smartwatch)** y otra para **Smart TV**, describe con precisión qué datos
transfiere cada una, por qué los transfiere y cómo se integra con la arquitectura del
repositorio actual.

---

## 1. Contexto: qué existe hoy en el repositorio

Antes de diseñar el widget es necesario entender qué infraestructura ya existe y qué
necesita extenderse.

### Datos disponibles en la API actual

| Modelo | Campos | Endpoint de origen |
|---|---|---|
| `News` | `id`, `title`, `authorName`, `content`, `publishedAt`, `imageUrl` | `GET /api/web/news` · `GET /api/wearable/news` |
| `Favorite` | `id`, `newsId`, `newsTitle`, `newsImageUrl`, `addedAt` | `GET /api/favorites` |
| `User` | `id`, `fullName`, `username`, `email`, `role` | `GET /api/profile` |
| `LoginResponse` | `token`, `tokenType`, `expiresIn`, `user` | `POST /api/auth/login` |

El endpoint `/api/wearable/news` ya implementa el patrón **BFF (Backend For Frontend)**:
devuelve noticias reducidas (sin `content` completo) pensadas para consumo en dispositivos
de bajo ancho de banda. Es la base natural sobre la que construir los widgets.

### Lógica de detección de dispositivo

```dart
// lib/core/constants.dart
static const double wearableBreakpoint = 320.0;

// lib/core/utils.dart
bool get isWearable => screenWidth <= AppConstants.wearableBreakpoint;
```

Esta lógica de breakpoint funciona dentro de la app Flutter. Los widgets del sistema
operativo son procesos separados que no corren dentro del motor Flutter, por lo que
necesitarán su propio mecanismo de comunicación con la API.

---

## 2. Variante A — Widget para Wearable (Smartwatch)

### 2.1 Descripción general

Los sistemas operativos de smartwatch modernos (Wear OS, Tizen, watchOS) permiten instalar
**tiles** o **complications**: pequeñas vistas que se muestran en la esfera del reloj o en
el panel de acceso rápido. Son actualizadas periódicamente en segundo plano y permiten
una interacción mínima (un toque que abre la app complementaria).

El widget TechNews para wearable sería una **tile de una sola pantalla** que muestra el
titular más reciente y permite abrirlo con un toque.

### 2.2 Diseño visual propuesto

```
┌─────────────────────────────┐  ← pantalla circular ~390×390 px (típico Galaxy Watch 6)
│                             │
│  ● TechNews         11:42   │  ← nombre + hora del sistema
│  ─────────────────────────  │
│                             │
│  ┌───┐  IA genera código    │  ← thumbnail 56×56 px + título (máx. 2 líneas, 14 sp)
│  │ ▣ │   sin supervisión    │
│  └───┘  humana              │
│                             │
│  J. Ramírez · hace 2h       │  ← autor + fecha relativa (10 sp)
│                             │
│  [  Leer más  ]  [  ★  ]    │  ← botón deep-link + toggle favorito
│                             │
└─────────────────────────────┘
```

### 2.3 Datos que transfiere y su propósito

#### Datos recibidos (API → Widget)

| Campo | Tipo | Propósito en el widget |
|---|---|---|
| `id` | `int` | Construir el deep-link `/news/{id}` al tocar "Leer más" |
| `title` | `String` | Titular principal — el dato más importante para el usuario |
| `authorName` | `String` | Credibilidad de la fuente; mostrado debajo del titular |
| `publishedAt` | `DateTime` | Convertido a fecha relativa ("hace 2h") con `formatDateRelative()` |
| `imageUrl` | `String?` | Thumbnail 56×56 px; si es `null` se muestra ícono `Icons.article_outlined` |
| `token` (JWT, desde `SharedPreferences`) | `String` | Header `Authorization: Bearer` para autenticar el request del widget |

El widget **no transfiere ni muestra** `content` (el cuerpo del artículo). La razón es
doble: el endpoint `/api/wearable/news` no lo devuelve, y una pantalla de 390 px no puede
presentar texto largo de forma útil.

#### Datos enviados (Widget → API)

| Operación | Payload | Endpoint | Propósito |
|---|---|---|---|
| Agregar favorito | `{ "newsId": 42 }` | `POST /api/favorites` | El usuario puede guardar la noticia sin abrir la app |
| Quitar favorito | — | `DELETE /api/favorites/42` | Desmarcar desde la muñeca |

La acción de favorito desde el widget es el único flujo de **escritura** que el widget
necesita. El `FavoritesService` actual ya implementa ambos métodos; solo se necesita
exponerlos a través de la capa de comunicación con el widget del SO.

#### Señal de sincronización (Widget ↔ App)

Cuando el usuario agrega un favorito desde el widget, la app web debe reflejar ese cambio
la próxima vez que cargue `FavoritesScreen`. El mecanismo ya existe: `FavoritesScreen`
llama a `FavoritesService.getFavorites()` en `initState`, por lo que simplemente recargar
la pantalla sincroniza el estado.

### 2.4 Frecuencia y volumen de transferencia

```
Ciclo de actualización recomendado: cada 30 minutos
Payload por ciclo (JSON comprimido):
  - 1 noticia wearable: ~320 bytes
  - Lista de 5 noticias recientes: ~1.6 KB
  
En 24 horas: 48 ciclos × 1.6 KB ≈ 77 KB/día
```

Esto es insignificante para cualquier plan de datos, incluso en conexiones Bluetooth LE
donde el smartwatch comparte datos con el teléfono. La razón de usar el endpoint wearable
(sin `content`) en lugar del endpoint web es precisamente mantener este volumen bajo.

### 2.5 Integración con el repositorio

```dart
// Nuevo servicio propuesto: lib/services/widget_service.dart

class WidgetService {
  /// Devuelve la noticia más reciente, optimizada para tile de reloj.
  static Future<News> getLatestForWidget() async {
    final list = await NewsService.getWearableNews();
    return list.first;
  }

  /// Registra favorito desde el widget del SO — mismo endpoint que la app.
  static Future<void> toggleFavoriteFromWidget(int newsId, bool isFav) async {
    if (isFav) {
      await FavoritesService.removeFavorite(newsId);
    } else {
      await FavoritesService.addFavorite(newsId);
    }
  }
}
```

El token JWT ya está disponible en `SharedPreferences` bajo la clave `auth_token`
(ver `ApiClient._tokenKey`). El proceso del widget del SO puede leerlo a través de la
API de almacenamiento compartido del SO (en Android/Wear OS: `SharedPreferences` del
proceso principal; en watchOS: `WatchConnectivity`).

---

## 3. Variante B — Widget para Smart TV

### 3.1 Descripción general

Las Smart TV modernas (Android TV / Google TV, Tizen, webOS) permiten instalar
**paneles de inicio** o **cards en el home screen** que presentan contenido sin abrir
la app. En Android TV se denominan **channels** y **programs**; en Tizen / webOS son
**widgets** del launcher.

El widget TechNews para Smart TV sería una **fila de contenido** en el home screen del
televisor (similar a como Netflix o YouTube muestran sus catálogos) con las últimas
noticias tecnológicas como tarjetas horizontales.

### 3.2 Diseño visual propuesto

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  TechNews  —  Últimas noticias tecnológicas                                  │
│                                                                              │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌────────────┐              │
│  │            │  │            │  │            │  │            │              │
│  │  [imagen]  │  │  [imagen]  │  │  [imagen]  │  │  [imagen]  │  ──────►     │
│  │            │  │            │  │            │  │            │              │
│  ├────────────┤  ├────────────┤  ├────────────┤  ├────────────┤              │
│  │ IA y ética │  │ Flutter 4  │  │ Quantum    │  │ La nube    │              │
│  │ en 2026    │  │ lanzado    │  │ computing  │  │ en 2026    │              │
│  │            │  │            │  │ avanza     │  │            │              │
│  │ J.Ramírez  │  │ A.López    │  │ M.Torres   │  │ P.Nava     │              │
│  │ hace 2h    │  │ hace 5h    │  │ ayer       │  │ hace 3d    │              │
│  └────────────┘  └────────────┘  └────────────┘  └────────────┘              │
└──────────────────────────────────────────────────────────────────────────────┘
  ↑ Cada tarjeta: 320×240 px (16:9).  Fila horizontal desplazable con D-pad.
```

### 3.3 Datos que transfiere y su propósito

#### Datos recibidos (API → Widget)

A diferencia del wearable, la Smart TV sí puede mostrar un preview del contenido:
la pantalla es grande y el usuario está sentado a distancia con tiempo de lectura.

| Campo | Tipo | Propósito en el widget TV |
|---|---|---|
| `id` | `int` | Deep-link al abrir la noticia en la app TV (`/news/{id}`) |
| `title` | `String` | Título de la tarjeta (máx. 2 líneas, ~24 sp) |
| `authorName` | `String` | Crédito del autor bajo el título |
| `publishedAt` | `DateTime` | Fecha relativa ("hace 2h", "ayer") |
| `imageUrl` | `String?` | Imagen de portada 16:9 — elemento principal de la tarjeta |
| `content` (primeros 200 chars) | `String?` | Preview en pantalla de detalle al enfocar con D-pad |
| `token` (JWT) | `String` | Autenticación del request |

Para el widget TV se usaría el endpoint **web** (`/api/web/news`) en lugar del wearable,
porque sí necesita el campo `content` para el preview. Sin embargo, se aplicaría
paginación o límite de resultados:

```
GET /api/web/news?limit=10
```

Esto trae solo las 10 noticias más recientes para la fila del home screen.

#### Datos enviados (Widget TV → API)

| Operación | Payload | Endpoint | Propósito |
|---|---|---|---|
| Registrar visualización | `{ "newsId": 42, "source": "tv_widget" }` | `POST /api/analytics/view` *(nuevo endpoint)* | Métricas de consumo por dispositivo |
| Agregar favorito | `{ "newsId": 42 }` | `POST /api/favorites` | Guardar desde el televisor, leer después en web o wearable |

El campo `"source": "tv_widget"` permitiría al backend —en una versión futura— saber qué
porcentaje del tráfico viene de cada superficie, sin modificar los modelos existentes.

#### Datos de configuración (Widget → SharedPreferences local del TV)

| Dato | Propósito |
|---|---|
| `auth_token` | Sesión persistente; el usuario no debería iniciar sesión cada vez que enciende el televisor |
| `last_fetched_at` | Timestamp de la última actualización, para mostrar un indicador "Actualizado hace X min" |
| `cached_news_ids` | Lista de IDs ya vistos, para marcarlos como "leídos" en la UI |

### 3.4 Frecuencia y volumen de transferencia

```
Ciclo de actualización recomendado: cada 15 minutos (TV encendida) / pausado (TV apagada)
Payload por ciclo (10 noticias web con content parcial):
  - ~8 KB por ciclo (JSON sin comprimir)
  - ~2.5 KB con gzip (estándar en cualquier servidor HTTP moderno)

En 4h de TV encendida: 16 ciclos × 2.5 KB ≈ 40 KB
```

Las imágenes son la carga real: una imagen de portada a 320×240 px puede pesar 15–40 KB.
Con 10 noticias eso es ~200–400 KB por carga inicial. Se recomienda usar el campo
`imageUrl` para cargar imágenes con lazy-loading (solo cuando la tarjeta entra al viewport
del carrusel).

### 3.5 Integración con el repositorio

```dart
// Extensión propuesta en lib/services/news_service.dart

static Future<List<News>> getTvWidgetNews({int limit = 10}) async {
  // Reutiliza ApiClient — misma capa de autenticación y manejo de errores
  final data = await ApiClient.get('/api/web/news?limit=$limit') as List;
  return data.map((e) => News.fromJson(e as Map<String, dynamic>)).toList();
}
```

El modelo `News` existente ya tiene todos los campos necesarios (incluyendo `content`
y `contentPreview` que devuelve los primeros 180 caracteres automáticamente):

```dart
// lib/models/news.dart — ya existe
String get contentPreview {
  if (content == null || content!.isEmpty) return '';
  return content!.length > 180 ? '${content!.substring(0, 180)}...' : content!;
}
```

`contentPreview` es exactamente lo que necesita la tarjeta TV al enfocarla con el D-pad.

---

## 4. Comparación de los dos widgets

| Aspecto | Widget Wearable | Widget Smart TV |
|---|---|---|
| **Superficie de instalación** | Tile / Complication en esfera del reloj | Fila de contenido en home screen del TV |
| **Tamaño de pantalla** | ~390×390 px (circular) | 1920×1080 px |
| **Interacción** | Toque único; gestos de deslizar | D-pad / control remoto |
| **Endpoint de datos** | `GET /api/wearable/news` (sin `content`) | `GET /api/web/news?limit=10` (con `content`) |
| **Campos transferidos** | `id`, `title`, `authorName`, `publishedAt`, `imageUrl` | Todos los anteriores + `content` |
| **Volumen estimado/día** | ~77 KB | ~40 KB por sesión de 4h |
| **Actualización** | Cada 30 min | Cada 15 min (TV activa) |
| **Escritura a API** | `POST/DELETE /api/favorites` | `POST /api/favorites` + `POST /api/analytics/view` |
| **Autenticación** | JWT desde `SharedPreferences` compartido | JWT desde `SharedPreferences` local del TV |
| **Caché local** | No necesaria (pantalla pequeña, dato único) | Sí (lista de 10 noticias + estado "leído") |

---

## 5. Flujo de datos completo

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         BACKEND (localhost:5273)                            │
│                                                                             │
│  POST /api/auth/login ──────► token JWT                                     │
│  GET  /api/wearable/news ───► [ {id,title,author,date,imageUrl} × N ]       │
│  GET  /api/web/news?limit=10 ► [ {id,title,author,date,imageUrl,content} ]  │
│  POST /api/favorites ────────► { id, newsId, newsTitle, addedAt }           │
│  DELETE /api/favorites/{id} ─► 204 No Content                               │
└────────────────┬───────────────────────────────────────────┬────────────────┘
                 │ HTTPS / JWT Bearer                        │
         ┌───────▼────────┐                         ┌────────▼────────┐
         │  WEARABLE      │                         │   SMART TV      │
         │  WIDGET        │                         │   WIDGET        │
         │                │                         │                 │
         │  Tile 390px    │                         │  Fila 1920px    │
         │  1 noticia     │                         │  10 noticias    │
         │  Thumbnail 56px│                         │  Imagen 16:9    │
         │  Título 2 línea│                         │  Preview 180ch  │
         │  ★ Favorito    │                         │  ★ Favorito    │
         └───────┬────────┘                         └────────┬────────┘
                 │  Deep-link /news/{id}                     │  Deep-link /news/{id}
         ┌───────▼──────────────────────────────────────────▼────────┐
         │                   APP FLUTTER (TechNews PWA)              │
         │                                                           │
         │   context.isWearable → WearableNewsDetailScreen           │
         │   context.isDesktop  → NewsDetailScreen                   │
         └───────────────────────────────────────────────────────────┘
```

---

## 6. Propósito integral del enlace

### Para el usuario del wearable
- **Consumo pasivo de información**: sin sacar el teléfono, el usuario ve el último titular
  tecnológico con un gesto de levantar la muñeca.
- **Acción inmediata**: puede marcar una noticia como favorita para leerla después en la
  web, cerrando el ciclo lectura-guardado-consumo completo entre dispositivos.
- **Ahorro de batería**: el endpoint wearable no envía `content`, reduciendo la carga de
  procesamiento JSON y la radioactiva del reloj.

### Para el usuario de Smart TV
- **Descubrimiento en pantalla grande**: el carrusel de noticias funciona como portada
  editorial; las imágenes 16:9 son el medio principal (como en un periódico visual).
- **Lectura con contexto**: el preview de 180 caracteres al enfocar una tarjeta da suficiente
  contexto para decidir si abrir el artículo completo.
- **Continuidad entre dispositivos**: lo que el usuario marca como favorito en el TV aparece
  en su perfil web la próxima vez que abre la PWA en el navegador, gracias al mismo endpoint
  `/api/favorites`.

### Para el sistema (métricas y contenido)
- El campo `source` en el endpoint de analytics permite al equipo editorial saber qué
  noticias atraen más clics desde cada superficie, informando decisiones de publicación.
- La arquitectura BFF (un endpoint por superficie) protege al backend de sobrecarga:
  el wearable nunca descarga artículos completos aunque el endpoint web los tenga.

---

## 7. Nuevo endpoint recomendado para el backend

Para completar el enlace sin modificar la lógica existente, se propone un único endpoint
nuevo:

```
GET /api/widget/summary
Authorization: Bearer {token}

Response:
{
  "latestNews": [
    {
      "id": 42,
      "title": "IA genera código sin supervisión humana",
      "authorName": "Jorge Ramírez",
      "publishedAt": "2026-06-11T09:30:00Z",
      "imageUrl": "https://cdn.technews.mx/img/ai-code.jpg",
      "contentPreview": "Investigadores del MIT presentaron..."
    }
  ],
  "unreadCount": 3,
  "favoriteCount": 7,
  "generatedAt": "2026-06-11T11:42:00Z"
}
```

`generatedAt` permite al widget mostrar "Actualizado hace X min" sin hacer un request
adicional. `unreadCount` puede mostrarse como badge numérico en la tilde del reloj o como
chip en la fila del TV.

Este endpoint reutiliza `NewsService`, `FavoritesService` y los modelos existentes en el
backend; solo agrega una capa de agregación.

---

## Resumen

| Elemento | Wearable | Smart TV |
|---|---|---|
| Clase Flutter base | `WearableNewsCard` | `NewsCard` |
| Servicio de datos | `NewsService.getWearableNews()` | `NewsService.getWebNews()` |
| Campos clave | `id · title · imageUrl · publishedAt` | `id · title · imageUrl · publishedAt · contentPreview` |
| Escritura | `FavoritesService.addFavorite()` / `removeFavorite()` | `FavoritesService.addFavorite()` |
| Autenticación | JWT de `ApiClient.getToken()` | JWT de `ApiClient.getToken()` |
| Nuevo código requerido | `WidgetService.getLatestForWidget()` | `NewsService.getTvWidgetNews()` |
| Nuevo endpoint de backend | `GET /api/widget/summary` | `GET /api/widget/summary` o `GET /api/web/news?limit=10` |

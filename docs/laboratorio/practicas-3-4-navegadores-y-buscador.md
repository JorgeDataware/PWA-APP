# Prácticas de laboratorio 3 y 4 — TechNews

**Materia:** Desarrollo para Dispositivos Inteligentes
**Proyecto:** TechNews PWA
**Alcance de este documento:** compatibilidad de librerías según navegador/dispositivo de destino (web y
wearable — Smart TV queda fuera de alcance de este proyecto) y buscador interno del sitio.

---

## 1. Librerías empleadas según navegadores de destino

### 1.1 ¿Dónde corre TechNews?

TechNews es una única aplicación Flutter Web que se ejecuta en dos superficies distintas desde el mismo
código y el mismo build:

| Superficie | Navegador real | Cómo se detecta |
|---|---|---|
| Web (desktop / móvil) | Chrome, Edge, Firefox, Safari (escritorio y móvil) | Ancho de viewport `> 320px` (`lib/core/utils.dart`) |
| Wearable (smartwatch, Wear OS) | **WebView de Chrome embebido en la app Android** — no es un navegador de escritorio | `PackageManager.hasSystemFeature(FEATURE_WATCH)` vía `MethodChannel` nativo (`MainActivity.kt`), reforzado por el mismo breakpoint de ancho |

Este segundo punto es la razón de fondo detrás de la elección de librerías: en wearable **no** se ejecuta en
un navegador de escritorio ni en Safari/Firefox — se ejecuta como una app Android compilada con Flutter que
internamente renderiza su UI web, empaquetada como APK e instalada en el reloj. Eso simplifica bastante la
matriz de compatibilidad porque el "navegador" del wearable es siempre Chromium/WebView reciente,
consistente entre dispositivos Wear OS.

### 1.2 Motor de renderizado: CanvasKit y su huella de compatibilidad

Flutter Web usa el renderer **CanvasKit** (Skia compilado a WebAssembly). Esto impone el primer requisito
real de compatibilidad de navegador, antes de llegar siquiera a las librerías de Dart/Flutter del
`pubspec.yaml`:

| Requisito del navegador | Por qué |
|---|---|
| Soporte de **WebAssembly** | CanvasKit se distribuye como `.wasm`; sin esto la app no arranca |
| **`'wasm-unsafe-eval'`** disponible (si hay CSP) | Chrome moderno exige este token de CSP específicamente para instanciar WebAssembly — lo agregamos en `web/index.html` tras diagnosticar una pantalla en blanco en producción (ver `docs/seguridad/checklist-seguridad-pwa.md`) |
| **Web Workers + `blob:` URLs** | CanvasKit/Skwasm generan workers desde blobs para no bloquear el hilo principal |
| Canvas 2D / WebGL | Fallback de renderizado; todos los navegadores modernos lo soportan |

**Conclusión práctica:** cualquier navegador de escritorio de los últimos ~3 años (Chrome, Edge, Firefox,
Safari) cumple estos requisitos. El WebView de Wear OS (basado en Chromium) también los cumple. Navegadores
muy antiguos o navegadores "ligeros" de ciertos Smart TV (fuera de alcance aquí) frecuentemente **no**
soportan WebAssembly completo ni Web Workers — por eso ese tipo de superficie necesitaría una estrategia de
renderizado distinta (HTML renderer en vez de CanvasKit), decisión que no aplicó a este proyecto.

Para reforzar esta compatibilidad, el pipeline de build usa `flutter build web --release
--no-web-resources-cdn`, que empaqueta CanvasKit **localmente** en vez de depender de que el navegador pueda
alcanzar el CDN externo de Google (`gstatic.com`) — relevante en redes corporativas o wearables con acceso a
internet restringido/proxied.

### 1.3 Librerías de `pubspec.yaml` y su relación con navegador/dispositivo

| Librería | Para qué se usa | Consideración de navegador / wearable / desempeño |
|---|---|---|
| `http` | Cliente HTTP hacia la API REST | Usa `fetch()` bajo el capó en Flutter Web — soportado universalmente. Se le agregó timeout de 15s (`lib/services/api_client.dart`) porque, sin límite, una respuesta lenta deja el spinner de carga girando indefinidamente; crítico en wearable, donde la batería y la paciencia del usuario son más escasas que en desktop |
| `go_router` | Enrutamiento declarativo | Usa `History API` del navegador (URLs limpias); requiere que el servidor reescriba todas las rutas a `index.html` — se configuró explícitamente en `web/vercel.json`, sin lo cual recargar `/news/5` daría 404 en cualquier navegador |
| `provider` | Manejo de estado (`AuthProvider`) | Puro Dart, sin dependencia de APIs de navegador — cero impacto de compatibilidad |
| `shared_preferences` | Persistencia de sesión (token JWT) | En Flutter Web usa **`window.localStorage`** — soportado en todos los navegadores destino, incluido el WebView de Wear OS. Nota importante: `localStorage` es por-origen, así que la sesión no se comparte automáticamente entre el teléfono y el reloj aunque sea "la misma cuenta" |
| `intl` | Formateo de fechas en español (`formatDate`, `formatDateShort`) | Requiere inicializar datos de locale (`initializeDateFormatting('es', null)`) antes del primer uso — si se omite, revienta en cualquier navegador, no es un problema específico de wearable |
| `url_launcher` | Abrir enlaces externos (redes sociales, `mailto:`) desde el footer | En Flutter Web delega a `window.open()`. **No se usa en las pantallas de wearable** — un smartwatch de 320px no tiene espacio útil para un footer con redes sociales, y abrir una pestaña nueva desde un WebView de reloj es una experiencia pobre. Por eso `AppFooter` solo se renderiza en las pantallas `web/`, nunca en `wearable/` |
| `cupertino_icons` | Íconos de estilo iOS (uso mínimo) | Solo afecta tamaño de bundle; se mitiga con *tree-shaking* de íconos (`flutter build web` reduce automáticamente las fuentes de íconos ~99%, ver logs de build) |

### 1.4 Notificaciones: qué se consideró y por qué no se implementaron push notifications

Se evaluó agregar notificaciones push (Web Push API + Service Worker) y se decidió **no** incluirlas en
esta iteración, por las siguientes razones de compatibilidad:

- **La Notification API / Push API no está disponible de forma confiable dentro de un WebView embebido**
  (el caso del wearable). A diferencia de una PWA abierta directamente en Chrome de escritorio o Android,
  un WebView cargado desde una `FlutterActivity` nativa no necesariamente expone permisos de notificación
  del sistema de la misma forma — normalmente eso requeriría una implementación **nativa** (Firebase Cloud
  Messaging o el `NotificationManager` de Android), no la Web Push API del navegador.
- Implementar notificaciones "a medias" (que funcionen en Chrome de escritorio pero no en el wearable)
  generaría una experiencia inconsistente entre dispositivos, algo que el resto de la arquitectura de este
  proyecto evita deliberadamente (mismo modelo de datos, mismo comportamiento, solo cambia la presentación).
- El Service Worker que Flutter genera automáticamente (`flutter_service_worker.js`) sí se usa para **modo
  offline** (cachear el shell de la app), que es el caso de uso de Service Worker que sí aplica de forma
  consistente en todas las superficies de destino.

**Conclusión:** el proyecto usa el Service Worker para lo que funciona igual en todos los navegadores
objetivo (caché offline), y deja las notificaciones push fuera de alcance por depender de una capa nativa
distinta por plataforma que rompería la premisa de "un solo código para todas las superficies".

### 1.5 Desempeño móvil

Decisiones tomadas específicamente por el costo de red/batería en dispositivos móviles y wearable:

| Técnica | Dónde | Efecto |
|---|---|---|
| Endpoint BFF reducido para wearable (`GET /api/wearable/news`, sin `content`) | Backend + `NewsService.getWearableNews()` | Evita descargar el cuerpo completo de los artículos en un dispositivo que no los va a mostrar completos |
| Debounce de 400ms en el buscador | `NewsListScreen._onSearchChanged` | Evita una petición HTTP por cada tecla presionada |
| Timeout de 15s en todas las peticiones (`ApiClient`) | Backend cualquiera | Evita procesos colgados consumiendo batería a la espera de una respuesta que nunca llega |
| *Tree-shaking* de fuentes de íconos | Build de producción | Reduce ~99% el peso de las fuentes de íconos (de ~1.6MB a ~12KB por fuente) |
| `Image.network` con `loadingBuilder`/`errorBuilder` | `NewsCard`, `WearableNewsCard` | Evita bloquear el layout mientras cargan imágenes remotas; degrada con gracia si la imagen falla |
| CanvasKit empaquetado localmente (`--no-web-resources-cdn`) | Build de producción | Evita una petición adicional a un CDN externo en la ruta crítica del primer render |

---

## 2. Buscador interno del sitio

### 2.1 Objetivo y alcance

Permitir encontrar contenido (noticias) dentro del sitio **sin salir de él** — es decir, sin redirigir a un
buscador externo (Google, Bing, etc.). La búsqueda es completamente interna: corre contra la base de datos
propia del proyecto, sin ningún servicio de búsqueda de terceros.

### 2.2 Arquitectura

```
┌─────────────────────────┐        GET /api/web/news/search?q=...        ┌──────────────────────────┐
│   NewsListScreen (UI)    │ ───────────────────────────────────────────► │   SearchNewsEndpoint     │
│  ícono de lupa → campo   │                                              │   (FastEndpoints, PWA-API)│
│  de texto con debounce   │ ◄─────────────────────────────────────────── │                          │
└─────────────────────────┘        200 OK — List<NewsDto>                 └──────────┬───────────────┘
                                                                                       │
                                                                                       ▼
                                                                          ┌────────────────────────┐
                                                                          │  NewsQueryService        │
                                                                          │  SearchNewsAsync(query)  │
                                                                          │  SQL: title/content ILIKE│
                                                                          └────────────────────────┘
```

- **Backend** — nuevo endpoint público `GET /api/web/news/search?q=<término>`
  ([SearchNewsEndpoint.cs](../../../PWA-API/Api/Endpoints/Web/News/SearchNewsEndpoint.cs)), que delega en
  `INewsService.SearchAsync()` → `INewsQueryService.SearchNewsAsync()`
  ([NewsQueryService.cs](../../../PWA-API/Infrastructure/Dapper/NewsQueryService.cs)), el cual ejecuta:
  ```sql
  SELECT n.id, n.title, n.author_id, u.full_name AS author_name,
         n.content, n.published_at, n.image_url
  FROM news n
  INNER JOIN users u ON n.author_id = u.id
  WHERE n.title ILIKE @Pattern OR n.content ILIKE @Pattern
  ORDER BY n.published_at DESC
  ```
  `ILIKE` de PostgreSQL hace la comparación insensible a mayúsculas/minúsculas. No se usó un motor de
  búsqueda dedicado (Elasticsearch, etc.) porque el volumen de datos del proyecto no lo justifica — hubiera
  agregado una pieza de infraestructura extra a desplegar y mantener sin beneficio real a esta escala.

- **Frontend** — [NewsService.searchNews()](../../lib/services/news_service.dart) llama al endpoint; la UI
  en [NewsListScreen](../../lib/screens/web/news_list_screen.dart) agrega un ícono de lupa en el `AppBar`
  que transforma el título en un campo de texto. El resultado reemplaza la lista normal mientras hay una
  búsqueda activa, reutilizando el mismo `NewsCard` y la misma lógica de favoritos.

- El buscador funciona **con o sin sesión iniciada** (mismo criterio de acceso público que el resto de la
  lectura de noticias).

### 2.3 Pruebas básicas realizadas

**Automatizadas** ([test/unit/search_test.dart](../../test/unit/search_test.dart), corren con `flutter
test`):

| # | Caso | Resultado esperado | Resultado |
|---|---|---|---|
| 1 | Buscar `"FLUTTER"` (mayúsculas) | Encuentra artículos con "Flutter" en el título, sin importar mayúsculas/minúsculas | ✅ Pasa |
| 2 | Buscar `"PWA"` | Encuentra coincidencias tanto en título como en contenido, no solo en título | ✅ Pasa |
| 3 | Buscar `"   "` (solo espacios) | Devuelve lista vacía, no lanza error ni consulta el backend | ✅ Pasa |
| 4 | Buscar un término inexistente (`"xyz-no-such-term-zzz"`) | Devuelve lista vacía | ✅ Pasa |
| 5 | Verificar orden de resultados | Los resultados vienen ordenados por fecha de publicación, más reciente primero | ✅ Pasa |

**Manuales** (contra el backend real desplegado):

| # | Búsqueda | Resultado esperado | Resultado |
|---|---|---|---|
| M1 | `flutter` | Aparece "Flutter 3.9 llega con mejoras de rendimiento en web" | ✅ Coincide |
| M2 | `chatgpt` | Aparecen los artículos relacionados con ChatGPT (coincidencia por título) | ✅ Coincide |
| M3 | Campo vacío | La app no dispara ninguna petición; se muestra el feed normal | ✅ Coincide |
| M4 | Término con errores de tipeo parcial (`"flutt"`) | Sigue encontrando "Flutter…" por ser coincidencia de subcadena, no de palabra completa | ✅ Coincide |
| M5 | Búsqueda sin sesión iniciada (usuario invitado) | Funciona igual que logueado; no pide iniciar sesión | ✅ Coincide |

### 2.4 Limitaciones conocidas

- Es una búsqueda por subcadena (`ILIKE '%término%'`), no full-text search: no maneja sinónimos, *stemming*
  (encontrar "corriendo" al buscar "correr"), ni relevancia por ranking. Para el tamaño de catálogo de
  noticias de este proyecto es suficiente; a mayor escala, la siguiente mejora natural sería usar
  `tsvector`/`tsquery` nativos de PostgreSQL antes de considerar un motor externo.

---

## 3. Resumen ejecutivo

| Requisito de la práctica | Estado | Evidencia |
|---|---|---|
| Librerías descritas según navegador de destino | ✅ | Sección 1 |
| Notificaciones consideradas | ✅ (evaluadas y descartadas con justificación) | Sección 1.4 |
| Desempeño móvil considerado | ✅ | Sección 1.5 |
| Buscador interno implementado | ✅ | Sección 2, endpoint `GET /api/web/news/search` |
| Pruebas básicas del buscador | ✅ | Sección 2.3 — 5 automatizadas + 5 manuales |

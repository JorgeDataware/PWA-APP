# OWASP Mobile Top 10 (2024) — aplicación a TechNews

Este documento recorre los diez riesgos del [OWASP Mobile Top 10 2024](https://owasp.org/www-project-mobile-top-10/)
y describe, para cada uno, cómo aplica (o no) a TechNews y qué mitigación existe en el código actual.

TechNews es una PWA Flutter Web (no una app nativa empaquetada), por lo que varios riesgos del top 10
—pensado originalmente para binarios instalables (APK/IPA)— se reinterpretan en clave de aplicación web:
no hay binario que analizar con ingeniería inversa, pero sí hay un bundle JS/Wasm servido públicamente,
almacenamiento del navegador, y una API REST consumida desde el cliente.

## M1: Uso indebido de credenciales

**Aplica.** Las credenciales (contraseña) nunca se guardan en el cliente; solo viaja el JWT recibido tras
`POST /api/auth/login`. El JWT se persiste en `SharedPreferences` (equivalente a `localStorage` en web) vía
`ApiClient.saveToken()` ([lib/services/api_client.dart](../../lib/services/api_client.dart)) y se limpia
explícitamente en `logout()`. No hay credenciales hardcodeadas en el bundle de producción (`useMockData =
false` en producción; las credenciales de demo solo existen cuando `useMockData = true`, un flag de
compilación pensado para desarrollo sin backend).

## M2: Cadena de suministro inadecuada

**Aplica parcialmente.** Las dependencias (`pubspec.yaml`) provienen únicamente de pub.dev con rangos de
versión fijados (`^`). No se usan paquetes de fuentes no oficiales ni forks sin mantenimiento. Pendiente:
automatizar `flutter pub outdated`/auditoría de dependencias en CI (ver DE.3 del plan de CI/CD).

## M3: Autenticación/autorización insegura

**Aplica.** La autenticación es JWT emitido por el backend (`PWA-API`), validado en cada request protegido
por el middleware de autenticación de ASP.NET (`AddJwtAuthentication`, `UseAuthentication`/`UseAuthorization`
en `Program.cs` del backend). El cliente nunca decide por sí mismo si un usuario es admin: cada endpoint
sensible (`/api/web/news` en escritura, `/api/favorites`, `/api/profile`) exige rol vía `Roles(...)` del
lado servidor — el `User.isAdmin` del cliente solo controla qué se **muestra** en la navegación, nunca qué
se **permite** en el backend. Los endpoints de lectura de noticias (`GET /api/web/news`, `GET
/api/web/news/{id}`, `GET /api/wearable/news`) son intencionalmente anónimos: TechNews es un portal de
noticias, y leer noticias no debe requerir cuenta (ver [main.dart](../../lib/main.dart) para la lógica de
rutas públicas equivalente en el cliente).

## M4: Validación de entrada/salida insuficiente

**Aplica.** Los formularios de login/registro validan en el cliente (`TextFormField.validator`) longitud,
formato de username (`^[a-zA-Z0-9_]+$`) y presencia de `@` en email — ver
[register_screen.dart](../../lib/screens/auth/register_screen.dart). Esta validación es solo UX; la
validación real y obligatoria ocurre en el backend (`Application/Validators` en `PWA-API`), que es quien
decide si los datos son aceptables. El contenido de las noticias se renderiza como `Text` plano (nunca
`HTML.parse`/`WebView` con contenido de terceros), por lo que no hay vector de inyección de marcado vía
artículo.

## M5: Comunicación insegura

**Aplica.** `AppConstants.baseUrl` apunta a `https://` en producción; no hay tráfico HTTP sin cifrar. El
`Content-Security-Policy` en `web/index.html` restringe `connect-src` a `https:` (ver
[checklist-seguridad-pwa.md](checklist-seguridad-pwa.md)), por lo que aunque el código intentara llamar a un
endpoint HTTP, el navegador lo bloquearía.

## M6: Privacidad inadecuada

**Aplica.** Ver [plan-retencion-datos.md](plan-retencion-datos.md) y el
[aviso de privacidad](../../lib/screens/legal/privacy_policy_screen.dart) accesible en `/privacy` dentro de
la app. TechNews recaba el mínimo de datos necesario (nombre, username, email) y permite navegar y leer
noticias sin cuenta ni recolección de datos personales.

## M7: Autenticación insuficiente en el binario/cliente

**No aplica directamente** (no hay lógica de negocio sensible ejecutándose exclusivamente en el cliente sin
respaldo del servidor). Toda decisión de autorización se revalida en el backend, como se describe en M3.

## M8: Seguridad insuficiente en la cadena binaria/protecciones de código

**No aplica** en el sentido clásico de ofuscación de APK: al ser Flutter Web, el "binario" es JS/Wasm público
por naturaleza (cualquier sitio web es inspeccionable desde DevTools). Esto es una propiedad inherente de la
plataforma web, no una vulnerabilidad específica de TechNews — ningún secreto (API keys, credenciales de
base de datos) vive en el bundle del cliente; el único artefacto que el cliente conserva es el JWT del
usuario que inició sesión, con expiración (`expiresIn`) controlada por el backend.

## M9: Mala gestión de sesiones

**Aplica.** El JWT tiene expiración server-side (`expiresIn`, ver `LoginResponse`). El cliente no renueva
tokens automáticamente ni implementa "recordarme" persistente más allá de lo que dura el token; al expirar,
cualquier request protegido devuelve 401 y el usuario debe volver a iniciar sesión. `logout()` limpia tanto
el token como los datos de perfil cacheados (`AuthProvider._clearPersisted()`).

## M10: Funcionalidad superflua/oculta

**Aplica.** No existen endpoints ni pantallas de depuración expuestos en build de producción. El modo
`useMockData` (que evita el backend real) es una constante de compilación (`AppConstants.useMockData =
false`), no un flag activable en runtime — no puede activarse accidentalmente en producción sin recompilar
y desplegar.

---

## Resumen de mitigaciones ya implementadas

| Riesgo | Mitigación |
|---|---|
| M1 | JWT en `SharedPreferences`, sin contraseñas en el cliente |
| M3 | Autorización revalidada en el backend por rol, endpoints de lectura pública separados de escritura |
| M4 | Validación de formularios + validación autoritativa en backend |
| M5 | HTTPS obligatorio + CSP `connect-src https:` |
| M6 | Aviso de privacidad, navegación sin cuenta, retención de datos a 30 días |
| M9 | Expiración de JWT controlada por servidor, limpieza de sesión en logout |

## Pendientes identificados

- Automatizar auditoría de dependencias en CI (M2).
- Agregar reintentos/renovación de token antes de expiración, en vez de solo detectar el 401 (M9) — mejora
  de UX, no un hueco de seguridad crítico.

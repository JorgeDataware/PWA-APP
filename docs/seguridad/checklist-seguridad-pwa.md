# Checklist de seguridad PWA — TechNews

| # | Elemento | Estado | Dónde |
|---|---|---|---|
| 1 | Content-Security-Policy configurada | ✅ Implementado | Meta tag en [web/index.html](../../web/index.html) |
| 2 | HTTPS obligatorio en todo el tráfico | ✅ Implementado | `AppConstants.baseUrl` usa `https://`; CSP `connect-src https:` lo hace cumplir a nivel navegador |
| 3 | SRI (Subresource Integrity) en scripts externos | ➖ No aplica | La app no carga scripts de terceros vía `<script src>`; el único script es `flutter_bootstrap.js`, servido desde el mismo origen que el `index.html` (mismo despliegue), por lo que no hay CDN externo que firmar |
| 4 | Validación de origin en comunicación entre contextos | ➖ No aplica directamente | TechNews no usa `BroadcastChannel`/`postMessage` entre pestañas o iframes (arquitectura de un solo Flutter Web app, sin PWA de TV ni canal de mensajería entre dispositivos). La superficie equivalente es la API REST, protegida por JWT + CORS (ver más abajo) |
| 5 | CORS configurado explícitamente en el backend | ⚠️ Configurado permisivo | `PWA-API/Program.cs` usa `AllowAnyOrigin()`. Es intencional (la API debe ser accesible desde cualquier frontend público: web, y a futuro otros clientes), pero como no se envían cookies (autenticación es Bearer token en header, no cookie de sesión), no hay riesgo de CSRF vía origen — ver nota abajo |
| 6 | Secretos (API keys, JWT signing key) fuera del repositorio | ✅ Implementado | `.env` y `.env.*` están en `.gitignore`; la clave de firma JWT vive en configuración del servidor (variables de entorno de Render), nunca en el bundle del cliente ni en el repo |
| 7 | Manifest.json válido con iconos e íconos maskable | ✅ Implementado | `web/manifest.json` |
| 8 | Service worker para modo offline | ✅ Implementado (generado por Flutter) | `flutter build web` genera `flutter_service_worker.js` automáticamente |
| 9 | Autenticación JWT con expiración | ✅ Implementado | Ver [owasp-mobile-top10.md](owasp-mobile-top10.md) M9 |
| 10 | Endpoints de lectura pública vs. escritura protegida separados | ✅ Implementado | `GET /api/web/news*` y `GET /api/wearable/news*` son anónimos; `POST/PUT/DELETE` de noticias exigen rol `Admin`; `/api/favorites` y `/api/profile` exigen sesión |

## Nota sobre CORS + `AllowAnyOrigin()`

`AllowAnyOrigin()` en un API que usa **JWT Bearer en el header `Authorization`** (no cookies) no habilita
CSRF: un sitio malicioso que haga un `fetch()` a la API desde el navegador de la víctima no tiene forma de
adjuntar el token del usuario (que vive en `SharedPreferences`/`localStorage` de `technews`, no accesible
desde otro origen). El riesgo real de `AllowAnyOrigin()` en este esquema es exponer datos **públicos** (las
noticias) a cualquier origen, lo cual es exactamente la intención al hacerlas anónimas.

## Verificación de la CSP aplicada

```html
<meta http-equiv="Content-Security-Policy"
      content="default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval';
               style-src 'self' 'unsafe-inline'; img-src 'self' https: data: blob:;
               font-src 'self' data:; connect-src 'self' https:; media-src 'self' https: data:;
               object-src 'none'; base-uri 'self'; frame-ancestors 'none';">
```

- `script-src 'unsafe-inline' 'unsafe-eval'` es requerido por el motor de Flutter Web (CanvasKit/HTML
  renderer inyectan y evalúan JS generado en tiempo de carga); restringirlo rompe la app. La mitigación real
  contra XSS en TechNews no depende de bloquear `eval`, sino de que **no se renderiza HTML no confiable en
  ningún punto** (todo el contenido de noticias se pinta con `Text`, nunca con un parser HTML).
- `img-src https:` permite imágenes de portada servidas por CDN externo (`picsum.photos` en datos de
  ejemplo, o el CDN real del backend en producción) sin abrir la puerta a orígenes `http://`.
- `frame-ancestors 'none'` evita que TechNews sea embebido en un `<iframe>` de otro sitio (protección
  clickjacking).
- `object-src 'none'` bloquea plugins tipo Flash/Java, sin uso en esta app.

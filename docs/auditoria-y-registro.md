# Auditoría y registro de fallas — TechNews

Cómo se registra lo que ocurre en la aplicación y cómo se reconstruye una falla
después de que sucedió, sin depender de que alguien haya estado mirando la
pantalla en ese momento.

---

## 1. La idea en una línea

Cada petición recibe un **código de rastreo** (`traceId`) que aparece
simultáneamente en tres lugares: la respuesta HTTP, el archivo de log y la tabla
de auditoría. Ese código es lo que convierte un "no me dejó guardar" en una
consulta puntual.

```
Usuario ve:      "Error interno del servidor (código: 0HNE1A2B3C4D5)"
                             │
        ┌────────────────────┼────────────────────┐
        ▼                    ▼                    ▼
 Cabecera HTTP        logs/technews-*.log     tabla audit_logs
 X-Trace-Id           trace=0HNE1A2B…         trace_id = 0HNE1A2B…
```

---

## 2. Las tres capas

### Capa 1 — Registro estructurado (Serilog)

Configurado en `PWA-API/Program.cs`. Dos destinos:

- **Consola**: visible en los logs del hosting.
- **Archivo**: `logs/technews-YYYYMMDD.log`, rotado por día y con retención de
  14 días. Es el respaldo consultable; está en `.gitignore` porque puede
  contener datos operativos.

`UseSerilogRequestLogging` registra una línea por petición con método, ruta,
código de estado y duración. El nivel **no** es fijo: 5xx se registra como
`Error`, 4xx como `Warning` y el resto como `Information`, de modo que las
fallas se filtran por nivel en vez de leer todo el archivo.

```bash
grep "\[ERR\]" PWA-API/logs/technews-20260813.log
```

### Capa 2 — Correlación (`RequestTraceMiddleware`)

Asigna el `traceId` al inicio de la petición, lo publica en la cabecera de
respuesta `X-Trace-Id` y lo empuja al contexto de Serilog para que **todas** las
líneas de esa petición lo lleven. Si el cliente ya envía un `X-Trace-Id`, se
respeta el suyo.

El cliente Flutter lo lee en `ApiClient` y lo expone en `ApiException.traceId`.
Se muestra al usuario únicamente cuando la falla es del servidor (5xx): un error
de validación se explica solo, un 500 no.

### Capa 3 — Auditoría (`AuditMiddleware` + tabla `audit_logs`)

Escribe **un registro por cada operación que modifica estado** — todo lo que no
sea `GET` —, haya terminado bien o mal. Se audita en el middleware y no dentro de
cada endpoint, de modo que un endpoint nuevo no puede quedar fuera del registro
por olvido.

Cada fila guarda: fecha, código de rastreo, usuario y rol (nulos si era anónimo,
como en un login rechazado), método, ruta, nombre legible de la acción, código de
estado, éxito/fracaso, duración en milisegundos, IP y el motivo del error.

Si escribir la auditoría falla, se registra el problema y **no** se interrumpe la
petición del usuario: el registro nunca debe romper aquello que registra.

---

## 3. Cómo se investiga una falla

1. **El usuario reporta el código** que vio en pantalla, o el administrador abre
   el panel en `/admin/dashboard` y activa *Sólo fallas*.
2. **Se localiza la operación** por ese código:

   ```
   GET /api/web/audit/{traceId}      (sólo Admin)
   ```

   Devuelve quién, qué, cuándo, desde qué IP, con qué resultado y cuánto tardó.
3. **Se lee el detalle técnico** en el archivo de log filtrando por el mismo
   código:

   ```bash
   grep "0HNE1A2B3C4D5" PWA-API/logs/technews-20260813.log
   ```

   Ahí está la excepción completa con su stack trace, si la hubo.

El panel del dashboard muestra las últimas 15 operaciones con el código
seleccionable para copiarlo, y el interruptor *Sólo fallas* reduce la lista a las
que no tuvieron éxito.

---

## 4. Endpoints

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| `GET` | `/api/web/audit?limit=50&onlyFailures=false` | Admin | Últimas operaciones, más recientes primero. `limit` se acota a 200 |
| `GET` | `/api/web/audit/{traceId}` | Admin | La operación detrás de un código de rastreo; 404 si no existe |

---

## 5. Qué **no** se guarda

Deliberadamente fuera del registro:

- **Cuerpos de las peticiones.** Un `POST /api/auth/login` contiene la
  contraseña; guardarlo convertiría la bitácora en un depósito de credenciales.
  Se registra que el intento ocurrió y cómo terminó, no con qué datos.
- **Tokens JWT y cabeceras de autorización.**
- **Contraseñas o sus hashes**, en cualquier forma.

El motivo del error se deriva del código de estado HTTP, no del cuerpo de la
respuesta, precisamente para no arrastrar datos sensibles a la tabla.

Ver también [`seguridad/plan-retencion-datos.md`](seguridad/plan-retencion-datos.md).

---

## 6. Limitaciones conocidas

- Las operaciones de **lectura** (`GET`) no se auditan. Se registran en el log de
  Serilog pero no generan fila en `audit_logs`: el volumen no compensa y ninguna
  lectura modifica datos.
- La auditoría escribe una fila por operación de forma **síncrona**. Con el
  volumen de esta aplicación es irrelevante; a mayor escala convendría encolar
  las escrituras.
- No hay purga automática de `audit_logs`. Con el tiempo habrá que definir una
  política de retención, en línea con el plan de retención de datos.

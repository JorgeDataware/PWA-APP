# PWA News API — Referencia de Endpoints

Documento de referencia completo para el cliente frontend. Cubre todos los endpoints, shapes exactos de request/response, reglas de validación y códigos de error.

---

## Configuración base

```
Base URL (desarrollo):  http://localhost:5273
Base URL (HTTPS dev):   https://localhost:7145
Content-Type:           application/json
```

---

## Autenticación

La API usa **JWT Bearer Token**.

1. Llama a `POST /api/auth/login` para obtener el token.
2. Incluye el header en cada request protegido:

```
Authorization: Bearer <token>
```

El token expira en **1440 minutos (24 horas)**.

### Roles

| Valor | Nombre | Descripción |
|-------|--------|-------------|
| `1`   | Admin  | Acceso total: CRUD usuarios, CRUD noticias, favoritos, perfil |
| `2`   | User   | Lectura de noticias, gestión de sus propios favoritos y perfil |

---

## Formato de errores

### Error de validación (FluentValidation) — `400`

```json
{
  "status": 400,
  "errors": {
    "Email": ["'Email' is not a valid email address."],
    "Password": ["The length of 'Password' must be at least 6 characters."]
  }
}
```

### Error de negocio — `400 | 401 | 403 | 404`

Cuando el body de la respuesta tiene contenido de error, tiene esta forma:

```json
null
```

> FastEndpoints envía `null` como body en respuestas de error de negocio (e.g. email duplicado, credenciales inválidas). El código HTTP es el indicador primario. Lee `response.status` para manejar estos casos.

---

## Tipos de datos

| Tipo en JSON | Descripción |
|---|---|
| `string` | UTF-8 |
| `number` | entero (int) |
| `string (ISO 8601)` | Fecha/hora UTC, e.g. `"2025-05-25T18:30:00Z"` |
| `string \| null` | Campo opcional, puede ser `null` |

---

## Auth

### `POST /api/auth/login`

Autentica un usuario y retorna un JWT.

**Auth requerida:** No

**Request body:**

```json
{
  "email": "admin@pwa-news.com",
  "password": "Admin1234!"
}
```

| Campo | Tipo | Reglas |
|-------|------|--------|
| `email` | string | requerido, formato email |
| `password` | string | requerido |

**Respuesta exitosa — `200`:**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "tokenType": "Bearer",
  "expiresIn": 86400,
  "user": {
    "id": 1,
    "fullName": "Admin User",
    "username": "admin",
    "email": "admin@pwa-news.com",
    "role": "Admin"
  }
}
```

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `token` | string | JWT a incluir en `Authorization: Bearer <token>` |
| `tokenType` | string | Siempre `"Bearer"` |
| `expiresIn` | number | Segundos de validez (86400 = 24h) |
| `user.id` | number | ID del usuario autenticado |
| `user.fullName` | string | Nombre completo |
| `user.username` | string | Username |
| `user.email` | string | Email |
| `user.role` | string | `"Admin"` o `"User"` |

**Errores:**

| Status | Condición |
|--------|-----------|
| `400` | Validación fallida (email inválido o campos vacíos) |
| `401` | Credenciales incorrectas |

---

### `POST /api/auth/register`

Registra un nuevo usuario con rol `User` por defecto.

**Auth requerida:** No

**Request body:**

```json
{
  "fullName": "Jane Doe",
  "username": "janedoe",
  "email": "jane@example.com",
  "password": "Secret123!"
}
```

| Campo | Tipo | Reglas |
|-------|------|--------|
| `fullName` | string | requerido, máx 100 caracteres |
| `username` | string | requerido, 3–50 caracteres, solo `[a-zA-Z0-9_]` |
| `email` | string | requerido, formato email |
| `password` | string | requerido, mín 6 caracteres |

**Respuesta exitosa — `201`:**

Mismo shape que `/api/auth/login` → `LoginResponse`.

**Errores:**

| Status | Condición |
|--------|-----------|
| `400` | Validación fallida o email/username ya en uso |

---

## Web — Usuarios

> Todos los endpoints de esta sección requieren rol **Admin**.

### `GET /api/web/users`

Retorna todos los usuarios registrados.

**Auth:** Bearer token — rol `Admin`

**Sin request body.**

**Respuesta exitosa — `200`:**

```json
[
  {
    "id": 1,
    "fullName": "Admin User",
    "username": "admin",
    "email": "admin@pwa-news.com",
    "role": "Admin",
    "createdAt": "2025-05-25T18:30:00Z"
  },
  {
    "id": 2,
    "fullName": "Normal User",
    "username": "usuario",
    "email": "user@pwa-news.com",
    "role": "User",
    "createdAt": "2025-05-25T18:30:00Z"
  }
]
```

| Campo | Tipo |
|-------|------|
| `id` | number |
| `fullName` | string |
| `username` | string |
| `email` | string |
| `role` | string — `"Admin"` \| `"User"` |
| `createdAt` | string (ISO 8601) |

---

### `GET /api/web/users/{id}`

Retorna un usuario por ID.

**Auth:** Bearer token — rol `Admin`

**Path params:** `id` (number)

**Respuesta exitosa — `200`:** Un objeto `UserDto` (mismo shape que el array de arriba).

**Errores:**

| Status | Condición |
|--------|-----------|
| `404` | Usuario no encontrado |

---

### `POST /api/web/users`

Crea un nuevo usuario (el Admin puede asignar cualquier rol).

**Auth:** Bearer token — rol `Admin`

**Request body:**

```json
{
  "fullName": "New Editor",
  "username": "neweditor",
  "email": "editor@example.com",
  "password": "Pass123!",
  "role": 1
}
```

| Campo | Tipo | Reglas |
|-------|------|--------|
| `fullName` | string | requerido, máx 100 |
| `username` | string | requerido, 3–50 caracteres, solo `[a-zA-Z0-9_]` |
| `email` | string | requerido, formato email |
| `password` | string | requerido, mín 6 caracteres |
| `role` | number | requerido, `1` = Admin, `2` = User |

**Respuesta exitosa — `201`:** Objeto `UserDto`.

**Errores:**

| Status | Condición |
|--------|-----------|
| `400` | Validación fallida o email/username ya en uso |

---

### `PUT /api/web/users/{id}`

Actualiza un usuario existente. Todos los campos del body son opcionales.

**Auth:** Bearer token — rol `Admin`

**Path params:** `id` (number)

**Request body:**

```json
{
  "fullName": "Updated Name",
  "username": "updateduser",
  "email": "updated@example.com",
  "password": "NewPass123!",
  "role": 2
}
```

| Campo | Tipo | Reglas |
|-------|------|--------|
| `fullName` | string \| null | máx 100, si se envía |
| `username` | string \| null | 3–50, `[a-zA-Z0-9_]`, si se envía |
| `email` | string \| null | formato email, si se envía |
| `password` | string \| null | mín 6 caracteres, si se envía |
| `role` | number \| null | `1` o `2`, si se envía |

**Respuesta exitosa — `200`:** Objeto `UserDto` actualizado.

**Errores:**

| Status | Condición |
|--------|-----------|
| `404` | Usuario no encontrado |
| `400` | Email/username ya en uso |

---

### `DELETE /api/web/users/{id}`

Elimina un usuario.

**Auth:** Bearer token — rol `Admin`

**Path params:** `id` (number)

**Respuesta exitosa — `204`:** Sin body.

**Errores:**

| Status | Condición |
|--------|-----------|
| `404` | Usuario no encontrado |

---

## Web — Noticias

### `GET /api/web/news`

Retorna todas las noticias con contenido completo.

**Auth:** Bearer token — rol `Admin` o `User`

**Sin request body.**

**Respuesta exitosa — `200`:**

```json
[
  {
    "id": 1,
    "title": "Lanzamiento de .NET 10",
    "authorId": 1,
    "authorName": "Admin User",
    "content": "Microsoft anunció hoy...",
    "publishedAt": "2025-05-25T18:00:00Z",
    "imageUrl": "https://example.com/dotnet10.jpg"
  }
]
```

| Campo | Tipo |
|-------|------|
| `id` | number |
| `title` | string |
| `authorId` | number |
| `authorName` | string |
| `content` | string |
| `publishedAt` | string (ISO 8601) |
| `imageUrl` | string \| null |

Ordenado por `publishedAt DESC`.

---

### `GET /api/web/news/{id}`

Retorna una noticia por ID con contenido completo.

**Auth:** Bearer token — rol `Admin` o `User`

**Path params:** `id` (number)

**Respuesta exitosa — `200`:** Un objeto `NewsDto` (mismo shape que el array).

**Errores:**

| Status | Condición |
|--------|-----------|
| `404` | Noticia no encontrada |

---

### `POST /api/web/news`

Crea una nueva noticia. El `authorId` se toma automáticamente del JWT del admin autenticado.

**Auth:** Bearer token — rol `Admin`

**Request body:**

```json
{
  "title": "Nuevo artículo de tecnología",
  "content": "Contenido completo del artículo...",
  "imageUrl": "https://example.com/imagen.jpg"
}
```

| Campo | Tipo | Reglas |
|-------|------|--------|
| `title` | string | requerido, máx 200 caracteres |
| `content` | string | requerido |
| `imageUrl` | string \| null | opcional, máx 500 caracteres |

**Respuesta exitosa — `201`:** Objeto `NewsDto`.

**Errores:**

| Status | Condición |
|--------|-----------|
| `400` | Validación fallida |

---

### `PUT /api/web/news/{id}`

Actualiza una noticia existente. Todos los campos son opcionales.

**Auth:** Bearer token — rol `Admin`

**Path params:** `id` (number)

**Request body:**

```json
{
  "title": "Título actualizado",
  "content": "Contenido actualizado...",
  "imageUrl": "https://example.com/nueva-imagen.jpg"
}
```

| Campo | Tipo | Reglas |
|-------|------|--------|
| `title` | string \| null | máx 200, si se envía |
| `content` | string \| null | sin restricción de longitud, si se envía |
| `imageUrl` | string \| null | máx 500, si se envía |

**Respuesta exitosa — `200`:** Objeto `NewsDto` actualizado.

**Errores:**

| Status | Condición |
|--------|-----------|
| `404` | Noticia no encontrada |

---

### `DELETE /api/web/news/{id}`

Elimina una noticia. Elimina en cascada los favoritos asociados.

**Auth:** Bearer token — rol `Admin`

**Path params:** `id` (number)

**Respuesta exitosa — `204`:** Sin body.

**Errores:**

| Status | Condición |
|--------|-----------|
| `404` | Noticia no encontrada |

---

## Wearable — Noticias

Versión ligera para dispositivos con limitaciones de red (smartwatch). Omite el campo `content`.

### `GET /api/wearable/news`

Retorna todas las noticias sin contenido.

**Auth:** Bearer token — rol `Admin` o `User`

**Sin request body.**

**Respuesta exitosa — `200`:**

```json
[
  {
    "id": 1,
    "title": "Lanzamiento de .NET 10",
    "authorName": "Admin User",
    "publishedAt": "2025-05-25T18:00:00Z",
    "imageUrl": "https://example.com/dotnet10.jpg"
  }
]
```

| Campo | Tipo |
|-------|------|
| `id` | number |
| `title` | string |
| `authorName` | string |
| `publishedAt` | string (ISO 8601) |
| `imageUrl` | string \| null |

Ordenado por `publishedAt DESC`.

---

### `GET /api/wearable/news/{id}`

Retorna una noticia por ID sin contenido.

**Auth:** Bearer token — rol `Admin` o `User`

**Path params:** `id` (number)

**Respuesta exitosa — `200`:** Un objeto `NewsWearableDto` (mismo shape que el array).

**Errores:**

| Status | Condición |
|--------|-----------|
| `404` | Noticia no encontrada |

---

## Favoritos

El userId se extrae automáticamente del JWT. Un usuario solo puede ver y gestionar sus propios favoritos.

### `GET /api/favorites`

Retorna los favoritos del usuario autenticado.

**Auth:** Bearer token — rol `Admin` o `User`

**Sin request body.**

**Respuesta exitosa — `200`:**

```json
[
  {
    "id": 3,
    "newsId": 1,
    "newsTitle": "Lanzamiento de .NET 10",
    "newsImageUrl": "https://example.com/dotnet10.jpg",
    "addedAt": "2025-05-25T20:00:00Z"
  }
]
```

| Campo | Tipo |
|-------|------|
| `id` | number — ID del registro favorito |
| `newsId` | number — ID de la noticia |
| `newsTitle` | string |
| `newsImageUrl` | string \| null |
| `addedAt` | string (ISO 8601) |

Ordenado por `addedAt DESC`.

---

### `POST /api/favorites`

Agrega una noticia a los favoritos del usuario autenticado.

**Auth:** Bearer token — rol `Admin` o `User`

**Request body:**

```json
{
  "newsId": 1
}
```

| Campo | Tipo | Reglas |
|-------|------|--------|
| `newsId` | number | requerido |

**Respuesta exitosa — `201`:** Objeto `FavoriteDto` (mismo shape que los del GET).

**Errores:**

| Status | Condición |
|--------|-----------|
| `400` | La noticia ya está en favoritos |
| `404` | Noticia no encontrada |

---

### `DELETE /api/favorites/{newsId}`

Elimina una noticia de los favoritos del usuario autenticado.

**Auth:** Bearer token — rol `Admin` o `User`

**Path params:** `newsId` (number) — ID de la noticia (no el ID del favorito)

**Respuesta exitosa — `204`:** Sin body.

**Errores:**

| Status | Condición |
|--------|-----------|
| `404` | Favorito no encontrado |

---

## Perfil

El usuario autenticado gestiona su propio perfil. El `role` no se puede cambiar desde aquí.

### `GET /api/profile`

Retorna el perfil del usuario autenticado.

**Auth:** Bearer token — rol `Admin` o `User`

**Sin request body.**

**Respuesta exitosa — `200`:** Objeto `UserDto`:

```json
{
  "id": 2,
  "fullName": "Normal User",
  "username": "usuario",
  "email": "user@pwa-news.com",
  "role": "User",
  "createdAt": "2025-05-25T18:30:00Z"
}
```

**Errores:**

| Status | Condición |
|--------|-----------|
| `404` | Usuario no encontrado (no debería ocurrir con token válido) |

---

### `PUT /api/profile`

Actualiza el perfil del usuario autenticado. Todos los campos son opcionales.

**Auth:** Bearer token — rol `Admin` o `User`

**Request body:**

```json
{
  "fullName": "Mi Nombre Actualizado",
  "username": "nuevousername",
  "email": "nuevo@email.com",
  "password": "NuevoPass123!"
}
```

| Campo | Tipo | Reglas |
|-------|------|--------|
| `fullName` | string \| null | máx 100, si se envía |
| `username` | string \| null | 3–50, `[a-zA-Z0-9_]`, si se envía |
| `email` | string \| null | formato email, si se envía |
| `password` | string \| null | mín 6 caracteres, si se envía |

> El campo `role` no está disponible aquí. Para cambiar el rol de un usuario usa `PUT /api/web/users/{id}` (requiere Admin).

**Respuesta exitosa — `200`:** Objeto `UserDto` actualizado.

**Errores:**

| Status | Condición |
|--------|-----------|
| `400` | Email/username ya en uso por otro usuario |
| `404` | Usuario no encontrado |

---

## Credenciales por defecto (seeded)

| Username | Email | Password | Rol |
|----------|-------|----------|-----|
| `admin` | `admin@pwa-news.com` | `Admin1234!` | Admin |
| `usuario` | `user@pwa-news.com` | `User1234!` | User |

---

## Flujo típico del cliente web

```
1. POST /api/auth/login                → obtener token + userId
2. GET  /api/web/news                  → listar noticias
3. GET  /api/web/news/{id}             → leer noticia completa
4. POST /api/favorites { newsId }      → marcar favorito
5. GET  /api/favorites                 → ver mis favoritos
6. DELETE /api/favorites/{newsId}      → quitar favorito
7. GET  /api/profile                   → ver mi perfil
8. PUT  /api/profile { ... }           → actualizar perfil
```

## Flujo típico del cliente wearable

```
1. POST /api/auth/login                → obtener token
2. GET  /api/wearable/news             → listar noticias (sin content)
3. GET  /api/wearable/news/{id}        → ver titular + imagen
```

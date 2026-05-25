# PWA News API

API REST para gestionar un sitio web de noticias de tecnología. Construida con **.NET 10** usando **Clean Architecture**, **FastEndpoints** y soporte para dos tipos de clientes: **Web** (funcionalidad completa) y **Wearable** (smartwatch, solo lectura de noticias).

---

## Tabla de Contenidos

- [Arquitectura](#arquitectura)
- [Stack Tecnológico](#stack-tecnológico)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Modelos de Datos](#modelos-de-datos)
- [Endpoints](#endpoints)
- [Autenticación y Autorización](#autenticación-y-autorización)
- [Patrón Result\<T\>](#patrón-resultt)
- [Configuración y Ejecución](#configuración-y-ejecución)
- [Credenciales por Defecto](#credenciales-por-defecto)

> **Referencia completa de endpoints para el frontend:** [`API.md`](./API.md)

---

## Arquitectura

El proyecto sigue **Clean Architecture** organizado en cuatro capas dentro de un solo proyecto .NET:

```
Domain         → Entidades, enums, Result<T>
Application    → DTOs, interfaces, servicios, validators, mappings
Infrastructure → EF Core (commands), Dapper (queries), JWT
Api            → FastEndpoints, middleware, extensions
```

### Principio de dependencia
```
Api → Application ← Infrastructure
       ↓
     Domain
```

---

## Stack Tecnológico

| Componente         | Librería / Patrón                     |
|--------------------|---------------------------------------|
| Framework          | .NET 10 / ASP.NET Core                |
| Endpoints          | FastEndpoints 5.34                    |
| ORM (commands)     | Entity Framework Core 9 + PostgreSQL  |
| Queries (selects)  | Dapper 2.1 + IDbConnectionFactory     |
| Base de datos      | PostgreSQL (Supabase)                 |
| Autenticación      | JWT Bearer (JwtBearer 9)              |
| Hash de passwords  | BCrypt.Net-Next 4.0                   |
| Validación         | FluentValidation 11 (integrado en FE) |
| Mapping            | AutoMapper 14                         |
| Documentación      | Scalar + FastEndpoints.Swagger        |
| Patrones           | Result\<T\>, Repository, Clean Arch   |

---

## Estructura del Proyecto

```
PWA-API/
├── Domain/
│   ├── Common/
│   │   └── Result.cs              # Patrón Result<T>
│   ├── Entities/
│   │   ├── User.cs
│   │   ├── News.cs
│   │   └── Favorite.cs
│   └── Enums/
│       └── UserRole.cs            # Admin=1, User=2
│
├── Application/
│   ├── DTOs/
│   │   ├── Auth/                  # LoginRequest, RegisterRequest, LoginResponse
│   │   ├── Users/                 # UserDto, CreateUserDto, UpdateUserDto
│   │   ├── News/                  # NewsDto, NewsWearableDto, CreateNewsDto, UpdateNewsDto
│   │   └── Favorites/             # FavoriteDto
│   ├── Interfaces/
│   │   ├── Dapper/                # IDbConnectionFactory
│   │   ├── Repositories/          # IUserRepository, INewsRepository, IFavoriteRepository
│   │   └── Services/              # IAuthService, IUserService, INewsService, IFavoriteService, INewsQueryService, ITokenService
│   ├── Services/                  # Implementaciones de los servicios
│   ├── Validators/                # FluentValidation validators
│   └── Mappings/
│       └── MappingProfile.cs      # AutoMapper profiles
│
├── Infrastructure/
│   ├── Persistence/
│   │   ├── AppDbContext.cs        # EF Core DbContext
│   │   ├── Configurations/        # Fluent API configurations
│   │   ├── Repositories/          # Implementaciones EF (commands)
│   │   └── DbSeeder.cs            # Datos iniciales
│   ├── Dapper/
│   │   ├── NpgsqlConnectionFactory.cs  # IDbConnectionFactory → PostgreSQL
│   │   └── NewsQueryService.cs         # Queries con Dapper
│   └── Services/
│       └── JwtTokenService.cs     # Generación de JWT
│
├── Api/
│   ├── Endpoints/
│   │   ├── Auth/                  # Login, Register
│   │   ├── Web/
│   │   │   ├── Users/             # CRUD completo (Admin)
│   │   │   └── News/              # CRUD completo (Admin) + lectura (User)
│   │   ├── Wearable/
│   │   │   └── News/              # Solo GET (Admin, User)
│   │   ├── Favorites/             # GET, POST, DELETE
│   │   └── Profile/               # GET, PUT
│   ├── Extensions/
│   │   ├── ServiceExtensions.cs   # Registro de servicios DI
│   │   └── ClaimsExtensions.cs    # Helpers para ClaimsPrincipal
│   └── Middleware/
│       └── GlobalExceptionHandler.cs
│
├── Migrations/                    # EF Core migrations
├── appsettings.json
├── appsettings.Development.json
└── Program.cs
```

---

## Modelos de Datos

### User (Usuario)

| Campo        | Tipo       | Descripción                    |
|--------------|------------|--------------------------------|
| Id           | int (PK)   | Identificador único            |
| FullName     | string     | Nombre completo (max 100)      |
| Username     | string     | Username único (max 50)        |
| Email        | string     | Email único (max 200)          |
| PasswordHash | string     | Hash BCrypt de la contraseña   |
| Role         | enum       | 1=Admin, 2=User                |
| CreatedAt    | DateTime   | Fecha de registro              |

### News (Noticia)

| Campo       | Tipo       | Descripción                     |
|-------------|------------|---------------------------------|
| Id          | int (PK)   | Identificador único             |
| Title       | string     | Título (max 200)                |
| AuthorId    | int (FK)   | Referencia a User.Id            |
| Content     | string     | Contenido completo              |
| PublishedAt | DateTime   | Fecha de publicación            |
| ImageUrl    | string?    | URL de imagen (max 500)         |

### Favorite (Favorito)

| Campo   | Tipo       | Descripción              |
|---------|------------|--------------------------|
| Id      | int (PK)   | Identificador único      |
| UserId  | int (FK)   | Referencia a User.Id     |
| NewsId  | int (FK)   | Referencia a News.Id     |
| AddedAt | DateTime   | Fecha en que se agregó   |

> Índice único compuesto en (UserId, NewsId) para evitar duplicados.

---

## Endpoints

### Autenticación (público)

| Método | Ruta                  | Descripción                      | Auth |
|--------|-----------------------|----------------------------------|------|
| POST   | /api/auth/login       | Login con email y password       | No   |
| POST   | /api/auth/register    | Registro (rol User por defecto)  | No   |

**Body Login:**
```json
{
  "email": "admin@pwa-news.com",
  "password": "Admin1234!"
}
```

**Respuesta Login:**
```json
{
  "token": "eyJhbGci...",
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

---

### Web - Usuarios (Admin only)

| Método | Ruta                  | Descripción           |
|--------|-----------------------|-----------------------|
| GET    | /api/web/users        | Listar todos          |
| GET    | /api/web/users/{id}   | Obtener por ID        |
| POST   | /api/web/users        | Crear usuario         |
| PUT    | /api/web/users/{id}   | Actualizar usuario    |
| DELETE | /api/web/users/{id}   | Eliminar usuario      |

---

### Web - Noticias

| Método | Ruta                  | Descripción               | Roles         |
|--------|-----------------------|---------------------------|---------------|
| GET    | /api/web/news         | Listar todas (con autor)  | Admin, User   |
| GET    | /api/web/news/{id}    | Obtener por ID            | Admin, User   |
| POST   | /api/web/news         | Crear noticia             | Admin         |
| PUT    | /api/web/news/{id}    | Actualizar noticia        | Admin         |
| DELETE | /api/web/news/{id}    | Eliminar noticia          | Admin         |

**Body Create News:**
```json
{
  "title": "Título de la noticia",
  "content": "Contenido completo de la noticia...",
  "imageUrl": "https://example.com/imagen.jpg"
}
```

---

### Wearable - Noticias (versión ligera)

| Método | Ruta                      | Descripción                      | Roles       |
|--------|---------------------------|----------------------------------|-------------|
| GET    | /api/wearable/news        | Listar noticias (sin contenido)  | Admin, User |
| GET    | /api/wearable/news/{id}   | Obtener por ID (sin contenido)   | Admin, User |

> Los endpoints Wearable devuelven `NewsWearableDto` que omite el campo `Content` para reducir el payload en dispositivos con limitaciones de red.

---

### Favoritos

| Método | Ruta                        | Descripción             | Roles       |
|--------|-----------------------------|-------------------------|-------------|
| GET    | /api/favorites              | Mis favoritos           | Admin, User |
| POST   | /api/favorites              | Agregar a favoritos     | Admin, User |
| DELETE | /api/favorites/{newsId}     | Quitar de favoritos     | Admin, User |

**Body Add Favorite:**
```json
{
  "newsId": 1
}
```

---

### Perfil

| Método | Ruta          | Descripción               | Roles       |
|--------|---------------|---------------------------|-------------|
| GET    | /api/profile  | Ver mi perfil             | Admin, User |
| PUT    | /api/profile  | Actualizar mi perfil      | Admin, User |

> El endpoint PUT de perfil no permite cambiar el `role`.

---

## Autenticación y Autorización

La API usa **JWT Bearer Token**. Para acceder a los endpoints protegidos:

1. Obtener el token mediante `POST /api/auth/login`
2. Incluir el header en cada request:
   ```
   Authorization: Bearer <token>
   ```

### Roles

| Rol   | Valor | Permisos                                          |
|-------|-------|---------------------------------------------------|
| Admin | 1     | CRUD usuarios, CRUD noticias, favoritos, perfil   |
| User  | 2     | Leer noticias, favoritos, perfil                  |

---

## Patrón Result\<T\>

Todos los servicios retornan `Result<T>` en lugar de lanzar excepciones para flujos de negocio:

```csharp
// Éxito
Result<UserDto>.Success(userDto)              // 200
Result<UserDto>.Success(userDto, 201)         // 201

// Errores
Result<UserDto>.Failure("Email ya en uso")    // 400
Result<UserDto>.NotFound("Usuario no encontrado") // 404
Result<UserDto>.Unauthorized("Credenciales inválidas") // 401
Result<UserDto>.Forbidden("Sin permisos")     // 403
```

---

## Configuración y Ejecución

### Pre-requisitos
- .NET 10 SDK
- Conexión a la base de datos PostgreSQL (Supabase)

### Variables de configuración (`appsettings.json`)

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=<pooler-host>;Database=postgres;Username=postgres.<project-ref>;Password=<password>;SSL Mode=Require;Trust Server Certificate=true"
  },
  "Jwt": {
    "Secret": "your-super-secret-jwt-key-that-is-at-least-32-chars!",
    "Issuer": "pwa-api",
    "Audience": "pwa-client",
    "ExpiresInMinutes": "1440"
  }
}
```

> **Importante**: En producción, cambiar el `Jwt:Secret` por una clave segura y almacenarlo en variables de entorno. Usar siempre el host del **connection pooler** de Supabase (no el host directo) para garantizar resolución IPv4.

### Pasos para ejecutar

```bash
# Restaurar dependencias y ejecutar
cd PWA-API
dotnet run

# La API estará disponible en:
# http://localhost:5273
```

### Documentación interactiva (Scalar)

Una vez ejecutando, visita:
```
http://localhost:5273/scalar/v1
```

### Swagger JSON

```
http://localhost:5273/swagger/v1/swagger.json
```

---

## Credenciales por Defecto

El `DbSeeder` crea automáticamente estos usuarios al iniciar la aplicación por primera vez:

| Usuario | Email                  | Password     | Rol   |
|---------|------------------------|--------------|-------|
| admin   | admin@pwa-news.com     | Admin1234!   | Admin |
| usuario | user@pwa-news.com      | User1234!    | User  |

También crea 3 noticias de ejemplo.

---

## Diseño Clave

### CQRS simplificado (EF + Dapper)

- **EF Core** → operaciones de escritura (Create, Update, Delete) via repositorios
- **Dapper** → operaciones de lectura (queries SELECT), usando `IDbConnectionFactory` para obtener conexiones SQLite

```csharp
// Factory para Dapper
public interface IDbConnectionFactory
{
    IDbConnection CreateConnection();
}

// Implementación PostgreSQL
public class NpgsqlConnectionFactory(string connectionString) : IDbConnectionFactory
{
    public IDbConnection CreateConnection()
    {
        var connection = new NpgsqlConnection(connectionString);
        connection.Open();
        return connection;
    }
}
```

### Endpoints separados por cliente

Los endpoints están organizados por `platform`:
- `/api/web/*` → cliente web, payload completo
- `/api/wearable/*` → smartwatch, payload reducido (sin `Content` en noticias)

### Validación con FluentValidation

FastEndpoints integra FluentValidation de forma nativa mediante `Validator<TValidator>()` en `Configure()`. Las validaciones se ejecutan automáticamente antes del handler y devuelven errores estructurados:

```json
{
  "status": 400,
  "errors": [
    { "field": "Email", "message": "Email is not a valid email address." },
    { "field": "Password", "message": "Password must be at least 6 characters." }
  ]
}
```

### Global Exception Handler

El middleware `GlobalExceptionHandler` captura todas las excepciones no manejadas y las convierte en respuestas JSON estructuradas, evitando que stack traces lleguen al cliente.

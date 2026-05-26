# TechNews PWA

Blog de noticias tecnológicas construido con **Flutter**, diseñado para correr en web y en dispositivos wearable (smartwatch). Consume una API REST con autenticación JWT y soporta dos roles de usuario: Admin y User.

---

## Características

- **Autenticación** con JWT (login / registro)
- **Modo web** — lista y detalle de noticias, favoritos, perfil de usuario
- **Modo wearable** — vista compacta sin contenido completo, adaptada a pantallas pequeñas (≤ 320 px)
- **Panel de administración** — CRUD de noticias y gestión de usuarios (solo rol Admin)
- **Diseño responsivo** con tema oscuro

## Arquitectura

```
lib/
├── core/           # Constantes, tema y utilidades
├── models/         # Modelos de datos (User, News, Favorite)
├── providers/      # Estado global con Provider (AuthProvider)
└── screens/
    ├── auth/       # Login y registro
    ├── web/        # Pantallas para web (noticias, favoritos, perfil, admin)
    └── wearable/   # Pantallas para smartwatch
```

El enrutamiento usa **go_router** con redirección automática según estado de autenticación. La detección de modo wearable se basa en el ancho de pantalla (breakpoint: 320 px).

## Credenciales de prueba

| Username  | Email                  | Password     | Rol   |
|-----------|------------------------|--------------|-------|
| `admin`   | `admin@pwa-news.com`   | `Admin1234!` | Admin |
| `usuario` | `user@pwa-news.com`    | `User1234!`  | User  |

---

## Cómo ejecutar el proyecto

### Requisitos previos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.9.0`
- Dart `^3.9.0`
- La API backend corriendo en `http://localhost:5273` (ver `API.md` para referencia de endpoints)

Verifica tu instalación de Flutter:

```bash
flutter doctor
```

### Instalar dependencias

```bash
flutter pub get
```

### Ejecutar en web (modo desarrollo)

```bash
flutter run -d chrome
```

Para especificar el puerto:

```bash
flutter run -d chrome --web-port 3000
```

### Ejecutar en modo wearable

La app detecta automáticamente el modo wearable cuando el ancho de pantalla es ≤ 320 px. Para simular este modo en Chrome:

1. Abre DevTools (F12)
2. Activa el modo de dispositivo responsivo
3. Establece el ancho a 320 px o menos

Alternativamente, si tienes un emulador de smartwatch configurado:

```bash
flutter run -d <device-id>
```

Lista los dispositivos disponibles con `flutter devices`.

### Compilar para producción

```bash
flutter build web --release
```

Los archivos compilados quedan en `build/web/`.

### Cambiar la URL del backend

Edita `lib/core/constants.dart`:

```dart
class AppConstants {
  static const String baseUrl = 'http://localhost:5273'; // cambia aquí
}
```

---

## API

La referencia completa de endpoints está en [`API.md`](API.md).

La URL base por defecto es `http://localhost:5273`. Todos los endpoints (excepto login y registro) requieren un header `Authorization: Bearer <token>`.

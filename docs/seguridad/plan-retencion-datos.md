# Plan de retención de datos — TechNews

Este documento describe qué datos personales guarda TechNews, dónde, por cuánto tiempo y cómo se eliminan.
Es la contraparte técnica de la sección 5 del [aviso de privacidad](../../lib/screens/legal/privacy_policy_screen.dart)
(`/privacy` dentro de la app).

## Datos almacenados localmente (dispositivo del usuario)

| Dato | Dónde | Se crea | Se elimina |
|---|---|---|---|
| Token JWT (`auth_token`) | `SharedPreferences` (`ApiClient._tokenKey`) | Al iniciar sesión o registrarse | Al cerrar sesión manualmente, o automáticamente **30 días** después de creado (ver estado de implementación abajo) |
| Perfil en caché (`user_id`, `user_full_name`, `user_username`, `user_email`, `user_role`) | `SharedPreferences` (`AuthProvider._persist`) | Junto con el token, al iniciar sesión | Junto con el token (mismo ciclo de vida) |

No se guarda contraseña en ningún momento en el cliente — ni en texto plano ni cifrada.

## Datos almacenados en el servidor (base de datos)

| Dato | Tabla / entidad | Finalidad | Retención |
|---|---|---|---|
| Nombre, username, email, contraseña (hash), rol | `Users` | Autenticación y personalización | Mientras la cuenta esté activa; se elimina si el usuario solicita baja (derecho de cancelación ARCO) |
| Favoritos guardados | `Favorites` | Función de guardado del usuario | Mientras la cuenta esté activa; se elimina en cascada si se elimina la noticia o la cuenta |
| Noticias | `News` | Contenido editorial público | Indefinida (es contenido público, no dato personal) |

## Política de expiración de sesión local (30 días)

**Regla:** el token y el perfil cacheado localmente se consideran válidos por 30 días desde su creación. Al
iniciar la app, si han pasado más de 30 días desde que se guardó el token, la sesión se cierra
automáticamente (equivalente a un logout silencioso) sin requerir acción del usuario.

**Estado de implementación:** Documentado aquí y comprometido para el nivel Autónomo (AU.4) del proyecto.
El mecanismo consiste en:

1. Guardar un timestamp de creación (`session_created_at`) junto con el token, la primera vez que se
   persiste la sesión.
2. En `AuthProvider.initialize()`, comparar `DateTime.now()` contra ese timestamp; si la diferencia supera
   30 días, invocar la misma limpieza que `logout()` en vez de restaurar la sesión.

Este mecanismo es independiente de la expiración del JWT en sí (`expiresIn`, controlada por el backend, del
orden de horas) — es una capa adicional de higiene de datos locales, no de seguridad de autenticación.

## Derechos ARCO

El usuario puede ejercer sus derechos de Acceso, Rectificación, Cancelación y Oposición:

- **Acceso/Rectificación:** desde `/profile` dentro de la app.
- **Cancelación:** escribiendo a través de `/contact`; al día de hoy no existe autoservicio de "eliminar mi
  cuenta" en la UI — es un pendiente para una futura iteración, gestionado manualmente por el equipo mientras
  tanto.
- **Oposición:** dejar de usar la app y cerrar sesión detiene toda recolección; no hay tracking en segundo
  plano ni tras cerrar sesión.

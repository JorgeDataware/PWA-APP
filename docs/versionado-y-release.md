# Versionado y liberación — TechNews PWA

Documento de la versión: qué significa cada número, cómo se comprueba que una
versión es estable y qué pasos se siguen para liberarla.

La bitácora de cambios vive en [`CHANGELOG.md`](../CHANGELOG.md).

---

## 1. Esquema de versiones

Se usa **Versionado Semántico** (`MAYOR.MENOR.PARCHE`):

| Componente | Se incrementa cuando… | Ejemplo en este proyecto |
|---|---|---|
| **MAYOR** | Hay un cambio incompatible: se rompe el contrato de la API, se elimina una pantalla o cambia el modelo de datos de forma no retrocompatible | Aún en 1 — no ha ocurrido |
| **MENOR** | Se agrega funcionalidad de forma retrocompatible | 1.2.0 (soporte Wear OS), 1.4.0 (panel de control) |
| **PARCHE** | Sólo correcciones que no cambian la funcionalidad ofrecida | Un hotfix sobre 1.4.0 sería 1.4.1 |

La versión vive en un solo lugar, `pubspec.yaml`:

```yaml
version: 1.4.0+5
```

- `1.4.0` es el **nombre de versión** (`versionName` en Android, visible al usuario).
- `+5` es el **número de compilación** (`versionCode` en Android). Es un entero que
  **siempre** aumenta, incluso entre parches; Google Play rechaza una subida cuyo
  `versionCode` no sea mayor al anterior.

Android toma ambos valores de `pubspec.yaml` a través del plugin de Gradle de
Flutter (`flutter.versionCode` / `flutter.versionName` en
`android/app/build.gradle.kts`), así que no se editan por separado.

---

## 2. Comprobación de versión estable

Una versión se considera **estable** cuando pasa las cuatro puertas siguientes.
Las tres primeras son automáticas y las ejecuta el pipeline
([`.github/workflows/ci.yml`](../.github/workflows/ci.yml)) en cada push a `main`;
la cuarta es manual.

| # | Puerta | Comando | Criterio |
|---|---|---|---|
| 1 | Análisis estático | `flutter analyze` | `No issues found!` — ningún hallazgo, ni siquiera `info`, llega a producción |
| 2 | Pruebas automatizadas | `flutter test` | 100% en verde (52/52 al liberar 1.4.0) |
| 3 | Compilación de release | `flutter build web --release --no-web-resources-cdn` | Termina sin errores; el despliegue a Vercel sólo corre si esta puerta pasa |
| 4 | Verificación manual | ver [`pruebas/plan-de-pruebas.md`](pruebas/plan-de-pruebas.md) | Pruebas manuales M1–M7 y ejecución en emulador Wear OS sin regresiones |

Ejecución local completa antes de etiquetar:

```bash
cd PWA-APP && flutter analyze && flutter test && flutter build web --release --no-web-resources-cdn
```

---

## 3. Procedimiento de liberación

1. Actualizar `version:` en `pubspec.yaml` (nombre **y** número de compilación).
2. Agregar la sección correspondiente en `CHANGELOG.md`, con la fecha y los
   commits que la componen.
3. Correr las cuatro puertas de la sección anterior.
4. Confirmar los cambios y etiquetar:

   ```bash
   git commit -am "Release v1.4.0"
   git tag -a v1.4.0 -m "TechNews PWA 1.4.0"
   git push origin main --follow-tags
   ```

5. Publicar el Release en GitHub usando la sección del `CHANGELOG.md` como notas.

La etiqueta (`vMAYOR.MENOR.PARCHE`) es la que permite volver a compilar
exactamente el código que se liberó, y debe coincidir con `version:` de
`pubspec.yaml`.

---

## 4. Artefactos de cada versión

| Artefacto | Cómo se genera | Dónde queda |
|---|---|---|
| PWA (web) | `flutter build web --release --no-web-resources-cdn` | Desplegada automáticamente en Vercel por el pipeline |
| APK Wear OS / Android | `flutter build apk --release` | `build/app/outputs/flutter-apk/app-release.apk` |
| APK por ABI (más ligero) | `flutter build apk --release --split-per-abi` | Un APK por arquitectura, en la misma carpeta |
| Bundle para Play Store | `flutter build appbundle --release` | `build/app/outputs/bundle/release/app-release.aab` |

> **Pendiente antes de publicar en Play Store:** el `applicationId` sigue siendo
> `com.example.pwa_app` y el build de release se firma con la llave de depuración
> (`android/app/build.gradle.kts`). Ambos deben cambiarse a un identificador propio
> y a un keystore real; hasta entonces los APK sirven para pruebas e instalación
> directa, no para distribución.

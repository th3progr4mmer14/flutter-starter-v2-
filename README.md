# Flutter Starter

Plantilla base para apps Flutter (pensada para apps de **monitoreo**). Se usa con
**Use this template** en GitHub y se encienden solo los módulos que el proyecto necesita.

**Stack:** Riverpod · go_router · Dio · SharedPreferences · flutter_secure_storage · gen-l10n (es/en)

---

## 1. Proyecto nuevo (paso a paso)

1. En GitHub: **Use this template** y clona el repo nuevo.
2. Renombra la app y el paquete:
   ```bash
   dart pub global activate rename
   rename setAppName --targets ios,android --value "Mi App"
   rename setBundleId --targets ios,android --value com.tuempresa.miapp
   ```
   Cambia también `name:` en `pubspec.yaml` y, si renombraste el paquete, los imports
   `package:flutter_starter_v2/...` (los de `lib/` son relativos, casi no hay que tocar).
3. Pon el `applicationId` real en `lib/features/map/map_defaults.dart` (`userAgentPackage`)
   y ajusta el centro del mapa a tu zona.
4. Colores de la marca: `lib/core/theme/app_colors.dart`.
5. **Enciende o apaga módulos:** `lib/core/config/app_modules.dart` (sección 2).
6. Instala y corre:
   ```bash
   flutter pub get
   flutter gen-l10n
   flutter run
   ```
   El login arranca en **modo demo** (cualquier correo válido y contraseña de 6+ caracteres).

---

## 2. Módulos

Edita los `enableX` en `lib/core/config/app_modules.dart`. El menú, las rutas, el dashboard,
los reportes y los servicios de fondo se ajustan solos.

| Módulo | Qué incluye | Necesita | Paquetes extra |
|---|---|---|---|
| **Núcleo** (siempre) | Login/sesión, ajustes (tema, idioma, notificaciones, monitoreo), menú, l10n | - | - |
| `dashboard` | KPIs, gráfica en vivo, alertas recientes | muestra lo que haya de devices/alerts | `fl_chart` |
| `devices` | CRUD de dispositivos (buscar, filtrar, crear, editar, borrar) | - | - |
| `alerts` | Lista, filtro por severidad, reconocer, limpiar | - | - |
| `map` | Mapa en vivo, mi ubicación, recorridos, geocercas con alerta | `devices` (y `alerts` para las alertas de geocerca) | `flutter_map`, `latlong2`, `geolocator` |
| `reports` | Exportar dispositivos y alertas a PDF y CSV | `devices` y/o `alerts` | `pdf`, `file_saver` |

Las dependencias entre módulos ya están resueltas en los valores "efectivos" de
`AppModules` (por ejemplo, `map` se apaga solo si `devices` está apagado).

### Permisos por módulo
- **map (Android):** en `android/app/src/main/AndroidManifest.xml`, arriba de `<application>`:
  `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` e `INTERNET`.
- **map (iOS):** `NSLocationWhenInUseUsageDescription` en `ios/Runner/Info.plist`.
- **Cualquier módulo con mapa en release (Android):** `INTERNET` es obligatorio (en debug ya viene).
- **reports (iOS):** si no ves el archivo en la app Archivos, revisa la sección de iOS del README de `file_saver`.

### Quitar un módulo por completo
Apagar con el flag lo oculta, pero el código y los paquetes siguen en el repo. Para limpiarlos:

1. Pon el flag en `false`.
2. Borra la carpeta `lib/features/<modulo>/`.
3. Quita sus imports y su ruta en `lib/core/router/app_router.dart` (y en `lib/app.dart` si es `map`).
4. Quita los paquetes: `flutter pub remove <paquetes de la tabla>`.
5. Vuelve a poner `generate: true` si el `pub remove` lo borró (ver "Problemas conocidos").
6. Opcional: borra sus textos de `lib/l10n/app_es.arb` y `app_en.arb`.

Notas: `alerts` lo usan el dashboard, los reportes y las geocercas; `devices` lo usan el mapa
y los reportes. Para esos dos conviene **solo apagarlos** salvo que quites también lo que depende de ellos.

---

## 3. Del modo demo a un backend real

| Qué | Hoy | Para conectar tu API |
|---|---|---|
| Login | `LocalAuthRepository` | `--dart-define=USE_MOCK_AUTH=false --dart-define=API_URL=https://tu-api.com` y ajusta endpoints en `auth_remote_datasource.dart` |
| Dispositivos | `LocalDeviceRepository` (SharedPreferences) | Crea otra clase que implemente `DeviceRepository` y cámbiala en `deviceRepositoryProvider` |
| Alertas / geocercas | repos locales | Mismo patrón: interfaz + implementación remota + provider |
| Lecturas en vivo | simuladas en `live_metrics_provider.dart` | Reemplaza el cuerpo del provider (MQTT, WebSocket o polling) |
| Posiciones en vivo | simuladas en `live_locations_provider.dart` | Igual: que emita `Map<idDispositivo, LatLng>` |
| Recorridos | en memoria (`trails_controller.dart`) | Consulta de historial a tu backend o base local |

---

## 4. Estructura

```
lib/
├── main.dart, app.dart
├── core/
│   ├── config/    env.dart, app_modules.dart
│   ├── router/    app_router.dart, app_routes.dart
│   ├── theme/     app_colors.dart, app_theme.dart
│   ├── network/, errors/, storage/, providers/
├── shared/        widgets (menú, scaffold, tarjetas...), utils (validators), constants
├── l10n/          app_es.arb, app_en.arb (+ archivos generados)
└── features/
    ├── authentication/   settings/   dashboard/   devices/
    ├── alerts/   map/   reports/
```

Cada feature sigue el patrón: `domain` (modelo + contrato) → `data` (repositorio) →
`presentation/providers` → `presentation/screens`. **Copia `features/devices` como ejemplo.**

### Agregar un feature nuevo (a mano)
1. Copia `features/devices` y renómbralo.
2. Agrega su ruta en `app_routes.dart` y `app_router.dart`.
3. Agrega su entrada en `shared/widgets/app_menu.dart`.
4. (Opcional) crea su flag en `app_modules.dart`.
5. Agrega sus textos en los dos `.arb` y corre `flutter gen-l10n`.

### Agregar un idioma
Crea `lib/l10n/app_<codigo>.arb` con las mismas llaves y agrégalo al selector de
`features/settings/presentation/screens/appearance_screen.dart`.

---

## 5. Problemas conocidos

- **`generate: true` desaparece del `pubspec.yaml`** después de `flutter pub add/remove`.
  Si ves `lib/l10n/app_localizations.dart not found`, revisa la sección `flutter:`:
  ```yaml
  flutter:
    generate: true
    uses-material-design: true
  ```
  y corre `flutter gen-l10n`.
- **Linux de escritorio:** `flutter_secure_storage` pide `sudo dnf install libsecret-devel` (Fedora)
  o `libsecret-1-dev` (Debian/Ubuntu), y un llavero activo (gnome-keyring) para guardar la sesión.
- **Android:** `minSdk` 23 o mayor por `flutter_secure_storage`.
- **Mapa:** los mosaicos gratuitos de OpenStreetMap no son para tráfico alto en producción;
  usa un proveedor de tiles o tu propio servidor (cambia `tileUrl` en `map_defaults.dart`).
- **Datos demo:** los dispositivos de ejemplo se guardan con la llave `devices_v2`; si cambias
  el modelo, sube la versión de la llave en `local_device_repository.dart`.
- **PDF:** la fuente por defecto cubre acentos y ñ, pero no emojis ni símbolos raros.

---

## 6. Comandos útiles

```bash
flutter pub get && flutter gen-l10n   # dependencias + traducciones
flutter analyze                       # revisar antes de cada commit
dart fix --apply                      # arreglos automáticos de estilo
flutter run -d linux                  # o el id que muestre `flutter devices`
```

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
| `apiDemo` (apagado) | Ejemplo que consume una API pública (JSONPlaceholder): lista paginada, refrescar, scroll infinito | - | - |

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

## 3. Conectar una API (lo más común: te mandan el backend y tú haces el front)

### Checklist cuando recibes una API
Lee su Swagger/Postman y anota:
1. **URL base** y si hay entornos (dev/staging/prod).
2. **Autenticación:** Bearer (JWT), API key o ambas; si hay **refresh token** y en qué endpoint.
3. **Forma de las listas:** array directo o `{ "items": [...], "total": 120 }`.
4. **Paginación:** `page/limit`, `offset`, o cursor.
5. **¿Envuelve todo en `{ "data": ... }`?**
6. **Formato de errores** (`message`, `errors` por campo).

### Pasos
1. Ajusta lo que difiera en `lib/core/config/api_config.dart` (header, esquema del token, llaves de login/refresh,
   `dataKey`, nombres de paginación, llaves de lista).
2. Corre apuntando a la API:
   ```bash
   flutter run --dart-define=USE_MOCK_AUTH=false \
               --dart-define=API_URL=https://tu-api.com \
               --dart-define=API_KEY=xxxx        # solo si usa API key
   ```
3. **Login:** ajusta el endpoint y el cuerpo en `features/authentication/data/.../auth_remote_datasource.dart`.
   Los tokens (access y refresh) se guardan solos en almacenamiento seguro.
4. **Un recurso REST** (`/products`, `/products/{id}`...):
   ```dart
   final productsResourceProvider = Provider<RemoteResource<Product>>((ref) =>
       RemoteResource<Product>(
         client: ref.watch(apiClientProvider),
         path: '/products',
         fromJson: Product.fromJson,
         toJson: (p) => p.toJson(),
       ));
   // list(page:), getById(id), create(item), update(id, item), delete(id)
   ```
5. **Lista paginada** con refrescar y scroll infinito: hereda `PaginatedController<T>`, implementa
   `fetchPage(page)` y pinta con `PaginatedListView`. El ejemplo completo está en `features/api_demo`
   (enciéndelo con `enableApiDemo = true`).
6. **Un dato suelto o un detalle:** `FutureProvider` + `AsyncValueView` (cargando, error con reintento, datos, vacío):
   ```dart
   final productProvider = FutureProvider.family<Product, String>((ref, id) =>
       ref.watch(productsResourceProvider).getById(id));
   // en la pantalla:
   AsyncValueView<Product>(
     value: ref.watch(productProvider(id)),
     onRetry: () => ref.invalidate(productProvider(id)),
     data: (p) => ProductDetail(p),
   )
   ```
7. **Formularios:** si la API responde 400/422, `Failure.fieldErrors` trae `{campo: mensaje}` para pintarlos
   en cada campo, y `failure.localized(context.l10n)` da el mensaje listo para mostrar.

### Generar un feature completo desde un JSON (lo más rápido)
Copia la respuesta de ejemplo del endpoint (Postman/Swagger) a un archivo y corre:
```bash
python3 tool/new_api_feature.py product /products --json product.json \
    --label-es "Productos" --label-en "Products" --icon inventory_2_outlined
```
El JSON puede ser un objeto, una lista o la respuesta completa (`{"items": [...]}`, `{"data": [...]}`):
se toma el primer objeto para detectar los campos y sus tipos (texto, entero, decimal, booleano, fecha, lista,
objeto; los `null` quedan opcionales).

Genera `lib/features/<nombre>/` con modelo tolerante, `RemoteResource`, lista paginada (refrescar + scroll
infinito), formulario de crear/editar (según los campos detectados), borrar deslizando y detalle, y lo registra
en módulos, rutas, menú y textos es/en.

| Opción | Para qué |
|---|---|
| `--readonly` | Solo lista + detalle (sin crear, editar ni borrar) |
| `--no-detail` | Editar/ver usa el item de la lista, sin `GET /endpoint/{id}` |
| `--patch` | Editar con PATCH en vez de PUT |
| `--id-field LLAVE` | Si el id no se llama `id`, `_id` ni `uuid` |
| `--page-param X` / `--limit-param X` | Si la paginación usa otros nombres (`_page`, `offset`...) |
| `--json -` | Lee el JSON desde la entrada estándar (`curl ... \| python3 ...`) |

Después de generar: revisa tipos y nombres en `domain/<nombre>_item.dart`, y traduce las etiquetas de los campos
(`<nombre>Field...`) en los `.arb`. Si la API tiene un caso especial (filtros, subrecursos, cursor), el lugar para
tocar es el `fetchPage` del controller y el `RemoteResource` del feature.

### Qué te da `ApiClient` sin escribir nada
- Token (o API key) **solo hacia tu `API_URL`**: nunca se envía a otros hosts.
- Si la API responde **401**, renueva el token una vez y reintenta la petición; si ya no se puede, cierra
  la sesión y el router manda al login. Si el refresh falla solo por red, **no** te saca de la sesión.
- **Reintentos** de GET con falla de red/timeout (`ApiConfig.maxRetries`).
- **Errores tipados** (`Failure`: red, timeout, 401, 403, 404, validación, servidor).
- **Banner "sin conexión"** automático (se basa en el resultado de tus peticiones, no en el estado del Wi-Fi).
- Desenvuelve `{ "data": ... }` si lo configuras.

### Otras piezas que siguen en modo demo
| Qué | Hoy | Para pasar a tu API |
|---|---|---|
| Dispositivos / alertas / geocercas | repos locales (SharedPreferences) | Implementa el repositorio con `RemoteResource` y cámbialo en su provider |
| Lecturas en vivo | simuladas en `live_metrics_provider.dart` | Reemplaza el cuerpo del provider (MQTT, WebSocket o polling) |
| Posiciones en vivo | simuladas en `live_locations_provider.dart` | Que emita `Map<idDispositivo, LatLng>` |
| Recorridos | en memoria (`trails_controller.dart`) | Consulta de historial a tu backend |

---

## 4. Estructura

```
tool/            new_feature.sh (feature local), new_api_feature.py (feature desde JSON de API), aplicar_api.py
lib/
├── main.dart, app.dart
├── core/
│   ├── config/    env.dart, app_modules.dart
│   ├── router/    app_router.dart, app_routes.dart
│   ├── theme/     app_colors.dart, app_theme.dart
│   ├── network/    api_client.dart, remote_resource.dart
│   ├── pagination/ paginated_controller.dart
│   ├── errors/, storage/, providers/
├── shared/        widgets (menú, scaffold, tarjetas...), utils (validators), constants
├── l10n/          app_es.arb, app_en.arb (+ archivos generados)
└── features/
    ├── authentication/   settings/   dashboard/   devices/
    ├── alerts/   map/   reports/
```

Cada feature sigue el patrón: `domain` (modelo + contrato) → `data` (repositorio) →
`presentation/providers` → `presentation/screens`. **Copia `features/devices` como ejemplo.**

### Agregar un feature nuevo (generador)
Desde la raíz del proyecto:
```bash
bash tool/new_feature.sh <nombre_snake> ["Etiqueta ES"] ["Label EN"] [icono]

# ejemplos
bash tool/new_feature.sh inventario
bash tool/new_feature.sh work_order "Órdenes de trabajo" "Work orders" build_outlined
```
Crea `lib/features/<nombre>/` (domain, data con guardado local, controller, pantalla de lista
y formulario) y lo registra solo en: `app_modules.dart` (interruptor `enableX`), `app_routes.dart`,
`app_router.dart`, `app_menu.dart` y los dos `.arb`. Después corre `flutter gen-l10n`.
Es seguro de repetir: si el feature ya existe, se niega y no pisa nada.

El feature generado es un CRUD genérico (nombre + notas). Para personalizarlo:
1. Agrega los campos en `domain/<nombre>_item.dart` (modelo, `fromJson`, `toJson`, `copyWith`).
2. Agrégalos en el formulario y en la lista (`presentation/screens/`).
3. Para usar una API en vez de guardado local, crea otra clase que implemente
   `<Nombre>Repository` y cámbiala en `<nombre>RepositoryProvider`.

Si el script no puede editar algún archivo (porque lo cambiaste mucho), te imprime el
fragmento exacto para pegarlo a mano.

**A mano (sin el script):** copia `features/devices`, renómbralo, y registra la ruta
(`app_routes.dart` y `app_router.dart`), la entrada del menú (`app_menu.dart`), su interruptor
(`app_modules.dart`) y sus textos en los dos `.arb`.

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

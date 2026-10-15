#!/usr/bin/env python3
"""Aplica la capa de consumo de APIs a un proyecto con la plantilla.

Uso (desde la raiz del proyecto, DESPUES de copiar lib/ y tool/ del zip):
    python3 tool/aplicar_api.py

Hace (es seguro repetirlo):
  1) auth_repository_impl: guarda tambien el refresh token del login.
  2) registra el ejemplo `api_demo` (apagado por defecto) en app_modules,
     app_routes, app_router y app_menu.
  3) agrega los textos nuevos a los .arb (es/en) y corre flutter gen-l10n.
"""
import glob
import json
import os
import shutil
import subprocess
import sys

if not os.path.exists('lib/core/config/app_modules.dart'):
    sys.exit('ERROR: ejecuta este script desde la raiz del proyecto con la plantilla.')

manual = []


def read(p):
    with open(p, encoding='utf-8') as f:
        return f.read()


def write(p, s):
    with open(p, 'w', encoding='utf-8') as f:
        f.write(s)


def insert_before_line(path, marker, text, label):
    s = read(path)
    if text.strip() in s:
        return
    i = s.find(marker)
    if i < 0:
        manual.append((label, path, text))
        return
    start = s.rfind('\n', 0, i) + 1
    write(path, s[:start] + text + s[start:])


def insert_after_line(path, marker, text, label):
    s = read(path)
    if text.strip() in s:
        return
    i = s.find(marker)
    if i < 0:
        manual.append((label, path, text))
        return
    end = s.find('\n', i)
    end = len(s) if end < 0 else end + 1
    write(path, s[:end] + text + s[end:])


# ---------------------------------------------------------------- 1) refresh token
matches = glob.glob('lib/features/authentication/**/auth_repository_impl.dart', recursive=True)
if not matches:
    manual.append(('refresh token', 'auth_repository_impl.dart',
                   "await _tokens.saveTokens(\n  access: data[ApiConfig.accessTokenKey] as String,\n"
                   "  refresh: data[ApiConfig.refreshTokenKey] as String?,\n);"))
else:
    p = matches[0]
    s = read(p)
    if 'ApiConfig' not in s:
        old = "await _tokens.save(data['token'] as String);"
        new = ("await _tokens.saveTokens(\n"
               "      access: data[ApiConfig.accessTokenKey] as String,\n"
               "      refresh: data[ApiConfig.refreshTokenKey] as String?,\n"
               "    );")
        if old in s:
            rel = os.path.relpath('lib/core/config/api_config.dart', os.path.dirname(p)).replace(os.sep, '/')
            s = s.replace(old, new, 1)
            i = s.find("import '")
            s = s[:i] + f"import '{rel}';\n" + s[i:]
            write(p, s)
        else:
            manual.append(('refresh token', p, new))

# ---------------------------------------------------------------- 2) modulo demo
mods = 'lib/core/config/app_modules.dart'
insert_after_line(mods, 'static const bool enableReports',
                  '  static const bool enableApiDemo = false; // ejemplo que consume una API publica\n',
                  'interruptor')
insert_after_line(mods, 'static const bool reports =',
                  '  static const bool apiDemo = enableApiDemo;\n', 'valor efectivo')

insert_before_line('lib/core/router/app_routes.dart', "static const settings = '/settings';",
                   "  static const apiDemo = '/api_demo';\n\n", 'ruta')

router = 'lib/core/router/app_router.dart'
insert_before_line(router, "import '../config/app_modules.dart';",
                   "import '../../features/api_demo/presentation/screens/api_demo_screen.dart';\n",
                   'import del router')
insert_before_line(router, '// ---- Núcleo: ajustes ----',
                   "      if (AppModules.apiDemo)\n"
                   "        GoRoute(\n"
                   "          path: AppRoutes.apiDemo,\n"
                   "          builder: (_, _) => const ApiDemoScreen(),\n"
                   "        ),\n", 'ruta del router')

insert_before_line('lib/shared/widgets/app_menu.dart', '(AppRoutes.settings, Icons.settings_outlined',
                   "      if (AppModules.apiDemo)\n"
                   "        (AppRoutes.apiDemo, Icons.cloud_outlined, l.navApiDemo),\n", 'menu')

# ---------------------------------------------------------------- 3) textos
keys = {
    'errNetwork': ('Sin conexión a internet', 'No internet connection'),
    'errTimeout': ('La solicitud tardó demasiado', 'The request timed out'),
    'errUnauthorized': ('Tu sesión expiró. Inicia sesión de nuevo', 'Your session expired. Please sign in again'),
    'errForbidden': ('No tienes permiso para hacer esto', 'You do not have permission to do this'),
    'errNotFound': ('No se encontró el recurso', 'Resource not found'),
    'errValidation': ('Revisa los datos enviados', 'Please check the submitted data'),
    'errServer': ('Error del servidor. Intenta más tarde', 'Server error. Try again later'),
    'errUnknown': ('Ocurrió un error inesperado', 'Unexpected error'),
    'retry': ('Reintentar', 'Retry'),
    'offlineBanner': ('Sin conexión. Los datos pueden estar desactualizados', 'Offline. Data may be out of date'),
    'noResults': ('Sin resultados', 'No results'),
    'loadMore': ('Cargar más', 'Load more'),
    'navApiDemo': ('API demo', 'API demo'),
}
for loc, i in (('es', 0), ('en', 1)):
    p = f'lib/l10n/app_{loc}.arb'
    if not os.path.exists(p):
        manual.append(('textos', p, json.dumps({k: v[i] for k, v in keys.items()}, ensure_ascii=False, indent=2)))
        continue
    d = json.loads(read(p))
    for k, v in keys.items():
        d.setdefault(k, v[i])
    write(p, json.dumps(d, ensure_ascii=False, indent=2) + '\n')

print('Listo: archivos de registro actualizados.')

if shutil.which('flutter'):
    print('Generando traducciones (flutter gen-l10n)...')
    subprocess.run(['flutter', 'gen-l10n'], check=False)
else:
    print('No encontre flutter en el PATH: corre `flutter gen-l10n` a mano.')

if manual:
    print('\nOJO: no pude editar automaticamente estas partes. Agregalas a mano:')
    for label, path, text in manual:
        print(f'\n--- {label} -> {path}\n{text}')

print('\nSiguientes pasos:')
print('  1) Revisa que `generate: true` siga en pubspec.yaml y corre: flutter analyze')
print('  2) Para ver el ejemplo: enableApiDemo = true en lib/core/config/app_modules.dart')

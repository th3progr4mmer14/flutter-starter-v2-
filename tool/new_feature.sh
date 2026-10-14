#!/usr/bin/env bash
# Generador de features CRUD (lista + formulario + guardado local).
#
# Uso (desde la raíz del proyecto):
#   bash tool/new_feature.sh <nombre_snake> ["Etiqueta ES"] ["Label EN"] [icono]
#
# Ejemplos:
#   bash tool/new_feature.sh inventario
#   bash tool/new_feature.sh work_order "Órdenes de trabajo" "Work orders" build_outlined
#
# Crea lib/features/<nombre>/ y registra el módulo en: app_modules.dart,
# app_routes.dart, app_router.dart, app_menu.dart y los .arb (es/en).
# Es seguro de repetir: no duplica nada y no pisa features existentes.
set -euo pipefail

NAME="${1:-}"
LABEL_ES="${2:-}"
LABEL_EN="${3:-}"
ICON="${4:-folder_outlined}"

die() { echo "ERROR: $*" >&2; exit 1; }

[ -n "$NAME" ] || die "Falta el nombre. Uso: bash tool/new_feature.sh <nombre_snake> [\"Etiqueta ES\"] [\"Label EN\"] [icono]"
[[ "$NAME" =~ ^[a-z][a-z0-9_]*$ ]] || die "El nombre debe ir en minúsculas y snake_case (ej. work_order)"
command -v python3 >/dev/null || die "Se necesita python3 para editar los archivos de registro"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
[ -f lib/core/config/app_modules.dart ] || die "No encuentro lib/core/config/app_modules.dart. Ejecuta el script desde un proyecto con la plantilla."

DIR="lib/features/$NAME"
[ ! -e "$DIR" ] || die "Ya existe $DIR (no se pisa nada)"

# nombre -> PascalCase y camelCase
PASCAL="$(python3 -c "import sys;print(''.join(p.capitalize() for p in sys.argv[1].split('_') if p))" "$NAME")"
CAMEL="$(python3 -c "import sys;p=sys.argv[1];print(p[:1].lower()+p[1:])" "$PASCAL")"
[ -n "$LABEL_ES" ] || LABEL_ES="$(python3 -c "import sys;print(' '.join(p.capitalize() for p in sys.argv[1].split('_') if p))" "$NAME")"
[ -n "$LABEL_EN" ] || LABEL_EN="$LABEL_ES"

grep -q "static const $CAMEL = " lib/core/router/app_routes.dart && die "Ya existe una ruta llamada '$CAMEL' en app_routes.dart"
grep -q "enable$PASCAL" lib/core/config/app_modules.dart && die "Ya existe el módulo enable$PASCAL en app_modules.dart"

echo "Creando feature '$NAME' ($PASCAL)..."
mkdir -p "$DIR/domain" "$DIR/data" "$DIR/presentation/providers" "$DIR/presentation/screens"

# Reemplaza los marcadores de las plantillas
render() {
  sed -e "s/@@SNAKE@@/$NAME/g" -e "s/@@PASCAL@@/$PASCAL/g" -e "s/@@CAMEL@@/$CAMEL/g"
}

# ------------------------------------------------------------------ domain
render > "$DIR/domain/${NAME}_item.dart" <<'EOF'
class @@PASCAL@@Item {
  final String id;
  final String name;
  final String notes;

  const @@PASCAL@@Item({
    required this.id,
    required this.name,
    this.notes = '',
  });

  @@PASCAL@@Item copyWith({String? name, String? notes}) => @@PASCAL@@Item(
        id: id,
        name: name ?? this.name,
        notes: notes ?? this.notes,
      );

  factory @@PASCAL@@Item.fromJson(Map<String, dynamic> json) => @@PASCAL@@Item(
        id: json['id'] as String,
        name: json['name'] as String,
        notes: json['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'notes': notes};
}
EOF

render > "$DIR/domain/${NAME}_repository.dart" <<'EOF'
import '@@SNAKE@@_item.dart';

abstract class @@PASCAL@@Repository {
  Future<List<@@PASCAL@@Item>> getAll();
  Future<void> upsert(@@PASCAL@@Item item);
  Future<void> delete(String id);
}
EOF

# -------------------------------------------------------------------- data
render > "$DIR/data/local_${NAME}_repository.dart" <<'EOF'
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/@@SNAKE@@_item.dart';
import '../domain/@@SNAKE@@_repository.dart';

/// Guarda los registros como JSON en SharedPreferences.
/// Para una API o base de datos, crea otra clase que implemente
/// @@PASCAL@@Repository y cámbiala en @@CAMEL@@RepositoryProvider.
class Local@@PASCAL@@Repository implements @@PASCAL@@Repository {
  static const _key = '@@SNAKE@@_v1';

  final SharedPreferences _prefs;
  Local@@PASCAL@@Repository(this._prefs);

  Future<List<@@PASCAL@@Item>> _load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return <@@PASCAL@@Item>[];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => @@PASCAL@@Item.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _save(List<@@PASCAL@@Item> items) => _prefs.setString(
        _key,
        jsonEncode(items.map((i) => i.toJson()).toList()),
      );

  @override
  Future<List<@@PASCAL@@Item>> getAll() => _load();

  @override
  Future<void> upsert(@@PASCAL@@Item item) async {
    final list = await _load();
    final i = list.indexWhere((e) => e.id == item.id);
    if (i >= 0) {
      list[i] = item;
    } else {
      list.add(item);
    }
    await _save(list);
  }

  @override
  Future<void> delete(String id) async {
    final list = await _load();
    list.removeWhere((e) => e.id == id);
    await _save(list);
  }
}
EOF

# ------------------------------------------------------------ presentation
render > "$DIR/presentation/providers/${NAME}_controller.dart" <<'EOF'
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../data/local_@@SNAKE@@_repository.dart';
import '../../domain/@@SNAKE@@_item.dart';
import '../../domain/@@SNAKE@@_repository.dart';

final @@CAMEL@@RepositoryProvider = Provider<@@PASCAL@@Repository>(
  (ref) => Local@@PASCAL@@Repository(ref.watch(sharedPreferencesProvider)),
);

class @@PASCAL@@Controller extends AsyncNotifier<List<@@PASCAL@@Item>> {
  @@PASCAL@@Repository get _repo => ref.read(@@CAMEL@@RepositoryProvider);

  @override
  Future<List<@@PASCAL@@Item>> build() => _repo.getAll();

  Future<void> save(@@PASCAL@@Item item) async {
    await _repo.upsert(item);
    state = AsyncData(await _repo.getAll());
  }

  Future<void> delete(String id) async {
    // Actualiza la UI al instante (necesario para Dismissible) y luego persiste.
    final current = state.value ?? <@@PASCAL@@Item>[];
    state = AsyncData(current.where((i) => i.id != id).toList());
    await _repo.delete(id);
  }
}

final @@CAMEL@@ControllerProvider =
    AsyncNotifierProvider<@@PASCAL@@Controller, List<@@PASCAL@@Item>>(
        @@PASCAL@@Controller.new);
EOF

render > "$DIR/presentation/screens/${NAME}_screen.dart" <<'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../l10n/l10n_x.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/content_width.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/@@SNAKE@@_item.dart';
import '../providers/@@SNAKE@@_controller.dart';

class @@PASCAL@@Screen extends ConsumerWidget {
  const @@PASCAL@@Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final items = ref.watch(@@CAMEL@@ControllerProvider);

    return AppScaffold(
      title: l.nav@@PASCAL@@,
      currentRoute: AppRoutes.@@CAMEL@@,
      floatingActionButton: FloatingActionButton(
        tooltip: l.@@CAMEL@@Add,
        onPressed: () => context.push(AppRoutes.@@CAMEL@@New),
        child: const Icon(Icons.add),
      ),
      body: ContentWidth(
        maxWidth: 900,
        child: items.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              EmptyState(icon: Icons.error_outline, title: l.errorGeneric),
          data: (list) {
            if (list.isEmpty) {
              return EmptyState(
                icon: Icons.inbox_outlined,
                title: l.@@CAMEL@@Empty,
                subtitle: l.@@CAMEL@@EmptyHint,
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: list.length,
              itemBuilder: (context, i) => _@@PASCAL@@Tile(item: list[i]),
            );
          },
        ),
      ),
    );
  }
}

class _@@PASCAL@@Tile extends ConsumerWidget {
  final @@PASCAL@@Item item;
  const _@@PASCAL@@Tile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => showConfirmDialog(
        context,
        title: l.@@CAMEL@@DeleteTitle,
        message: l.deleteConfirm(item.name),
      ),
      onDismissed: (_) {
        ref.read(@@CAMEL@@ControllerProvider.notifier).delete(item.id);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.deleted)));
      },
      child: Card(
        child: ListTile(
          title: Text(item.name),
          subtitle: item.notes.isEmpty ? null : Text(item.notes),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.@@CAMEL@@Edit(item.id)),
        ),
      ),
    );
  }
}
EOF

render > "$DIR/presentation/screens/${NAME}_form_screen.dart" <<'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/l10n_x.dart';
import '../../../../shared/utils/validators.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/content_width.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/@@SNAKE@@_item.dart';
import '../providers/@@SNAKE@@_controller.dart';

/// Sirve para crear (itemId == null) y para editar.
class @@PASCAL@@FormScreen extends ConsumerStatefulWidget {
  final String? itemId;
  const @@PASCAL@@FormScreen({super.key, this.itemId});

  @override
  ConsumerState<@@PASCAL@@FormScreen> createState() =>
      _@@PASCAL@@FormScreenState();
}

class _@@PASCAL@@FormScreenState extends ConsumerState<@@PASCAL@@FormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _notes;
  @@PASCAL@@Item? _existing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final id = widget.itemId;
    if (id != null) {
      final list =
          ref.read(@@CAMEL@@ControllerProvider).value ?? <@@PASCAL@@Item>[];
      _existing = list.where((i) => i.id == id).firstOrNull;
    }
    _name = TextEditingController(text: _existing?.name ?? '');
    _notes = TextEditingController(text: _existing?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final item = @@PASCAL@@Item(
      id: _existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      notes: _notes.text.trim(),
    );

    await ref.read(@@CAMEL@@ControllerProvider.notifier).save(item);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.saved)));
    context.pop();
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final ok = await showConfirmDialog(
      context,
      title: l.@@CAMEL@@DeleteTitle,
      message: l.deleteConfirm(_existing!.name),
    );
    if (!ok) return;
    await ref.read(@@CAMEL@@ControllerProvider.notifier).delete(_existing!.id);
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? l.@@CAMEL@@Add : l.@@CAMEL@@Edit),
        actions: [
          if (_existing != null)
            IconButton(
              tooltip: l.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ContentWidth(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _name,
                  label: l.@@CAMEL@@Name,
                  icon: Icons.label_outline,
                  validator: Validators.required(context),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _notes,
                  label: l.@@CAMEL@@Notes,
                  icon: Icons.notes_outlined,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: l.save,
                  isLoading: _saving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
EOF

# ---------------------------------------------- registro en archivos existentes
SNAKE="$NAME" PASCAL="$PASCAL" CAMEL="$CAMEL" LABEL_ES="$LABEL_ES" LABEL_EN="$LABEL_EN" ICON="$ICON" \
python3 - <<'PYEOF'
import json, os, sys

snake, pascal, camel = os.environ['SNAKE'], os.environ['PASCAL'], os.environ['CAMEL']
label_es, label_en, icon = os.environ['LABEL_ES'], os.environ['LABEL_EN'], os.environ['ICON']
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


# 1) app_modules.dart
mods = 'lib/core/config/app_modules.dart'
insert_after_line(mods, 'static const bool enableReports',
                  f'  static const bool enable{pascal} = true;\n', 'interruptor')
insert_after_line(mods, 'static const bool reports =',
                  f'  static const bool {camel} = enable{pascal};\n', 'valor efectivo')

# 2) app_routes.dart
routes = 'lib/core/router/app_routes.dart'
insert_before_line(routes, "static const settings = '/settings';",
                   f"  static const {camel} = '/{snake}';\n"
                   f"  static const {camel}New = '/{snake}/new';\n"
                   f"  static String {camel}Edit(String id) => '/{snake}/$id';\n\n", 'rutas')

# 3) app_router.dart (imports + rutas)
router = 'lib/core/router/app_router.dart'
imports = (f"import '../../features/{snake}/presentation/screens/{snake}_form_screen.dart';\n"
           f"import '../../features/{snake}/presentation/screens/{snake}_screen.dart';\n")
insert_before_line(router, "import '../config/app_modules.dart';", imports, 'imports del router')
route_block = f"""      if (AppModules.{camel})
        GoRoute(
          path: AppRoutes.{camel},
          builder: (_, _) => const {pascal}Screen(),
          routes: [
            // 'new' va antes que ':id' para que no lo confunda con un id.
            GoRoute(path: 'new', builder: (_, _) => const {pascal}FormScreen()),
            GoRoute(
              path: ':id',
              builder: (_, state) =>
                  {pascal}FormScreen(itemId: state.pathParameters['id']),
            ),
          ],
        ),
"""
insert_before_line(router, '// ---- Núcleo: ajustes ----', route_block, 'rutas del router')

# 4) app_menu.dart
menu = 'lib/shared/widgets/app_menu.dart'
menu_item = (f"      if (AppModules.{camel})\n"
             f"        (AppRoutes.{camel}, Icons.{icon}, l.nav{pascal}),\n")
insert_before_line(menu, '(AppRoutes.settings, Icons.settings_outlined', menu_item, 'menú')

# 5) textos es/en
keys = {
    f'nav{pascal}': (label_es, label_en),
    f'{camel}Add': (f'Agregar', 'Add'),
    f'{camel}Edit': ('Editar', 'Edit'),
    f'{camel}Name': ('Nombre', 'Name'),
    f'{camel}Notes': ('Notas', 'Notes'),
    f'{camel}Empty': ('Sin registros', 'No records'),
    f'{camel}EmptyHint': ('Agrega uno con el botón +', 'Add one with the + button'),
    f'{camel}DeleteTitle': ('¿Eliminar registro?', 'Delete record?'),
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

if manual:
    print('\nOJO: no pude editar automáticamente estas partes. Agrégalas a mano:')
    for label, path, text in manual:
        print(f'\n--- {label} -> {path}\n{text}')
PYEOF

echo
echo "Archivos creados en $DIR:"
find "$DIR" -type f | sort | sed 's/^/  /'

if command -v flutter >/dev/null 2>&1; then
  echo
  echo "Generando traducciones (flutter gen-l10n)..."
  flutter gen-l10n
fi

cat <<EOM

Listo. Siguientes pasos:
  1) Revisa que 'generate: true' siga en pubspec.yaml y corre: flutter analyze
  2) Prueba: menú -> $LABEL_ES  (se apaga/enciende con enable$PASCAL en lib/core/config/app_modules.dart)
  3) Personaliza el modelo en lib/features/$NAME/domain/${NAME}_item.dart
EOM

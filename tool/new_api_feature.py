#!/usr/bin/env python3
"""Genera un feature completo que consume una API a partir de un JSON de ejemplo.

Uso (desde la raiz del proyecto):
  python3 tool/new_api_feature.py <nombre_snake> <endpoint> [opciones]

Ejemplos:
  python3 tool/new_api_feature.py product /products --json product.json
  python3 tool/new_api_feature.py order /orders --json orders.json --label-es "Pedidos" --label-en "Orders"
  python3 tool/new_api_feature.py report /reports --json r.json --readonly
  curl -s https://api.com/products | python3 tool/new_api_feature.py product /products --json -

El JSON puede ser un objeto, una lista de objetos o la respuesta completa de la
API ({"items": [...]}, {"data": [...]}): se toma el primer objeto para inferir
los campos.

Opciones:
  --json RUTA        JSON de ejemplo ('-' = stdin). Sin esto se crea con id + name.
  --label-es TEXTO   Nombre en el menu (es). Por defecto, el nombre del feature.
  --label-en TEXTO   Nombre en el menu (en).
  --icon NOMBRE      Icono de Material (por defecto folder_outlined).
  --readonly         Solo lista + detalle (sin crear, editar ni borrar).
  --no-detail        Editar/ver usa el item de la lista en vez de GET /endpoint/{id}.
  --patch            Editar con PATCH en vez de PUT.
  --id-field LLAVE   Llave del id en el JSON (por defecto se detecta: id, _id, uuid).
  --page-param X     Nombre del parametro de pagina (por defecto ApiConfig.pageParam).
  --limit-param X    Nombre del parametro de tamano (por defecto ApiConfig.limitParam).

Crea lib/features/<nombre>/ y lo registra en app_modules, app_routes, app_router,
app_menu y los .arb (es/en). Es seguro repetirlo: no pisa features existentes.
"""
import argparse
import glob
import json
import os
import re
import shutil
import subprocess
import sys

RESERVED = {
    'abstract', 'as', 'assert', 'async', 'await', 'break', 'case', 'catch', 'class', 'const',
    'continue', 'covariant', 'default', 'deferred', 'do', 'dynamic', 'else', 'enum', 'export',
    'extends', 'extension', 'external', 'factory', 'false', 'final', 'finally', 'for', 'function',
    'get', 'hide', 'if', 'implements', 'import', 'in', 'interface', 'is', 'late', 'library',
    'mixin', 'new', 'null', 'on', 'operator', 'part', 'required', 'rethrow', 'return', 'set',
    'show', 'static', 'super', 'switch', 'sync', 'this', 'throw', 'true', 'try', 'typedef',
    'var', 'void', 'while', 'with', 'yield',
    # nombres que usa el modelo generado
    'hashCode', 'runtimeType', 'isNew', 'newId', 'toJson', 'fromJson', 'toString', 'noSuchMethod',
}
ID_CANDIDATES = ['id', '_id', 'uuid', 'ID', 'Id', 'Uuid', 'UUID']
TITLE_PREFS = ['name', 'title', 'nombre', 'titulo', 'label', 'full_name', 'fullname',
               'username', 'email', 'description', 'descripcion']
SUB_PREFS = ['description', 'descripcion', 'body', 'email', 'subtitle', 'status', 'estado',
             'type', 'tipo', 'category', 'categoria']
ITEM_KEYS = ['data', 'items', 'results', 'content', 'rows', 'records']
DATE_RE = re.compile(r'^\d{4}-\d{2}-\d{2}([T ]\d{2}:\d{2}(:\d{2}(\.\d+)?)?(Z|[+-]\d{2}:?\d{2})?)?$')


def die(msg):
    sys.exit('ERROR: ' + msg)


# ------------------------------------------------------------------ nombres
def camel(s):
    s = re.sub(r'[^0-9a-zA-Z_]+', '_', str(s)).strip('_')
    parts = [p for p in s.split('_') if p]
    if not parts:
        return 'field'
    name = parts[0][0].lower() + parts[0][1:] + ''.join(p[:1].upper() + p[1:] for p in parts[1:])
    if name[0].isdigit():
        name = 'f' + name[0].upper() + name[1:]
    if name in RESERVED:
        name += 'Value'
    return name


def pascal(s):
    return ''.join(p[:1].upper() + p[1:] for p in s.split('_') if p)


def humanize(key):
    s = re.sub(r'(?<=[a-z0-9])(?=[A-Z])', ' ', str(key))
    s = re.sub(r'[_\-\s]+', ' ', s).strip()
    return s[:1].upper() + s[1:].lower() if s else key


def q(s):
    """Escapa texto para un literal Dart con comillas simples."""
    return str(s).replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')


# ------------------------------------------------------------------ muestra
def pick_object(data):
    """Encuentra el primer objeto dentro de lo que se pegó (objeto, lista o respuesta paginada)."""
    if isinstance(data, list):
        for e in data:
            if isinstance(e, dict):
                return e
        return {}
    if isinstance(data, dict):
        for k in ITEM_KEYS:
            v = data.get(k)
            if isinstance(v, list):
                for e in v:
                    if isinstance(e, dict):
                        return e
            if isinstance(v, dict) and len(data) <= 3:  # {"data": {...}} = un solo objeto
                return v
        return data
    return {}


class Field:
    def __init__(self, json_key, value, dart, is_id=False):
        self.json_key = json_key
        self.dart = dart
        self.is_id = is_id
        if isinstance(value, bool):
            self.kind = 'bool'
        elif isinstance(value, int):
            self.kind = 'int'
        elif isinstance(value, float):
            self.kind = 'double'
        elif isinstance(value, str):
            self.kind = 'DateTime' if DATE_RE.match(value) else 'String'
        elif isinstance(value, list):
            self.kind = 'List'
        elif isinstance(value, dict):
            self.kind = 'Map'
        else:  # null: no se sabe el tipo -> texto opcional
            self.kind = 'String'
        # Los null del ejemplo y las fechas (pueden no parsear) son opcionales.
        self.nullable = (value is None) or self.kind == 'DateTime'
        self.label = humanize(json_key)

    @property
    def dart_type(self):
        base = {'List': 'List<dynamic>', 'Map': 'Map<String, dynamic>'}.get(self.kind, self.kind)
        return base + ('?' if self.nullable else '')

    @property
    def pascal(self):
        return self.dart[:1].upper() + self.dart[1:]

    def parse_expr(self):
        k = f"json['{q(self.json_key)}']"
        if self.kind == 'String':
            return f'asString({k})' + ('' if self.nullable else " ?? ''")
        if self.kind == 'int':
            return f'asInt({k})' + ('' if self.nullable else ' ?? 0')
        if self.kind == 'double':
            return f'asDouble({k})' + ('' if self.nullable else ' ?? 0.0')
        if self.kind == 'bool':
            return f'asBool({k})' + ('' if self.nullable else ' ?? false')
        if self.kind == 'DateTime':
            return f'asDate({k})'
        if self.kind == 'List':
            return f'asList({k})'
        return f'asMap({k})'

    def json_expr(self):
        if self.kind == 'DateTime':
            return f'{self.dart}?.toIso8601String()'
        return self.dart


def build_fields(sample, id_field):
    keys = list(sample.keys())
    if not keys:
        sample = {'id': 1, 'name': 'Ejemplo'}
        keys = list(sample.keys())

    if id_field:
        if id_field not in sample:
            die(f"--id-field '{id_field}' no existe en el JSON. Llaves: {', '.join(keys)}")
        idk = id_field
    else:
        idk = next((c for c in ID_CANDIDATES if c in sample), None)
        if idk is None:
            die("No encontre el campo id (busque: id, _id, uuid). Indica la llave con --id-field. "
                f"Llaves del JSON: {', '.join(keys)}")

    used = {'id'}
    fields = []
    id_value = sample[idk]
    idf = Field(idk, id_value if id_value is not None else 0, 'id', is_id=True)
    idf.nullable = False
    if idf.kind != 'int':
        idf.kind = 'String'  # uuid, texto, etc.
    fields.append(idf)

    for k in keys:
        if k == idk:
            continue
        name = camel(k)
        base, n = name, 2
        while name in used:
            name = f'{base}{n}'
            n += 1
        used.add(name)
        fields.append(Field(k, sample[k], name))
    return fields


def choose_title_sub(fields):
    body = [f for f in fields if not f.is_id]
    strings = [f for f in body if f.kind == 'String']

    def by_prefs(prefs, pool, exclude=None):
        for p in prefs:
            for f in pool:
                if f is not exclude and f.json_key.lower() == p:
                    return f
        return None

    title = by_prefs(TITLE_PREFS, strings) or (strings[0] if strings else (body[0] if body else fields[0]))
    sub = by_prefs(SUB_PREFS, strings, title)
    if sub is None:
        sub = next((f for f in strings if f is not title), None)
    return title, sub


def disp(f, var):
    """Expresion Dart (tipo String) para mostrar el valor de un campo."""
    if f.kind == 'String' and not f.nullable:
        return f'{var}.{f.dart}'
    if f.nullable:
        return "'${" + f'{var}.{f.dart}' + " ?? ''}'"
    return "'${" + f'{var}.{f.dart}' + "}'"


# ------------------------------------------------------------------ plantillas
def render(tpl, **kw):
    for k, v in kw.items():
        tpl = tpl.replace(f'@@{k}@@', v)
    return tpl


def entity_code(P, fields):
    idf = fields[0]
    id_type = idf.kind  # int | String
    new_id = '0' if id_type == 'int' else "''"
    body = fields[1:]

    ctor = ['    required this.id,']
    for f in body:
        ctor.append(f'    this.{f.dart},' if f.nullable else f'    required this.{f.dart},')

    decls = [f'  final {id_type} id;'] + [f'  final {f.dart_type} {f.dart};' for f in body]

    id_parse = (f"asInt(json['{q(idf.json_key)}']) ?? newId" if id_type == 'int'
                else f"asString(json['{q(idf.json_key)}']) ?? newId")
    from_args = [f'        id: {id_parse},'] + [f'        {f.dart}: {f.parse_expr()},' for f in body]
    to_entries = [f"        if (!isNew) '{q(idf.json_key)}': id,"] + \
                 [f"        '{q(f.json_key)}': {f.json_expr()}," for f in body]

    return render(
        """import '../../../core/network/json_utils.dart';

/// Modelo generado con tool/new_api_feature.py a partir de un JSON de ejemplo.
/// Ajusta tipos y nombres aquí si la API real difiere.
class @@P@@Item {
  const @@P@@Item({
@@CTOR@@
  });

  /// Id de un registro que todavía no existe en el servidor (al crear).
  static const @@IDTYPE@@ newId = @@NEWID@@;

@@DECLS@@

  bool get isNew => id == newId;

  factory @@P@@Item.fromJson(Map<String, dynamic> json) => @@P@@Item(
@@FROM@@
      );

  /// Al crear (POST) no se manda el id.
  Map<String, dynamic> toJson() => {
@@TO@@
      };
}
""",
        P=P, IDTYPE=id_type, NEWID=new_id, CTOR='\n'.join(ctor), DECLS='\n'.join(decls),
        FROM='\n'.join(from_args), TO='\n'.join(to_entries))


RESOURCE_TPL = """import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/remote_resource.dart';
import '../../../core/providers/api_providers.dart';
import '../domain/@@SNAKE@@_item.dart';

/// Endpoint: @@ENDPOINT@@
/// Ajusta aquí el path o los nombres de paginación si esta API es distinta.
final @@CAMEL@@ResourceProvider = Provider<RemoteResource<@@P@@Item>>((ref) {
  return RemoteResource<@@P@@Item>(
    client: ref.watch(apiClientProvider),
    path: '@@ENDPOINT_Q@@',
    fromJson: @@P@@Item.fromJson,
    toJson: (item) => item.toJson(),
@@EXTRA@@
  );
});
"""

CONTROLLER_TPL = """import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/remote_resource.dart';
import '../../../../core/pagination/paginated_controller.dart';
import '../../data/@@SNAKE@@_resource.dart';
import '../../domain/@@SNAKE@@_item.dart';

class @@P@@ListController extends PaginatedController<@@P@@Item> {
  RemoteResource<@@P@@Item> get _resource =>
      ref.read(@@CAMEL@@ResourceProvider);

  @override
  Future<PagedResult<@@P@@Item>> fetchPage(int page) =>
      _resource.list(page: page);
@@MUTATIONS@@}

final @@CAMEL@@ListControllerProvider =
    NotifierProvider<@@P@@ListController, PaginatedState<@@P@@Item>>(
        @@P@@ListController.new);
@@DETAIL@@"""

MUTATIONS = """
  /// Crea o actualiza y recarga la lista.
  Future<void> save(@@P@@Item item) async {
    if (item.isNew) {
      await _resource.create(item);
    } else {
      await _resource.update(item.id.toString(), item);
    }
    await refresh();
  }

  /// Quita el registro de la lista al instante y lo borra en el servidor.
  /// Si el servidor falla, lo regresa a la lista y relanza el error.
  Future<void> remove(String id) async {
    final previous = state.items;
    state = state.copyWith(
      items: previous.where((i) => i.id.toString() != id).toList(),
    );
    try {
      await _resource.delete(id);
    } catch (_) {
      state = state.copyWith(items: previous);
      rethrow;
    }
  }
"""

DETAIL_PROVIDER = """
/// Trae un registro por id (GET @@ENDPOINT@@/{id}).
final @@CAMEL@@DetailProvider =
    FutureProvider.autoDispose.family<@@P@@Item, String>(
  (ref, id) => ref.watch(@@CAMEL@@ResourceProvider).getById(id),
);
"""

LIST_SCREEN_EDITABLE = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_x.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../l10n/l10n_x.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/content_width.dart';
import '../../../../shared/widgets/paginated_list_view.dart';
import '../../domain/@@SNAKE@@_item.dart';
import '../providers/@@SNAKE@@_controller.dart';

class @@P@@Screen extends ConsumerWidget {
  const @@P@@Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final state = ref.watch(@@CAMEL@@ListControllerProvider);
    final controller = ref.read(@@CAMEL@@ListControllerProvider.notifier);

    return AppScaffold(
      title: l.nav@@P@@,
      currentRoute: AppRoutes.@@CAMEL@@,
      floatingActionButton: FloatingActionButton(
        tooltip: l.@@CAMEL@@Add,
        onPressed: () => context.push(AppRoutes.@@CAMEL@@New),
        child: const Icon(Icons.add),
      ),
      body: ContentWidth(
        maxWidth: 900,
        child: PaginatedListView<@@P@@Item>(
          state: state,
          onRefresh: controller.refresh,
          onLoadMore: controller.loadMore,
          itemBuilder: (context, item) => _@@P@@Tile(item: item),
        ),
      ),
    );
  }
}

class _@@P@@Tile extends ConsumerWidget {
  final @@P@@Item item;
  const _@@P@@Tile({required this.item});

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
        message: l.deleteConfirm(@@TITLE@@),
      ),
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          await ref
              .read(@@CAMEL@@ListControllerProvider.notifier)
              .remove(item.id.toString());
          messenger.showSnackBar(SnackBar(content: Text(l.deleted)));
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(content: Text(Failure.from(e).localized(l))),
          );
        }
      },
      child: Card(
        child: ListTile(
          title: Text(@@TITLE@@),
@@SUBTITLE@@          trailing: const Icon(Icons.chevron_right),
          onTap: () =>
              context.push(AppRoutes.@@CAMEL@@Edit(item.id.toString())),
        ),
      ),
    );
  }
}
"""

LIST_SCREEN_READONLY = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../l10n/l10n_x.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/content_width.dart';
import '../../../../shared/widgets/paginated_list_view.dart';
import '../../domain/@@SNAKE@@_item.dart';
import '../providers/@@SNAKE@@_controller.dart';

class @@P@@Screen extends ConsumerWidget {
  const @@P@@Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final state = ref.watch(@@CAMEL@@ListControllerProvider);
    final controller = ref.read(@@CAMEL@@ListControllerProvider.notifier);

    return AppScaffold(
      title: l.nav@@P@@,
      currentRoute: AppRoutes.@@CAMEL@@,
      body: ContentWidth(
        maxWidth: 900,
        child: PaginatedListView<@@P@@Item>(
          state: state,
          onRefresh: controller.refresh,
          onLoadMore: controller.loadMore,
          itemBuilder: (context, item) => Card(
            child: ListTile(
              title: Text(@@TITLE@@),
@@SUBTITLE@@              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  context.push(AppRoutes.@@CAMEL@@Edit(item.id.toString())),
            ),
          ),
        ),
      ),
    );
  }
}
"""

FORM_SCREEN = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_x.dart';
import '../../../../core/errors/failures.dart';
import '../../../../l10n/l10n_x.dart';
@@EXTRA_IMPORTS@@import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/content_width.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/@@SNAKE@@_item.dart';
import '../providers/@@SNAKE@@_controller.dart';

/// Crear (itemId == null) o editar un registro.
class @@P@@FormScreen extends ConsumerWidget {
  final String? itemId;
  const @@P@@FormScreen({super.key, this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final id = itemId;

    Widget body;
    if (id == null) {
      body = const _@@P@@Form();
    } else {
@@LOAD@@
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(id == null ? l.@@CAMEL@@Add : l.@@CAMEL@@Edit),
      ),
      body: body,
    );
  }
}

class _@@P@@Form extends ConsumerStatefulWidget {
  final @@P@@Item? item;
  const _@@P@@Form({this.item});

  @override
  ConsumerState<_@@P@@Form> createState() => _@@P@@FormState();
}

class _@@P@@FormState extends ConsumerState<_@@P@@Form> {
  final _formKey = GlobalKey<FormState>();
@@DECLS@@
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
@@INITS@@
  }

  @override
  void dispose() {
@@DISPOSES@@
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final existing = widget.item;
    setState(() => _saving = true);

    final item = @@P@@Item(
      id: existing?.id ?? @@P@@Item.newId,
@@BUILD@@
    );

    try {
      await ref.read(@@CAMEL@@ListControllerProvider.notifier).save(item);
      messenger.showSnackBar(SnackBar(content: Text(l.saved)));
      if (mounted) router.pop();
    } catch (e) {
      final f = Failure.from(e);
      final extra =
          f.fieldErrors.isEmpty ? '' : ': ${f.fieldErrors.values.first}';
      messenger.showSnackBar(
        SnackBar(content: Text('${f.localized(l)}$extra')),
      );
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final item = widget.item!;

    final ok = await showConfirmDialog(
      context,
      title: l.@@CAMEL@@DeleteTitle,
      message: l.deleteConfirm(@@TITLE@@),
    );
    if (!ok) return;

    try {
      await ref
          .read(@@CAMEL@@ListControllerProvider.notifier)
          .remove(item.id.toString());
      messenger.showSnackBar(SnackBar(content: Text(l.deleted)));
      if (mounted) router.pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(Failure.from(e).localized(l))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return ContentWidth(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
@@FIELDS@@
              const SizedBox(height: 8),
              PrimaryButton(
                label: l.save,
                isLoading: _saving,
                onPressed: _submit,
              ),
              if (widget.item != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _saving ? null : _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l.delete),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
"""

DETAIL_SCREEN = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/l10n_x.dart';
@@EXTRA_IMPORTS@@import '../../../../shared/widgets/content_width.dart';
import '../../domain/@@SNAKE@@_item.dart';
import '../providers/@@SNAKE@@_controller.dart';

/// Detalle de solo lectura de un registro.
class @@P@@DetailScreen extends ConsumerWidget {
  final String itemId;
  const @@P@@DetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l.nav@@P@@)),
      body: @@LOAD@@,
    );
  }

  Widget _content(BuildContext context, @@P@@Item item) {
    final l = context.l10n;
    return ContentWidth(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
@@ROWS@@
        ],
      ),
    );
  }
}
"""


# ------------------------------------------------------------------ main
def main():
    ap = argparse.ArgumentParser(description='Genera un feature que consume una API desde un JSON de ejemplo.')
    ap.add_argument('name')
    ap.add_argument('endpoint')
    ap.add_argument('--json', dest='json_path')
    ap.add_argument('--label-es')
    ap.add_argument('--label-en')
    ap.add_argument('--icon', default='folder_outlined')
    ap.add_argument('--readonly', action='store_true')
    ap.add_argument('--no-detail', action='store_true')
    ap.add_argument('--patch', action='store_true')
    ap.add_argument('--id-field')
    ap.add_argument('--page-param')
    ap.add_argument('--limit-param')
    a = ap.parse_args()

    name = a.name
    if not re.match(r'^[a-z][a-z0-9_]*$', name):
        die('El nombre debe ir en minusculas y snake_case (ej. work_order)')
    if not os.path.exists('lib/core/config/app_modules.dart') or not os.path.exists('lib/core/network/remote_resource.dart'):
        die('Ejecuta el script desde la raiz del proyecto, con la plantilla y la capa de API '
            '(lib/core/network/remote_resource.dart).')

    P = pascal(name)
    C = P[:1].lower() + P[1:]
    feature_dir = f'lib/features/{name}'
    if os.path.exists(feature_dir):
        die(f'Ya existe {feature_dir} (no se pisa nada)')
    if f"static const {C} = " in open('lib/core/router/app_routes.dart', encoding='utf-8').read():
        die(f"Ya existe una ruta llamada '{C}' en app_routes.dart")
    if re.search(rf'\benable{P}\b', open('lib/core/config/app_modules.dart', encoding='utf-8').read()):
        die(f'Ya existe el modulo enable{P} en app_modules.dart')

    label_es = a.label_es or humanize(name)
    label_en = a.label_en or label_es
    endpoint = a.endpoint
    if not endpoint.startswith('/') and not endpoint.startswith('http'):
        endpoint = '/' + endpoint
    editable = not a.readonly
    use_detail = not a.no_detail

    # ---- muestra
    if a.json_path:
        raw = sys.stdin.read() if a.json_path == '-' else open(a.json_path, encoding='utf-8').read()
        try:
            data = json.loads(raw)
        except json.JSONDecodeError as e:
            die(f'El JSON de ejemplo no es valido: {e}')
        sample = pick_object(data)
        if not sample:
            die('No encontre ningun objeto dentro del JSON de ejemplo.')
    else:
        sample = {'id': 1, 'name': 'Ejemplo'}
        print('Sin --json: se crea con los campos id y name (editalos en el modelo).')

    fields = build_fields(sample, a.id_field)
    body = [f for f in fields if not f.is_id]
    title_f, sub_f = choose_title_sub(fields)

    # ---- archivos
    files = {}

    files[f'domain/{name}_item.dart'] = entity_code(P, fields)

    extra = []
    if a.page_param:
        extra.append(f"    pageParam: '{q(a.page_param)}',")
    if a.limit_param:
        extra.append(f"    limitParam: '{q(a.limit_param)}',")
    if a.patch and editable:
        extra.append('    usePatch: true,')
    files[f'data/{name}_resource.dart'] = render(
        RESOURCE_TPL, SNAKE=name, CAMEL=C, P=P, ENDPOINT=endpoint, ENDPOINT_Q=q(endpoint),
        EXTRA='\n'.join(extra)).replace('\n\n  );', '\n  );')

    files[f'presentation/providers/{name}_controller.dart'] = render(
        CONTROLLER_TPL, SNAKE=name, CAMEL=C, P=P,
        MUTATIONS=render(MUTATIONS, P=P) if editable else '',
        DETAIL=render(DETAIL_PROVIDER, CAMEL=C, P=P, ENDPOINT=endpoint) if use_detail else '')

    title_expr = disp(title_f, 'item')
    sub_line = ''
    if sub_f is not None:
        indent = '          ' if editable else '              '
        sub_line = f'{indent}subtitle: Text({disp(sub_f, "item")}, maxLines: 2, overflow: TextOverflow.ellipsis),\n'

    files[f'presentation/screens/{name}_screen.dart'] = render(
        LIST_SCREEN_EDITABLE if editable else LIST_SCREEN_READONLY,
        SNAKE=name, CAMEL=C, P=P, TITLE=title_expr, SUBTITLE=sub_line)

    def load_block(widget_kind):
        # widget_kind: 'form' (usa id/body) | 'detail'
        if widget_kind == 'form':
            if use_detail:
                return (f"      final detail = ref.watch({C}DetailProvider(id));\n"
                        f"      body = AsyncValueView<{P}Item>(\n"
                        f"        value: detail,\n"
                        f"        onRetry: () => ref.invalidate({C}DetailProvider(id)),\n"
                        f"        data: (item) => _{P}Form(item: item),\n"
                        f"      );")
            return (f"      final items = ref.watch({C}ListControllerProvider).items;\n"
                    f"      final item = items.where((i) => i.id.toString() == id).firstOrNull;\n"
                    f"      body = item == null ? const ErrorView() : _{P}Form(item: item);")
        if use_detail:
            return (f"AsyncValueView<{P}Item>(\n"
                    f"        value: ref.watch({C}DetailProvider(itemId)),\n"
                    f"        onRetry: () => ref.invalidate({C}DetailProvider(itemId)),\n"
                    f"        data: (item) => _content(context, item),\n"
                    f"      )")
        return (f"Builder(\n"
                f"        builder: (context) {{\n"
                f"          final items = ref.watch({C}ListControllerProvider).items;\n"
                f"          final item = items.where((i) => i.id.toString() == itemId).firstOrNull;\n"
                f"          return item == null ? const ErrorView() : _content(context, item);\n"
                f"        }},\n"
                f"      )")

    if editable:
        form_fields = [f for f in body if f.kind in ('String', 'int', 'double', 'bool')]
        decls, inits, disposes, build_args, widgets = [], [], [], [], []
        uses_validators = False
        for f in body:
            n = f.dart
            if f.kind in ('String', 'int', 'double'):
                decls.append(f'  late final TextEditingController _{n};')
                disposes.append(f'    _{n}.dispose();')
                if f.kind == 'String':
                    inits.append(f"    _{n} = TextEditingController(text: item?.{n} ?? '');")
                else:
                    inits.append(f"    _{n} = TextEditingController(text: item?.{n}?.toString() ?? '');")
            elif f.kind == 'bool':
                decls.append(f'  late bool _{n};')
                inits.append(f'    _{n} = item?.{n} ?? false;')

            if f.kind == 'String':
                build_args.append(f"      {n}: _{n}.text.trim()," if not f.nullable else
                                  f"      {n}: _{n}.text.trim().isEmpty ? null : _{n}.text.trim(),")
            elif f.kind == 'int':
                build_args.append(f"      {n}: int.tryParse(_{n}.text.trim())" + ('' if f.nullable else ' ?? 0') + ',')
            elif f.kind == 'double':
                build_args.append(f"      {n}: double.tryParse(_{n}.text.trim().replaceAll(',', '.'))" + ('' if f.nullable else ' ?? 0.0') + ',')
            elif f.kind == 'bool':
                build_args.append(f'      {n}: _{n},')
            elif f.kind == 'DateTime':
                build_args.append(f'      {n}: existing?.{n},')
            elif f.kind == 'List':
                build_args.append(f'      {n}: existing?.{n} ?? const <dynamic>[],')
            else:
                build_args.append(f'      {n}: existing?.{n} ?? const <String, dynamic>{{}},')

        for f in form_fields:
            n = f.dart
            if f.kind == 'bool':
                widgets.append(f"              SwitchListTile(\n"
                               f"                contentPadding: EdgeInsets.zero,\n"
                               f"                title: Text(l.{C}Field{f.pascal}),\n"
                               f"                value: _{n},\n"
                               f"                onChanged: (v) => setState(() => _{n} = v),\n"
                               f"              ),\n"
                               f"              const SizedBox(height: 8),")
            else:
                extra_args = ''
                if f.kind == 'int':
                    extra_args += '                keyboardType: TextInputType.number,\n'
                elif f.kind == 'double':
                    extra_args += '                keyboardType: const TextInputType.numberWithOptions(decimal: true),\n'
                if f.kind == 'String' and not f.nullable and f is title_f:
                    extra_args += '                validator: Validators.required(context),\n'
                    uses_validators = True
                elif f.kind == 'int' and not f.nullable:
                    extra_args += '                validator: Validators.integer(context),\n'
                    uses_validators = True
                elif f.kind == 'double' and not f.nullable:
                    extra_args += '                validator: Validators.number(context),\n'
                    uses_validators = True
                widgets.append(f"              AppTextField(\n"
                               f"                controller: _{n},\n"
                               f"                label: l.{C}Field{f.pascal},\n"
                               f"{extra_args}"
                               f"              ),\n"
                               f"              const SizedBox(height: 16),")

        imports = ''
        if uses_validators:
            imports += "import '../../../../shared/utils/validators.dart';\n"
        imports += ("import '../../../../shared/widgets/async_value_view.dart';\n" if use_detail
                    else "import '../../../../shared/widgets/error_view.dart';\n")

        title_for_delete = disp(title_f, 'item')
        files[f'presentation/screens/{name}_form_screen.dart'] = render(
            FORM_SCREEN, SNAKE=name, CAMEL=C, P=P, EXTRA_IMPORTS=imports,
            LOAD=load_block('form'), DECLS='\n'.join(decls), INITS='\n'.join(inits) or '    // (sin campos editables)',
            DISPOSES='\n'.join(disposes) or '    // (nada que liberar)', BUILD='\n'.join(build_args),
            TITLE=title_for_delete, FIELDS='\n'.join(widgets) or '              // (sin campos editables)')
    else:
        rows = []
        for f in body:
            rows.append(f"          ListTile(\n"
                        f"            title: Text(l.{C}Field{f.pascal}),\n"
                        f"            subtitle: Text({disp(f, 'item')}),\n"
                        f"          ),")
        imports = ("import '../../../../shared/widgets/async_value_view.dart';\n" if use_detail
                   else "import '../../../../shared/widgets/error_view.dart';\n")
        files[f'presentation/screens/{name}_detail_screen.dart'] = render(
            DETAIL_SCREEN, SNAKE=name, CAMEL=C, P=P, EXTRA_IMPORTS=imports,
            LOAD=load_block('detail'), ROWS='\n'.join(rows))

    # ---- escribir
    for rel, content in files.items():
        path = os.path.join(feature_dir, rel)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, 'w', encoding='utf-8') as fh:
            fh.write(content)

    # ---- registro
    manual = []

    def read(p):
        with open(p, encoding='utf-8') as fh:
            return fh.read()

    def write(p, s):
        with open(p, 'w', encoding='utf-8') as fh:
            fh.write(s)

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

    mods = 'lib/core/config/app_modules.dart'
    insert_after_line(mods, 'static const bool enableReports', f'  static const bool enable{P} = true;\n', 'interruptor')
    insert_after_line(mods, 'static const bool reports =', f'  static const bool {C} = enable{P};\n', 'valor efectivo')

    routes_txt = f"  static const {C} = '/{name}';\n"
    if editable:
        routes_txt += f"  static const {C}New = '/{name}/new';\n"
    routes_txt += f"  static String {C}Edit(String id) => '/{name}/$id';\n\n"
    insert_before_line('lib/core/router/app_routes.dart', "static const settings = '/settings';", routes_txt, 'rutas')

    router = 'lib/core/router/app_router.dart'
    second = f'{name}_form_screen.dart' if editable else f'{name}_detail_screen.dart'
    imports_txt = (f"import '../../features/{name}/presentation/screens/{second}';\n"
                   f"import '../../features/{name}/presentation/screens/{name}_screen.dart';\n")
    insert_before_line(router, "import '../config/app_modules.dart';", imports_txt, 'imports del router')

    if editable:
        route = (f"      if (AppModules.{C})\n"
                 f"        GoRoute(\n"
                 f"          path: AppRoutes.{C},\n"
                 f"          builder: (_, _) => const {P}Screen(),\n"
                 f"          routes: [\n"
                 f"            // 'new' va antes que ':id' para que no lo confunda con un id.\n"
                 f"            GoRoute(path: 'new', builder: (_, _) => const {P}FormScreen()),\n"
                 f"            GoRoute(\n"
                 f"              path: ':id',\n"
                 f"              builder: (_, state) =>\n"
                 f"                  {P}FormScreen(itemId: state.pathParameters['id']),\n"
                 f"            ),\n"
                 f"          ],\n"
                 f"        ),\n")
    else:
        route = (f"      if (AppModules.{C})\n"
                 f"        GoRoute(\n"
                 f"          path: AppRoutes.{C},\n"
                 f"          builder: (_, _) => const {P}Screen(),\n"
                 f"          routes: [\n"
                 f"            GoRoute(\n"
                 f"              path: ':id',\n"
                 f"              builder: (_, state) =>\n"
                 f"                  {P}DetailScreen(itemId: state.pathParameters['id']!),\n"
                 f"            ),\n"
                 f"          ],\n"
                 f"        ),\n")
    insert_before_line(router, '// ---- Núcleo: ajustes ----', route, 'rutas del router')

    insert_before_line('lib/shared/widgets/app_menu.dart', '(AppRoutes.settings, Icons.settings_outlined',
                       f"      if (AppModules.{C})\n"
                       f"        (AppRoutes.{C}, Icons.{a.icon}, l.nav{P}),\n", 'menu')

    keys = {f'nav{P}': (label_es, label_en),
            f'{C}Add': ('Agregar', 'Add'),
            f'{C}Edit': ('Editar', 'Edit'),
            f'{C}DeleteTitle': ('¿Eliminar registro?', 'Delete record?')}
    if not editable:
        keys.pop(f'{C}Add'); keys.pop(f'{C}DeleteTitle')
    for f in body:
        keys[f'{C}Field{f.pascal}'] = (f.label, f.label)

    for loc, i in (('es', 0), ('en', 1)):
        p = f'lib/l10n/app_{loc}.arb'
        if not os.path.exists(p):
            manual.append(('textos', p, json.dumps({k: v[i] for k, v in keys.items()}, ensure_ascii=False, indent=2)))
            continue
        d = json.loads(read(p))
        for k, v in keys.items():
            d.setdefault(k, v[i])
        write(p, json.dumps(d, ensure_ascii=False, indent=2) + '\n')

    # ---- resumen
    print(f"\nFeature '{name}' ({P}Item) -> {endpoint}")
    print('Campos detectados:')
    for f in fields:
        tags = []
        if f.is_id:
            tags.append('id')
        if f is title_f:
            tags.append('titulo')
        if f is sub_f:
            tags.append('subtitulo')
        print(f"  {f.json_key:<24} -> {f.dart:<20} {f.dart_type:<22} {' '.join('[' + t + ']' for t in tags)}")
    print(f"\nModo: {'solo lectura (lista + detalle)' if not editable else 'CRUD (lista, crear, editar, borrar)'}"
          f"{' | detalle: GET ' + endpoint + '/{id}' if use_detail else ' | sin GET por id (usa la lista)'}")
    print('Archivos:')
    for rel in sorted(files):
        print(f'  {feature_dir}/{rel}')

    if manual:
        print('\nOJO: no pude editar automaticamente estas partes. Agregalas a mano:')
        for label, path, text in manual:
            print(f'\n--- {label} -> {path}\n{text}')

    if shutil.which('flutter'):
        print('\nGenerando traducciones (flutter gen-l10n)...')
        subprocess.run(['flutter', 'gen-l10n'], check=False)
    else:
        print('\nNo encontre flutter en el PATH: corre `flutter gen-l10n` a mano.')

    print(f"\nSiguientes pasos:\n  1) flutter analyze\n  2) Revisa tipos y nombres en lib/features/{name}/domain/{name}_item.dart"
          f"\n  3) Ajusta los textos de los campos en lib/l10n/app_es.arb y app_en.arb (llaves {C}Field...)"
          f"\n  4) Se apaga/enciende con enable{P} en lib/core/config/app_modules.dart")


if __name__ == '__main__':
    main()

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../l10n/l10n_x.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/content_width.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/inventario_item.dart';
import '../providers/inventario_controller.dart';

class InventarioScreen extends ConsumerWidget {
  const InventarioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final items = ref.watch(inventarioControllerProvider);

    return AppScaffold(
      title: l.navInventario,
      currentRoute: AppRoutes.inventario,
      floatingActionButton: FloatingActionButton(
        tooltip: l.inventarioAdd,
        onPressed: () => context.push(AppRoutes.inventarioNew),
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
                title: l.inventarioEmpty,
                subtitle: l.inventarioEmptyHint,
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: list.length,
              itemBuilder: (context, i) => _InventarioTile(item: list[i]),
            );
          },
        ),
      ),
    );
  }
}

class _InventarioTile extends ConsumerWidget {
  final InventarioItem item;
  const _InventarioTile({required this.item});

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
        title: l.inventarioDeleteTitle,
        message: l.deleteConfirm(item.name),
      ),
      onDismissed: (_) {
        ref.read(inventarioControllerProvider.notifier).delete(item.id);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.deleted)));
      },
      child: Card(
        child: ListTile(
          title: Text(item.name),
          subtitle: item.notes.isEmpty ? null : Text(item.notes),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.inventarioEdit(item.id)),
        ),
      ),
    );
  }
}

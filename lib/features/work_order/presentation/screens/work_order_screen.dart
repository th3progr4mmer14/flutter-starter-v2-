import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../l10n/l10n_x.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/content_width.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/work_order_item.dart';
import '../providers/work_order_controller.dart';

class WorkOrderScreen extends ConsumerWidget {
  const WorkOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final items = ref.watch(workOrderControllerProvider);

    return AppScaffold(
      title: l.navWorkOrder,
      currentRoute: AppRoutes.workOrder,
      floatingActionButton: FloatingActionButton(
        tooltip: l.workOrderAdd,
        onPressed: () => context.push(AppRoutes.workOrderNew),
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
                title: l.workOrderEmpty,
                subtitle: l.workOrderEmptyHint,
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: list.length,
              itemBuilder: (context, i) => _WorkOrderTile(item: list[i]),
            );
          },
        ),
      ),
    );
  }
}

class _WorkOrderTile extends ConsumerWidget {
  final WorkOrderItem item;
  const _WorkOrderTile({required this.item});

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
        title: l.workOrderDeleteTitle,
        message: l.deleteConfirm(item.name),
      ),
      onDismissed: (_) {
        ref.read(workOrderControllerProvider.notifier).delete(item.id);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.deleted)));
      },
      child: Card(
        child: ListTile(
          title: Text(item.name),
          subtitle: item.notes.isEmpty ? null : Text(item.notes),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.workOrderEdit(item.id)),
        ),
      ),
    );
  }
}

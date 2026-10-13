import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../l10n/l10n_x.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/content_width.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../devices/domain/device.dart';
import '../../../devices/presentation/providers/devices_controller.dart';
import '../providers/geofences_controller.dart';
import '../widgets/geofence_x.dart';

class GeofencesScreen extends ConsumerWidget {
  const GeofencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final geofences = ref.watch(geofencesControllerProvider);
    final devices = ref.watch(devicesControllerProvider).value ?? <Device>[];

    String deviceLabel(String? id) {
      if (id == null) return l.allDevices;
      return devices.where((d) => d.id == id).firstOrNull?.name ?? l.allDevices;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.geofences)),
      floatingActionButton: FloatingActionButton(
        tooltip: l.addGeofence,
        onPressed: () => context.push(AppRoutes.geofenceNew),
        child: const Icon(Icons.add),
      ),
      body: ContentWidth(
        maxWidth: 900,
        child: geofences.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              EmptyState(icon: Icons.error_outline, title: l.errorGeneric),
          data: (list) {
            if (list.isEmpty) {
              return EmptyState(
                icon: Icons.adjust,
                title: l.noGeofences,
                subtitle: l.noGeofencesHint,
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final g = list[i];
                return Dismissible(
                  key: ValueKey(g.id),
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
                    title: l.geofenceDeleteTitle,
                    message: l.deleteConfirm(g.name),
                  ),
                  onDismissed: (_) {
                    ref.read(geofencesControllerProvider.notifier).delete(g.id);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(l.deleted)));
                  },
                  child: Card(
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.adjust)),
                      title: Text(g.name),
                      subtitle: Text(
                          '${g.radiusMeters.round()} m · ${g.trigger.label(l)} · ${deviceLabel(g.deviceId)}'),
                      onTap: () => context.push(AppRoutes.geofenceEdit(g.id)),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

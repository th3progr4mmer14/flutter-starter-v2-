import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../l10n/l10n_x.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/content_width.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/device.dart';
import '../providers/devices_controller.dart';
import '../widgets/device_x.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  String _query = '';
  DeviceStatus? _status; // null = todos

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final devices = ref.watch(devicesControllerProvider);

    return AppScaffold(
      title: l.navDevices,
      currentRoute: AppRoutes.devices,
      floatingActionButton: FloatingActionButton(
        tooltip: l.addDevice,
        onPressed: () => context.push(AppRoutes.deviceNew),
        child: const Icon(Icons.add),
      ),
      body: ContentWidth(
        maxWidth: 900,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: l.searchHint,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(l.filterAll),
                    selected: _status == null,
                    onSelected: (_) => setState(() => _status = null),
                  ),
                  for (final s in DeviceStatus.values) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(s.label(l)),
                      selected: _status == s,
                      onSelected: (_) => setState(() => _status = s),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: devices.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => EmptyState(
                    icon: Icons.error_outline, title: l.errorGeneric),
                data: (list) {
                  final filtered = list.where((d) {
                    final matchesText = _query.isEmpty ||
                        d.name.toLowerCase().contains(_query) ||
                        d.location.toLowerCase().contains(_query);
                    final matchesStatus = _status == null || d.status == _status;
                    return matchesText && matchesStatus;
                  }).toList();

                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.devices_other_outlined,
                      title: l.noDevices,
                      subtitle: l.noDevicesHint,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _DeviceTile(device: filtered[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceTile extends ConsumerWidget {
  final Device device;
  const _DeviceTile({required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;

    return Dismissible(
      key: ValueKey(device.id),
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
        title: l.deleteTitle,
        message: l.deleteConfirm(device.name),
      ),
      onDismissed: (_) {
        ref.read(devicesControllerProvider.notifier).delete(device.id);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.deleted)));
      },
      child: Card(
        child: ListTile(
          leading: CircleAvatar(child: Icon(device.type.icon)),
          title: Text(device.name),
          subtitle: Text('${device.location} · ${device.type.label(l)}'),
          trailing: StatusChip(status: device.status),
          onTap: () => context.push(AppRoutes.deviceEdit(device.id)),
        ),
      ),
    );
  }
}

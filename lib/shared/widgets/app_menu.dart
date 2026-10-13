import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_routes.dart';
import '../../features/authentication/presentation/providers/auth_controller.dart';
import '../../l10n/l10n_x.dart';

/// Menú principal: se usa dentro del Drawer (móvil) o fijo a la izquierda (ancho).
class AppMenu extends ConsumerWidget {
  final String currentRoute;
  final bool closeOnTap;

  const AppMenu({
    super.key,
    required this.currentRoute,
    required this.closeOnTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).user;
    final name = user?.name ?? '';

    final items = <(String, IconData, String)>[
      (AppRoutes.dashboard, Icons.dashboard_outlined, l.navDashboard),
      (AppRoutes.devices, Icons.devices_other_outlined, l.navDevices),
      (AppRoutes.map, Icons.map_outlined, l.navMap),
      (AppRoutes.alerts, Icons.notifications_active_outlined, l.navAlerts),
      (AppRoutes.settings, Icons.settings_outlined, l.navSettings),
    ];

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis),
                      Text(user?.email ?? '',
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                for (final item in items)
                  ListTile(
                    selected: currentRoute == item.$1,
                    selectedTileColor:
                        theme.colorScheme.primary.withValues(alpha: 0.10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    leading: Icon(item.$2),
                    title: Text(item.$3),
                    onTap: () {
                      if (closeOnTap) Navigator.of(context).pop();
                      if (currentRoute != item.$1) context.go(item.$1);
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l.logout),
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

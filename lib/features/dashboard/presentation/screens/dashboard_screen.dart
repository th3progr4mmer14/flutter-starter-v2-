import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_modules.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../l10n/l10n_x.dart';
import '../../../../shared/constants/app_sizes.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/content_width.dart';
import '../../../../shared/widgets/kpi_card.dart';
import '../../../alerts/domain/alert_item.dart';
import '../../../alerts/presentation/providers/alerts_controller.dart';
import '../../../alerts/presentation/widgets/alert_x.dart';
import '../../../authentication/presentation/providers/auth_controller.dart';
import '../../../devices/domain/device.dart';
import '../../../devices/presentation/providers/devices_controller.dart';
import '../providers/live_metrics_provider.dart';
import '../widgets/live_line_chart.dart';

/// Muestra solo lo que corresponde a los módulos activos:
/// KPIs de dispositivos (devices), KPI y lista de alertas (alerts).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final theme = Theme.of(context);

    final user = ref.watch(authControllerProvider).user;
    final devices = ref.watch(devicesControllerProvider).value ?? <Device>[];
    final alerts = ref.watch(alertsControllerProvider).value ?? <AlertItem>[];
    final metrics = ref.watch(liveMetricsProvider);

    final online =
        devices.where((d) => d.status == DeviceStatus.online).length;
    final offline =
        devices.where((d) => d.status == DeviceStatus.offline).length;
    final activeAlerts = alerts.where((a) => !a.acknowledged).toList();

    return AppScaffold(
      title: l.navDashboard,
      currentRoute: AppRoutes.dashboard,
      body: ContentWidth(
        maxWidth: 1100,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.md),
          children: [
            Text(l.hello(user?.name ?? ''),
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSizes.md),

            // ---- KPIs ----
            LayoutBuilder(builder: (context, box) {
              final cols = box.maxWidth >= 700 ? 4 : 2;
              final w = (box.maxWidth - (cols - 1) * AppSizes.md) / cols;
              return Wrap(
                spacing: AppSizes.md,
                runSpacing: AppSizes.md,
                children: [
                  if (AppModules.devices) ...[
                    SizedBox(
                      width: w,
                      child: KpiCard(
                        icon: Icons.devices_other_outlined,
                        label: l.totalDevices,
                        value: '${devices.length}',
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(
                      width: w,
                      child: KpiCard(
                        icon: Icons.check_circle_outline,
                        label: l.statusOnline,
                        value: '$online',
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(
                      width: w,
                      child: KpiCard(
                        icon: Icons.portable_wifi_off,
                        label: l.statusOffline,
                        value: '$offline',
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  if (AppModules.alerts)
                    SizedBox(
                      width: w,
                      child: KpiCard(
                        icon: Icons.notifications_active_outlined,
                        label: l.activeAlerts,
                        value: '${activeAlerts.length}',
                        color: Colors.red,
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: AppSizes.lg),

            // ---- Gráfica en vivo ----
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(l.liveReadings,
                              style: theme.textTheme.titleMedium),
                        ),
                        if (metrics.value != null)
                          Text(
                            '${l.lastValue}: ${metrics.value!.last.toStringAsFixed(1)}',
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),
                    SizedBox(
                      height: 220,
                      child: metrics.when(
                        data: (v) => LiveLineChart(values: v),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, _) => Center(child: Text(l.errorGeneric)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---- Alertas recientes ----
            if (AppModules.alerts) ...[
              const SizedBox(height: AppSizes.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(l.recentAlerts,
                            style: theme.textTheme.titleMedium),
                        trailing: TextButton(
                          onPressed: () => context.go(AppRoutes.alerts),
                          child: Text(l.viewAll),
                        ),
                      ),
                      if (activeAlerts.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSizes.md),
                          child: Text(l.noAlerts),
                        ),
                      for (final a in activeAlerts.take(3))
                        ListTile(
                          leading:
                              Icon(a.severity.icon, color: a.severity.color),
                          title: Text(a.title),
                          subtitle: Text(a.deviceName),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../l10n/l10n_x.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/content_width.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/alert_item.dart';
import '../providers/alerts_controller.dart';
import '../widgets/alert_x.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  AlertSeverity? _severity; // null = todas

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final alerts = ref.watch(alertsControllerProvider);
    final dateFormat =
        DateFormat.yMd(Localizations.localeOf(context).toString()).add_Hm();

    return AppScaffold(
      title: l.navAlerts,
      currentRoute: AppRoutes.alerts,
      actions: [
        IconButton(
          tooltip: l.clearAcknowledged,
          icon: const Icon(Icons.delete_sweep_outlined),
          onPressed: () =>
              ref.read(alertsControllerProvider.notifier).clearAcknowledged(),
        ),
      ],
      body: ContentWidth(
        maxWidth: 900,
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(l.filterAll),
                    selected: _severity == null,
                    onSelected: (_) => setState(() => _severity = null),
                  ),
                  for (final s in AlertSeverity.values) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(s.label(l)),
                      selected: _severity == s,
                      onSelected: (_) => setState(() => _severity = s),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: alerts.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (_, __) => EmptyState(
                    icon: Icons.error_outline, title: l.errorGeneric),
                data: (list) {
                  final filtered = list
                      .where((a) => _severity == null || a.severity == _severity)
                      .toList();

                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.notifications_off_outlined,
                      title: l.noAlerts,
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final a = filtered[i];
                      return Card(
                        child: ListTile(
                          leading: Icon(a.severity.icon, color: a.severity.color),
                          title: Text(a.title),
                          subtitle: Text(
                              '${a.deviceName} · ${dateFormat.format(a.timestamp)}'),
                          trailing: a.acknowledged
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : TextButton(
                                  onPressed: () => ref
                                      .read(alertsControllerProvider.notifier)
                                      .acknowledge(a.id),
                                  child: Text(l.acknowledge),
                                ),
                        ),
                      );
                    },
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

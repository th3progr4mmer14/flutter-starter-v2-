import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/l10n_x.dart';
import '../../../../shared/widgets/content_width.dart';
import '../providers/settings_controller.dart';

class MonitoringScreen extends ConsumerWidget {
  const MonitoringScreen({super.key});

  static const _options = [2, 5, 10, 30];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final settings = ref.watch(settingsControllerProvider);
    final ctrl = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsMonitoring)),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l.refreshInterval, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(l.refreshEvery(settings.refreshSeconds),
                style: textTheme.bodySmall),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                for (final s in _options)
                  ButtonSegment(value: s, label: Text('$s s')),
              ],
              selected: {settings.refreshSeconds},
              onSelectionChanged: (v) => ctrl.setRefreshSeconds(v.first),
            ),
          ],
        ),
      ),
    );
  }
}

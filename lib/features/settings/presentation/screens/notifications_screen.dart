import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/l10n_x.dart';
import '../../../../shared/widgets/content_width.dart';
import '../providers/settings_controller.dart';

/// Guarda las preferencias. Para notificaciones push reales agrega
/// firebase_messaging o flutter_local_notifications y léelas desde aquí.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final settings = ref.watch(settingsControllerProvider);
    final ctrl = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsNotifications)),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: Text(l.pushNotifications),
              subtitle: Text(l.pushNotificationsDesc),
              value: settings.notificationsEnabled,
              onChanged: ctrl.setNotifications,
            ),
            SwitchListTile(
              title: Text(l.alertSound),
              value: settings.soundEnabled,
              onChanged:
                  settings.notificationsEnabled ? ctrl.setSound : null,
            ),
          ],
        ),
      ),
    );
  }
}

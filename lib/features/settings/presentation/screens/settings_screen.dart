import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../l10n/l10n_x.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/content_width.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    final items = <(IconData, String, String)>[
      (Icons.palette_outlined, l.settingsAppearance, AppRoutes.settingsAppearance),
      (Icons.notifications_outlined, l.settingsNotifications,
          AppRoutes.settingsNotifications),
      (Icons.speed_outlined, l.settingsMonitoring, AppRoutes.settingsMonitoring),
      (Icons.info_outline, l.settingsAbout, AppRoutes.settingsAbout),
    ];

    return AppScaffold(
      title: l.navSettings,
      currentRoute: AppRoutes.settings,
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final item in items)
              Card(
                child: ListTile(
                  leading: Icon(item.$1),
                  title: Text(item.$2),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(item.$3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

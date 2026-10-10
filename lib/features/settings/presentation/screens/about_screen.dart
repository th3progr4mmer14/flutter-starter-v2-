import 'package:flutter/material.dart';

import '../../../../l10n/l10n_x.dart';
import '../../../../shared/widgets/content_width.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Cámbiala por package_info_plus si quieres leerla automáticamente.
  static const _version = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsAbout)),
      body: ContentWidth(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Icon(Icons.monitor_heart_outlined,
                  size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(l.appName, style: theme.textTheme.headlineSmall),
              Text('${l.version} $_version', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: l.appName,
                  applicationVersion: _version,
                ),
                child: Text(l.licenses),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/l10n_x.dart';
import '../../../../shared/widgets/content_width.dart';
import '../providers/settings_controller.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final settings = ref.watch(settingsControllerProvider);
    final ctrl = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsAppearance)),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(l.theme, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto),
                  label: Text(l.systemDefault),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode),
                  label: Text(l.themeLight),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode),
                  label: Text(l.themeDark),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (v) => ctrl.setThemeMode(v.first),
            ),
            const SizedBox(height: 32),
            Text(l.language, style: textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(value: 'system', label: Text(l.systemDefault)),
                const ButtonSegment(value: 'es', label: Text('Español')),
                const ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {settings.languageCode ?? 'system'},
              onSelectionChanged: (v) =>
                  ctrl.setLanguage(v.first == 'system' ? null : v.first),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/api_providers.dart';
import '../../l10n/l10n_x.dart';

/// Franja "sin conexión" que aparece cuando la última petición a la API falló
/// por red. Se oculta sola cuando el servidor vuelve a responder.
class ConnectionBanner extends ConsumerWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(apiOnlineProvider);
    if (online) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 18, color: scheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.offlineBanner,
                style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/errors/failure_x.dart';
import '../../core/errors/failures.dart';
import '../../l10n/l10n_x.dart';

/// Pantalla/zona de error con botón de reintentar.
/// [error] puede ser un Failure o cualquier excepción.
class ErrorView extends StatelessWidget {
  final Object? error;
  final VoidCallback? onRetry;

  const ErrorView({super.key, this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final failure = error == null ? null : Failure.from(error!);
    final message = failure?.localized(l) ?? l.errorGeneric;
    final offline = failure?.isNetwork ?? false;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              offline ? Icons.cloud_off_outlined : Icons.error_outline,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(message,
                style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../l10n/l10n_x.dart';

class ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final int count;
  final bool busy;
  final VoidCallback onPdf;
  final VoidCallback onCsv;
  final Widget? extra;

  const ReportCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.count,
    required this.busy,
    required this.onPdf,
    required this.onCsv,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final disabled = busy || count == 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(child: Icon(icon)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      Text(description, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(l.recordsCount(count), style: theme.textTheme.bodyMedium),
            if (extra != null) ...[
              const SizedBox(height: 4),
              extra!,
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(l.exportPdf),
                    onPressed: disabled ? null : onPdf,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.table_chart_outlined),
                    label: Text(l.exportCsv),
                    onPressed: disabled ? null : onCsv,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/app_modules.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../l10n/l10n_x.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/content_width.dart';
import '../../../alerts/domain/alert_item.dart';
import '../../../alerts/presentation/providers/alerts_controller.dart';
import '../../../devices/domain/device.dart';
import '../../../devices/presentation/providers/devices_controller.dart';
import '../../data/csv_builder.dart';
import '../../data/pdf_report_builder.dart';
import '../../data/report_saver.dart';
import '../../domain/report_table.dart';
import '../report_builders.dart';
import '../widgets/report_card.dart';

enum _Format { pdf, csv }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  bool _busy = false;
  bool _onlyActive = false;

  Future<void> _export(String fileId, ReportTable table, _Format format) async {
    // Se leen antes del primer await para no usar el context después.
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final locale = Localizations.localeOf(context).toString();

    setState(() => _busy = true);
    try {
      final now = DateTime.now();
      final name = '${fileId}_${DateFormat('yyyyMMdd_HHmm').format(now)}';

      final Uint8List bytes;
      final String ext;
      final MimeType mime;

      if (format == _Format.pdf) {
        bytes = await PdfReportBuilder.build(
          table: table,
          appName: l.appName,
          generatedLabel:
              l.reportGenerated(DateFormat.yMd(locale).add_Hm().format(now)),
          pageLabel: (page, pages) => l.pageOf(page, pages),
        );
        ext = 'pdf';
        mime = MimeType.pdf;
      } else {
        bytes = CsvBuilder.build(table);
        ext = 'csv';
        mime = MimeType.csv;
      }

      final path = await ReportSaver.save(
        name: name,
        bytes: bytes,
        ext: ext,
        mimeType: mime,
      );
      messenger.showSnackBar(
        SnackBar(content: Text(path.isEmpty ? l.saved : l.reportSaved(path))),
      );
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.reportError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMd(locale).add_Hm();

    final devices = ref.watch(devicesControllerProvider).value ?? <Device>[];
    final alerts = ref.watch(alertsControllerProvider).value ?? <AlertItem>[];

    final devicesTable = buildDevicesReport(l, devices);
    final alertsTable =
        buildAlertsReport(l, alerts, dateFormat, onlyActive: _onlyActive);

    return AppScaffold(
      title: l.navReports,
      currentRoute: AppRoutes.reports,
      body: ContentWidth(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (AppModules.devices)
              ReportCard(
                icon: Icons.devices_other_outlined,
                title: devicesTable.title,
                description: l.reportDevicesDesc,
                count: devicesTable.rows.length,
                busy: _busy,
                onPdf: () => _export('devices_report', devicesTable, _Format.pdf),
                onCsv: () => _export('devices_report', devicesTable, _Format.csv),
              ),
            if (AppModules.devices && AppModules.alerts)
              const SizedBox(height: 16),
            if (AppModules.alerts)
              ReportCard(
                icon: Icons.notifications_active_outlined,
                title: alertsTable.title,
                description: l.reportAlertsDesc,
                count: alertsTable.rows.length,
                busy: _busy,
                extra: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.onlyActiveAlerts),
                  value: _onlyActive,
                  onChanged: (v) => setState(() => _onlyActive = v),
                ),
                onPdf: () => _export('alerts_report', alertsTable, _Format.pdf),
                onCsv: () => _export('alerts_report', alertsTable, _Format.csv),
              ),
          ],
        ),
      ),
    );
  }
}

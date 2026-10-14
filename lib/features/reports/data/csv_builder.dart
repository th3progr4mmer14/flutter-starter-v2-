import 'dart:convert';
import 'dart:typed_data';

import '../domain/report_table.dart';

class CsvBuilder {
  CsvBuilder._();

  /// Genera un CSV en UTF-8 con BOM (para que Excel respete acentos y ñ).
  static Uint8List build(ReportTable table) {
    final lines = <String>[
      table.headers.map(_cell).join(','),
      for (final row in table.rows) row.map(_cell).join(','),
    ];
    final csv = '\uFEFF${lines.join('\r\n')}\r\n';
    return Uint8List.fromList(utf8.encode(csv));
  }

  static String _cell(String value) {
    var v = _neutralizeFormula(value);
    final needsQuotes = v.contains(',') ||
        v.contains('"') ||
        v.contains('\n') ||
        v.contains('\r');
    v = v.replaceAll('"', '""');
    return needsQuotes ? '"$v"' : v;
  }

  /// Evita "inyección de fórmulas": si un texto (por ejemplo el nombre de un
  /// dispositivo) empieza con = + @ o con - seguido de una letra, Excel/Sheets
  /// podrían ejecutarlo como fórmula. Se le antepone una comilla.
  /// Los números negativos (-99.13) se dejan intactos.
  static String _neutralizeFormula(String v) {
    if (v.isEmpty) return v;
    final first = v[0];
    if (first == '=' || first == '+' || first == '@' || first == '\t' || first == '\r') {
      return "'$v";
    }
    if (first == '-' && v.length > 1 && !RegExp(r'[0-9.]').hasMatch(v[1])) {
      return "'$v";
    }
    return v;
  }
}

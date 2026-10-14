import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

/// Guarda el archivo con file_saver (Android, iOS, Linux, macOS, Windows y web).
/// Devuelve la ruta donde quedó (en web puede venir vacía: se descarga directo).
class ReportSaver {
  ReportSaver._();

  static Future<String> save({
    required String name,
    required Uint8List bytes,
    required String ext,
    required MimeType mimeType,
  }) async {
    final result = await FileSaver.instance.saveFile(
      name: name,
      bytes: bytes,
      fileExtension: ext,
      mimeType: mimeType,
    );
    return '$result';
  }
}

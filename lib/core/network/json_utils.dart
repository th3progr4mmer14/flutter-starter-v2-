/// Lectores tolerantes para JSON de APIs: aceptan números como texto
/// ("12"), booleanos como 0/1, y devuelven null si el dato no sirve.
/// Los modelos generados (tool/new_api_feature.py) los usan en fromJson.
int? asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim());
}

double? asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().trim().replaceAll(',', '.'));
}

bool? asBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  final s = v.toString().toLowerCase().trim();
  if (s == 'true' || s == '1' || s == 'yes' || s == 'si' || s == 'sí') return true;
  if (s == 'false' || s == '0' || s == 'no') return false;
  return null;
}

String? asString(dynamic v) => v?.toString();

DateTime? asDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

List<dynamic> asList(dynamic v) => v is List ? v : const <dynamic>[];

Map<String, dynamic> asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : const <String, dynamic>{};

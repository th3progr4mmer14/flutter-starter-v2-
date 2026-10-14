/// Un reporte es solo una tabla: título, encabezados y filas de texto.
/// Con esta forma simple, el mismo reporte se exporta a PDF o CSV.
class ReportTable {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;

  const ReportTable({
    required this.title,
    required this.headers,
    required this.rows,
  });
}

import 'inventario_item.dart';

abstract class InventarioRepository {
  Future<List<InventarioItem>> getAll();
  Future<void> upsert(InventarioItem item);
  Future<void> delete(String id);
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/inventario_item.dart';
import '../domain/inventario_repository.dart';

/// Guarda los registros como JSON en SharedPreferences.
/// Para una API o base de datos, crea otra clase que implemente
/// InventarioRepository y cámbiala en inventarioRepositoryProvider.
class LocalInventarioRepository implements InventarioRepository {
  static const _key = 'inventario_v1';

  final SharedPreferences _prefs;
  LocalInventarioRepository(this._prefs);

  Future<List<InventarioItem>> _load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return <InventarioItem>[];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => InventarioItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _save(List<InventarioItem> items) => _prefs.setString(
        _key,
        jsonEncode(items.map((i) => i.toJson()).toList()),
      );

  @override
  Future<List<InventarioItem>> getAll() => _load();

  @override
  Future<void> upsert(InventarioItem item) async {
    final list = await _load();
    final i = list.indexWhere((e) => e.id == item.id);
    if (i >= 0) {
      list[i] = item;
    } else {
      list.add(item);
    }
    await _save(list);
  }

  @override
  Future<void> delete(String id) async {
    final list = await _load();
    list.removeWhere((e) => e.id == id);
    await _save(list);
  }
}

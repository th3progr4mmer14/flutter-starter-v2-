import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/work_order_item.dart';
import '../domain/work_order_repository.dart';

/// Guarda los registros como JSON en SharedPreferences.
/// Para una API o base de datos, crea otra clase que implemente
/// WorkOrderRepository y cámbiala en workOrderRepositoryProvider.
class LocalWorkOrderRepository implements WorkOrderRepository {
  static const _key = 'work_order_v1';

  final SharedPreferences _prefs;
  LocalWorkOrderRepository(this._prefs);

  Future<List<WorkOrderItem>> _load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return <WorkOrderItem>[];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => WorkOrderItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _save(List<WorkOrderItem> items) => _prefs.setString(
        _key,
        jsonEncode(items.map((i) => i.toJson()).toList()),
      );

  @override
  Future<List<WorkOrderItem>> getAll() => _load();

  @override
  Future<void> upsert(WorkOrderItem item) async {
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

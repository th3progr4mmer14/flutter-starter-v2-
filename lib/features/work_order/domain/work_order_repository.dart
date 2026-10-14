import 'work_order_item.dart';

abstract class WorkOrderRepository {
  Future<List<WorkOrderItem>> getAll();
  Future<void> upsert(WorkOrderItem item);
  Future<void> delete(String id);
}

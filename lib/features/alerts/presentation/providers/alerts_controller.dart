import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/providers.dart';
import '../../data/local_alert_repository.dart';
import '../../domain/alert_item.dart';

final alertRepositoryProvider = Provider<LocalAlertRepository>(
  (ref) => LocalAlertRepository(ref.watch(sharedPreferencesProvider)),
);

class AlertsController extends AsyncNotifier<List<AlertItem>> {
  LocalAlertRepository get _repo => ref.read(alertRepositoryProvider);

  @override
  Future<List<AlertItem>> build() async {
    final list = await _repo.getAll();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<void> acknowledge(String id) async {
    final updated = [
      for (final a in state.value ?? <AlertItem>[])
        a.id == id ? a.copyWith(acknowledged: true) : a,
    ];
    state = AsyncData(updated);
    await _repo.saveAll(updated);
  }

  Future<void> clearAcknowledged() async {
    final updated =
        (state.value ?? <AlertItem>[]).where((a) => !a.acknowledged).toList();
    state = AsyncData(updated);
    await _repo.saveAll(updated);
  }
}

final alertsControllerProvider =
    AsyncNotifierProvider<AlertsController, List<AlertItem>>(
        AlertsController.new);

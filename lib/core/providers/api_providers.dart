import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/authentication/presentation/providers/auth_controller.dart';
import '../network/api_client.dart';
import 'providers.dart';

/// ¿El servidor está respondiendo? (se actualiza con cada petición de ApiClient)
class ApiOnlineNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool online) {
    if (state == online) return;
    // Fuera del ciclo de construcción de widgets.
    Future.microtask(() => state = online);
  }
}

final apiOnlineProvider =
    NotifierProvider<ApiOnlineNotifier, bool>(ApiOnlineNotifier.new);

/// Cliente para consumir la API. Úsalo desde tus repositorios:
///   final client = ref.watch(apiClientProvider);
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    // Si la sesión ya no se puede renovar, se cierra y el router manda al login.
    onUnauthorized: () => ref.read(authControllerProvider.notifier).logout(),
    onConnectivityChanged: (online) =>
        ref.read(apiOnlineProvider.notifier).set(online),
  );
});

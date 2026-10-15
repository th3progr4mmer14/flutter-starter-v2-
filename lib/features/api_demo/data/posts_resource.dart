import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/remote_resource.dart';
import '../../../core/providers/api_providers.dart';
import '../domain/post.dart';

/// EJEMPLO de cómo conectar un endpoint: JSONPlaceholder (API pública de
/// pruebas). Usa una URL absoluta, por eso el token de tu API NO se envía.
/// JSONPlaceholder pagina con _page y _limit, así que se sobreescriben aquí.
///
/// Para tu API real: path '/products', y deja page/limit con los valores de
/// ApiConfig (o cámbialos en ese archivo si todas tus rutas usan otros).
final postsResourceProvider = Provider<RemoteResource<Post>>((ref) {
  return RemoteResource<Post>(
    client: ref.watch(apiClientProvider),
    path: 'https://jsonplaceholder.typicode.com/posts',
    fromJson: Post.fromJson,
    toJson: (p) => p.toJson(),
    pageParam: '_page',
    limitParam: '_limit',
  );
});

// ignore_for_file: unintended_html_in_doc_comment

import '../config/api_config.dart';
import 'api_client.dart';

/// Una página de resultados.
class PagedResult<T> {
  final List<T> items;
  final int page;
  final bool hasMore;
  final int? total;

  const PagedResult({
    required this.items,
    required this.page,
    required this.hasMore,
    this.total,
  });
}

/// CRUD genérico contra un endpoint REST: /products, /products/{id}, ...
///
///   final products = RemoteResource<Product>(
///     client: client,
///     path: '/products',
///     fromJson: Product.fromJson,
///     toJson: (p) => p.toJson(),
///   );
///   final page = await products.list(page: 1);
///
/// Si la API usa otros nombres de paginación, pásalos en pageParam/limitParam
/// (o cámbialos para todos en ApiConfig).
class RemoteResource<T> {
  final ApiClient client;
  final String path;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T item)? toJson;
  final String pageParam;
  final String limitParam;

  /// true = editar con PATCH en vez de PUT (algunas APIs solo aceptan PATCH).
  final bool usePatch;

  RemoteResource({
    required this.client,
    required this.path,
    required this.fromJson,
    this.toJson,
    this.pageParam = ApiConfig.pageParam,
    this.limitParam = ApiConfig.limitParam,
    this.usePatch = false,
  });

  Future<PagedResult<T>> list({
    int page = 1,
    int limit = ApiConfig.defaultPageSize,
    Map<String, dynamic>? query,
  }) async {
    final body = await client.get(path, query: {
      pageParam: page,
      limitParam: limit,
      ...?query,
    });

    final rawItems = _extractItems(body);
    final items = rawItems
        .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    int? total;
    if (body is Map && body[ApiConfig.totalKey] is num) {
      total = (body[ApiConfig.totalKey] as num).toInt();
    }

    // Con total conocido se calcula exacto; si no, una página llena
    // sugiere que hay más.
    final hasMore = total != null ? page * limit < total : items.length >= limit;

    return PagedResult(items: items, page: page, hasMore: hasMore, total: total);
  }

  Future<T> getById(String id) async {
    final body = await client.get('$path/$id');
    return fromJson(Map<String, dynamic>.from(body as Map));
  }

  Future<T> create(T item) async {
    final body = await client.post(path, data: _encode(item));
    return body is Map ? fromJson(Map<String, dynamic>.from(body)) : item;
  }

  Future<T> update(String id, T item) async {
    final data = _encode(item);
    final body = usePatch
        ? await client.patch('$path/$id', data: data)
        : await client.put('$path/$id', data: data);
    return body is Map ? fromJson(Map<String, dynamic>.from(body)) : item;
  }

  Future<void> delete(String id) async {
    await client.delete('$path/$id');
  }

  Map<String, dynamic> _encode(T item) {
    final encoder = toJson;
    if (encoder == null) {
      throw StateError('RemoteResource<$T> necesita toJson para crear/editar');
    }
    return encoder(item);
  }

  /// Acepta una lista directa o un objeto con la lista adentro.
  List<dynamic> _extractItems(dynamic body) {
    if (body is List) return body;
    if (body is Map) {
      for (final key in ApiConfig.itemsKeys) {
        final value = body[key];
        if (value is List) return value;
      }
    }
    return const [];
  }
}

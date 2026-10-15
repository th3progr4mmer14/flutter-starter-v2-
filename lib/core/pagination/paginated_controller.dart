// ignore_for_file: unintended_html_in_doc_comment

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/failures.dart';
import '../network/remote_resource.dart';

class PaginatedState<T> {
  final List<T> items;
  final int page;
  final bool hasMore;
  final bool initialLoading;
  final bool loadingMore;
  final Failure? error;

  const PaginatedState({
    this.items = const [],
    this.page = 0,
    this.hasMore = true,
    this.initialLoading = false,
    this.loadingMore = false,
    this.error,
  });

  PaginatedState<T> copyWith({
    List<T>? items,
    int? page,
    bool? hasMore,
    bool? initialLoading,
    bool? loadingMore,
    Failure? error,
    bool clearError = false,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      initialLoading: initialLoading ?? this.initialLoading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Base para listas paginadas con "jalar para refrescar" y scroll infinito.
/// Solo implementa [fetchPage]:
///
///   class ProductsController extends PaginatedController<Product> {
///     @override
///     Future<PagedResult<Product>> fetchPage(int page) =>
///         ref.read(productsResourceProvider).list(page: page);
///   }
///   final productsControllerProvider =
///       NotifierProvider<ProductsController, PaginatedState<Product>>(
///           ProductsController.new);
abstract class PaginatedController<T> extends Notifier<PaginatedState<T>> {
  /// Trae la página [page] (empieza en 1).
  Future<PagedResult<T>> fetchPage(int page);

  bool _busy = false;

  @override
  PaginatedState<T> build() {
    Future.microtask(refresh);
    return PaginatedState<T>(initialLoading: true);
  }

  /// Recarga desde la primera página.
  Future<void> refresh() async {
    if (_busy) return;
    _busy = true;

    final hadItems = state.items.isNotEmpty;
    state = state.copyWith(initialLoading: !hadItems, clearError: true);

    try {
      final result = await fetchPage(1);
      state = PaginatedState<T>(
        items: result.items,
        page: 1,
        hasMore: result.hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        initialLoading: false,
        error: Failure.from(e),
      );
    } finally {
      _busy = false;
    }
  }

  /// Trae la siguiente página (si hay).
  Future<void> loadMore() async {
    if (_busy || !state.hasMore || state.initialLoading) return;
    _busy = true;
    state = state.copyWith(loadingMore: true, clearError: true);

    try {
      final next = state.page + 1;
      final result = await fetchPage(next);
      state = state.copyWith(
        items: [...state.items, ...result.items],
        page: next,
        hasMore: result.hasMore,
        loadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: Failure.from(e));
    } finally {
      _busy = false;
    }
  }
}

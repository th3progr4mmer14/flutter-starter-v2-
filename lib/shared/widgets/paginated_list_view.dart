// ignore_for_file: unintended_html_in_doc_comment

import 'package:flutter/material.dart';

import '../../core/pagination/paginated_controller.dart';
import '../../l10n/l10n_x.dart';
import 'empty_state.dart';
import 'error_view.dart';

/// Lista con carga inicial, "jalar para refrescar", scroll infinito,
/// estado vacío y error con reintento. Se alimenta de un PaginatedController.
///
///   final state = ref.watch(productsControllerProvider);
///   final ctrl = ref.read(productsControllerProvider.notifier);
///   PaginatedListView<Product>(
///     state: state,
///     onRefresh: ctrl.refresh,
///     onLoadMore: ctrl.loadMore,
///     itemBuilder: (context, p) => ListTile(title: Text(p.name)),
///   )
class PaginatedListView<T> extends StatelessWidget {
  final PaginatedState<T> state;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget? empty;
  final EdgeInsetsGeometry padding;

  const PaginatedListView({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
    required this.itemBuilder,
    this.empty,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 24),
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    if (state.initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return ErrorView(error: state.error, onRetry: onRefresh);
    }

    if (state.items.isEmpty) {
      // ListView para que también se pueda jalar para refrescar.
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            empty ?? EmptyState(icon: Icons.inbox_outlined, title: l.noResults),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 240) {
            onLoadMore();
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: padding,
          itemCount: state.items.length + 1,
          itemBuilder: (context, i) {
            if (i < state.items.length) {
              return itemBuilder(context, state.items[i]);
            }
            return _Footer(state: state, onLoadMore: onLoadMore);
          },
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final PaginatedState<dynamic> state;
  final VoidCallback onLoadMore;

  const _Footer({required this.state, required this.onLoadMore});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: TextButton.icon(
            onPressed: onLoadMore,
            icon: const Icon(Icons.refresh),
            label: Text(l.retry),
          ),
        ),
      );
    }

    if (state.hasMore) {
      // También sirve si la lista es corta y no alcanza a hacer scroll.
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: TextButton(onPressed: onLoadMore, child: Text(l.loadMore)),
        ),
      );
    }

    return const SizedBox(height: 16);
  }
}

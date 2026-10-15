// ignore_for_file: unintended_html_in_doc_comment

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_x.dart';
import 'empty_state.dart';
import 'error_view.dart';

/// Pinta un AsyncValue con sus tres estados (cargando, error con reintento,
/// datos) y, opcionalmente, el estado vacío.
///
///   AsyncValueView<List<Product>>(
///     value: ref.watch(productsProvider),
///     onRetry: () => ref.invalidate(productsProvider),
///     isEmpty: (list) => list.isEmpty,
///     data: (list) => ProductList(list),
///   )
class AsyncValueView<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final bool Function(T data)? isEmpty;
  final Widget? empty;

  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.isEmpty,
    this.empty,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorView(error: e, onRetry: onRetry),
      data: (d) {
        if (isEmpty?.call(d) ?? false) {
          return empty ??
              EmptyState(
                icon: Icons.inbox_outlined,
                title: context.l10n.noResults,
              );
        }
        return data(d);
      },
    );
  }
}

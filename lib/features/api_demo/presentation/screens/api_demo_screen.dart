import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../l10n/l10n_x.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../../../../shared/widgets/content_width.dart';
import '../../../../shared/widgets/paginated_list_view.dart';
import '../../domain/post.dart';
import '../providers/posts_controller.dart';

/// Ejemplo de pantalla que consume una API: carga inicial, jalar para
/// refrescar, scroll infinito, error con reintento y banner sin conexión.
/// Cópiala como punto de partida para tus pantallas con API.
class ApiDemoScreen extends ConsumerWidget {
  const ApiDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final state = ref.watch(postsControllerProvider);
    final controller = ref.read(postsControllerProvider.notifier);

    return AppScaffold(
      title: l.navApiDemo,
      currentRoute: AppRoutes.apiDemo,
      body: ContentWidth(
        maxWidth: 900,
        child: PaginatedListView<Post>(
          state: state,
          onRefresh: controller.refresh,
          onLoadMore: controller.loadMore,
          itemBuilder: (context, post) => Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${post.id}')),
              title: Text(post.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle:
                  Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () => _showPost(context, post),
            ),
          ),
        ),
      ),
    );
  }

  void _showPost(BuildContext context, Post post) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.title, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text(post.body),
            ],
          ),
        ),
      ),
    );
  }
}

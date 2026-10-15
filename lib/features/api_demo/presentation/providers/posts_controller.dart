import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/remote_resource.dart';
import '../../../../core/pagination/paginated_controller.dart';
import '../../data/posts_resource.dart';
import '../../domain/post.dart';

/// Lista paginada: solo hay que decir cómo traer una página.
class PostsController extends PaginatedController<Post> {
  @override
  Future<PagedResult<Post>> fetchPage(int page) =>
      ref.read(postsResourceProvider).list(page: page);
}

final postsControllerProvider =
    NotifierProvider<PostsController, PaginatedState<Post>>(
        PostsController.new);

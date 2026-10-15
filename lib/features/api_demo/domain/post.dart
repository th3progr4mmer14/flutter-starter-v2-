class Post {
  final int id;
  final int userId;
  final String title;
  final String body;

  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: (json['id'] as num).toInt(),
        userId: (json['userId'] as num?)?.toInt() ?? 0,
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'userId': userId, 'title': title, 'body': body};
}

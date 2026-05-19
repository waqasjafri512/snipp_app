/// Data model for a Comment.
class CommentModel {
  final int id;
  final int dareId;
  final int userId;
  final String content;
  final int? parentId;
  final String? createdAt;

  // Author info
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final bool isVerified;

  // Interaction
  int likesCount;
  bool isLiked;

  CommentModel({
    required this.id,
    required this.dareId,
    required this.userId,
    required this.content,
    this.parentId,
    this.createdAt,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.isVerified = false,
    this.likesCount = 0,
    this.isLiked = false,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? 0,
      dareId: json['dare_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      content: json['content'] ?? '',
      parentId: json['parent_id'],
      createdAt: json['created_at'],
      username: json['username'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      isVerified: json['is_verified'] == true,
      likesCount: json['likes_count'] ?? 0,
      isLiked: json['is_liked'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dare_id': dareId,
      'user_id': userId,
      'content': content,
      'parent_id': parentId,
      'created_at': createdAt,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'is_verified': isVerified,
      'likes_count': likesCount,
      'is_liked': isLiked,
    };
  }

  /// Display name for the comment author.
  String get displayName => fullName ?? username ?? 'User';

  /// Whether this is a reply to another comment.
  bool get isReply => parentId != null;
}

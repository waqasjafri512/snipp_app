/// Data model for a Dare post.
/// Provides type safety instead of raw Map<String, dynamic>.
class DareModel {
  final int id;
  final int creatorId;
  final String? title;
  final String? description;
  final String postType; // 'dare', 'completion', 'general'
  final String? category;
  final String? emoji;
  final String? mediaUrl;
  final String? mediaType;
  final String? createdAt;

  // Creator info
  final String? creatorUsername;
  final String? creatorFullName;
  final String? creatorAvatar;
  final bool creatorVerified;

  // Solver info (for completions)
  final int? solverId;
  final String? solverUsername;
  final String? solverFullName;
  final bool solverVerified;

  // Interaction counts
  int likesCount;
  int commentsCount;
  int sharesCount;
  int acceptsCount;

  // User interaction flags
  bool isLiked;
  bool isAccepted;
  bool isFollowingCreator;
  bool isFollowingSolver;

  DareModel({
    required this.id,
    required this.creatorId,
    this.title,
    this.description,
    this.postType = 'dare',
    this.category,
    this.emoji,
    this.mediaUrl,
    this.mediaType,
    this.createdAt,
    this.creatorUsername,
    this.creatorFullName,
    this.creatorAvatar,
    this.creatorVerified = false,
    this.solverId,
    this.solverUsername,
    this.solverFullName,
    this.solverVerified = false,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.acceptsCount = 0,
    this.isLiked = false,
    this.isAccepted = false,
    this.isFollowingCreator = false,
    this.isFollowingSolver = false,
  });

  factory DareModel.fromJson(Map<String, dynamic> json) {
    return DareModel(
      id: json['id'] ?? 0,
      creatorId: json['creator_id'] ?? 0,
      title: json['title'],
      description: json['description'],
      postType: json['post_type'] ?? json['actual_post_type'] ?? 'dare',
      category: json['category'],
      emoji: json['emoji'],
      mediaUrl: json['media_url'],
      mediaType: json['media_type'],
      createdAt: json['created_at'],
      creatorUsername: json['creator_username'],
      creatorFullName: json['creator_full_name'] ?? json['creator_name'],
      creatorAvatar: json['creator_avatar'],
      creatorVerified: json['creator_verified'] == true,
      solverId: json['solver_id'],
      solverUsername: json['solver_username'],
      solverFullName: json['solver_full_name'],
      solverVerified: json['solver_verified'] == true,
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      sharesCount: json['shares_count'] ?? 0,
      acceptsCount: json['accepts_count'] ?? 0,
      isLiked: json['is_liked'] == true,
      isAccepted: json['is_accepted'] == true,
      isFollowingCreator: json['is_following_creator'] == true,
      isFollowingSolver: json['is_following_solver'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creator_id': creatorId,
      'title': title,
      'description': description,
      'post_type': postType,
      'category': category,
      'emoji': emoji,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'created_at': createdAt,
      'creator_username': creatorUsername,
      'creator_full_name': creatorFullName,
      'creator_avatar': creatorAvatar,
      'creator_verified': creatorVerified,
      'solver_id': solverId,
      'solver_username': solverUsername,
      'solver_full_name': solverFullName,
      'solver_verified': solverVerified,
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'shares_count': sharesCount,
      'accepts_count': acceptsCount,
      'is_liked': isLiked,
      'is_accepted': isAccepted,
      'is_following_creator': isFollowingCreator,
      'is_following_solver': isFollowingSolver,
    };
  }

  /// Whether this dare has any media attached.
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;

  /// Whether this is a completion post.
  bool get isCompletion => postType == 'completion';

  /// Whether this is a general/status post.
  bool get isGeneral => postType == 'general';

  /// Display name for the post author.
  String get displayName {
    if (isCompletion) {
      return solverFullName ?? solverUsername ?? 'User';
    }
    return creatorFullName ?? creatorUsername ?? 'User';
  }

  /// The user ID of the profile to navigate to.
  int get targetUserId {
    if (isCompletion) {
      return solverId ?? creatorId;
    }
    return creatorId;
  }
}

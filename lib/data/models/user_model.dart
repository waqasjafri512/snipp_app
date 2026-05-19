/// Data model for a User.
/// Provides type safety instead of raw Map<String, dynamic>.
class UserModel {
  final int id;
  final String? username;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final String? location;
  final String? fromLocation;
  final String? worksAt;
  final String? studiedAt;
  final bool isVerified;
  final bool isPrivate;
  final int followersCount;
  final int followingCount;
  final int daresCount;
  final bool isFollowing;
  final bool isFriend;
  final String? fcmToken;
  final String? lastSeen;

  UserModel({
    required this.id,
    this.username,
    this.fullName,
    this.email,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.location,
    this.fromLocation,
    this.worksAt,
    this.studiedAt,
    this.isVerified = false,
    this.isPrivate = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.daresCount = 0,
    this.isFollowing = false,
    this.isFriend = false,
    this.fcmToken,
    this.lastSeen,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'],
      fullName: json['full_name'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
      coverUrl: json['cover_url'],
      bio: json['bio'],
      location: json['location'],
      fromLocation: json['from_location'],
      worksAt: json['works_at'],
      studiedAt: json['studied_at'],
      isVerified: json['is_verified'] == true,
      isPrivate: json['is_private'] == true,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      daresCount: json['dares_count'] ?? 0,
      isFollowing: json['is_following'] == true,
      isFriend: json['is_friend'] == true,
      fcmToken: json['fcm_token'],
      lastSeen: json['last_seen'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'email': email,
      'avatar_url': avatarUrl,
      'cover_url': coverUrl,
      'bio': bio,
      'location': location,
      'from_location': fromLocation,
      'works_at': worksAt,
      'studied_at': studiedAt,
      'is_verified': isVerified,
      'is_private': isPrivate,
      'followers_count': followersCount,
      'following_count': followingCount,
      'dares_count': daresCount,
      'is_following': isFollowing,
      'is_friend': isFriend,
      'fcm_token': fcmToken,
      'last_seen': lastSeen,
    };
  }

  /// Display name with fallback to username.
  String get displayName => fullName ?? username ?? 'User';

  /// First letter of display name for avatar placeholder.
  String get initials => displayName[0].toUpperCase();

  /// Whether the user has a profile picture.
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  /// Whether the user has a cover photo.
  bool get hasCover => coverUrl != null && coverUrl!.isNotEmpty;
}

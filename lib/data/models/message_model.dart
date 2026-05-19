/// Data model for a Chat Message.
class MessageModel {
  final int id;
  final int senderId;
  final int? receiverId;
  final int? groupId;
  final String? content;
  final String type; // 'text', 'image', 'video'
  final String? mediaUrl;
  final bool isRead;
  final String? createdAt;

  // Sender info (for group messages)
  final String? username;
  final String? avatarUrl;

  MessageModel({
    required this.id,
    required this.senderId,
    this.receiverId,
    this.groupId,
    this.content,
    this.type = 'text',
    this.mediaUrl,
    this.isRead = false,
    this.createdAt,
    this.username,
    this.avatarUrl,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      receiverId: json['receiver_id'],
      groupId: json['group_id'],
      content: json['content'],
      type: json['type'] ?? 'text',
      mediaUrl: json['media_url'],
      isRead: json['is_read'] == true,
      createdAt: json['created_at'],
      username: json['username'],
      avatarUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'group_id': groupId,
      'content': content,
      'type': type,
      'media_url': mediaUrl,
      'is_read': isRead,
      'created_at': createdAt,
      'username': username,
      'avatar_url': avatarUrl,
    };
  }

  /// Whether this message is a group message.
  bool get isGroupMessage => groupId != null;

  /// Whether this message contains media.
  bool get hasMedia => mediaUrl != null && mediaUrl!.isNotEmpty;
}

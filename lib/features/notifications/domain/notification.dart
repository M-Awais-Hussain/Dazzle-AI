class AppNotification {
  final String id;
  final String receiverId;
  final String? senderId;
  final String role;
  final String type; // 'marketplace_order', 'designer_request', 'designer_response', 'chat', 'order_status', 'general'
  final String title;
  final String body;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  // Joined sender details from the profiles table
  final String? senderName;
  final String? senderAvatarUrl;

  AppNotification({
    required this.id,
    required this.receiverId,
    this.senderId,
    required this.role,
    required this.type,
    required this.title,
    required this.body,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
    this.senderName,
    this.senderAvatarUrl,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    // Safely parse joined profile data
    final profilesJson = json['profiles'] as Map<String, dynamic>?;
    final sName = profilesJson != null ? profilesJson['full_name'] as String? : json['sender_name'] as String?;
    final sAvatar = profilesJson != null ? profilesJson['avatar_url'] as String? : json['sender_avatar_url'] as String?;

    return AppNotification(
      id: json['id'] as String,
      receiverId: json['receiver_id'] as String,
      senderId: json['sender_id'] as String?,
      role: json['role'] as String? ?? 'user',
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      referenceId: json['reference_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']).toLocal() 
          : DateTime.now(),
      senderName: sName,
      senderAvatarUrl: sAvatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'receiver_id': receiverId,
      'sender_id': senderId,
      'role': role,
      'type': type,
      'title': title,
      'body': body,
      'reference_id': referenceId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    String? receiverId,
    String? senderId,
    String? role,
    String? type,
    String? title,
    String? body,
    String? referenceId,
    bool? isRead,
    DateTime? createdAt,
    String? senderName,
    String? senderAvatarUrl,
  }) {
    return AppNotification(
      id: id ?? this.id,
      receiverId: receiverId ?? this.receiverId,
      senderId: senderId ?? this.senderId,
      role: role ?? this.role,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      referenceId: referenceId ?? this.referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
    );
  }
}

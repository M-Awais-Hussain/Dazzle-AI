class DesignerRequest {
  final String id;
  final String userId;
  final String designerId;
  final String budget;
  final String preferences;
  final String roomType;
  final List<String> attachments;
  final String accessLevel;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Joined user metadata (optional, populated in SQL select)
  final String? userName;
  final String? userAvatarUrl;

  DesignerRequest({
    required this.id,
    required this.userId,
    required this.designerId,
    required this.budget,
    required this.preferences,
    required this.roomType,
    required this.attachments,
    required this.accessLevel,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userAvatarUrl,
  });

  factory DesignerRequest.fromJson(Map<String, dynamic> json) {
    // Check if there is joined profiles table info
    final profilesJson = json['profiles'] as Map<String, dynamic>?;
    final uName = profilesJson != null ? profilesJson['full_name'] as String? : json['user_name'] as String?;
    final uAvatar = profilesJson != null ? profilesJson['avatar_url'] as String? : json['user_avatar_url'] as String?;

    return DesignerRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      designerId: json['designer_id'] as String,
      budget: json['budget'] as String? ?? 'N/A',
      preferences: json['preferences'] as String? ?? '',
      roomType: json['room_type'] as String? ?? 'Living Room',
      attachments: (json['attachments'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      accessLevel: json['access_level'] as String? ?? 'chat_only',
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
      userName: uName ?? 'Client',
      userAvatarUrl: uAvatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'designer_id': designerId,
      'budget': budget,
      'preferences': preferences,
      'room_type': roomType,
      'attachments': attachments,
      'access_level': accessLevel,
      'status': status,
    };
  }

  DesignerRequest copyWith({
    String? id,
    String? userId,
    String? designerId,
    String? budget,
    String? preferences,
    String? roomType,
    List<String>? attachments,
    String? accessLevel,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userAvatarUrl,
  }) {
    return DesignerRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      designerId: designerId ?? this.designerId,
      budget: budget ?? this.budget,
      preferences: preferences ?? this.preferences,
      roomType: roomType ?? this.roomType,
      attachments: attachments ?? this.attachments,
      accessLevel: accessLevel ?? this.accessLevel,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
    );
  }
}

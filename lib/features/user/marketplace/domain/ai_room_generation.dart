class AiRoomGeneration {
  final String id;
  final String userId;
  final String productId;
  final String originalProductImage;
  final String transparentProductImage;
  final String roomImage;
  final String generatedImage;
  final String? productDescription;
  final DateTime createdAt;

  const AiRoomGeneration({
    required this.id,
    required this.userId,
    required this.productId,
    required this.originalProductImage,
    required this.transparentProductImage,
    required this.roomImage,
    required this.generatedImage,
    this.productDescription,
    required this.createdAt,
  });

  factory AiRoomGeneration.fromJson(Map<String, dynamic> json) {
    return AiRoomGeneration(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      originalProductImage: json['original_product_image'] as String,
      transparentProductImage: json['transparent_product_image'] as String,
      roomImage: json['room_image'] as String,
      generatedImage: json['generated_image'] as String,
      productDescription: json['product_description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'product_id': productId,
      'original_product_image': originalProductImage,
      'transparent_product_image': transparentProductImage,
      'room_image': roomImage,
      'generated_image': generatedImage,
      'product_description': productDescription,
    };
  }
}

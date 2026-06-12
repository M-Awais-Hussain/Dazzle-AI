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
  final double? positionX;
  final double? positionY;
  final double? scale;
  final double? rotation;
  final double? canvasWidth;
  final double? canvasHeight;

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
    this.positionX,
    this.positionY,
    this.scale,
    this.rotation,
    this.canvasWidth,
    this.canvasHeight,
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
      positionX: (json['position_x'] as num?)?.toDouble(),
      positionY: (json['position_y'] as num?)?.toDouble(),
      scale: (json['scale'] as num?)?.toDouble(),
      rotation: (json['rotation'] as num?)?.toDouble(),
      canvasWidth: (json['canvas_width'] as num?)?.toDouble(),
      canvasHeight: (json['canvas_height'] as num?)?.toDouble(),
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
      if (positionX != null) 'position_x': positionX,
      if (positionY != null) 'position_y': positionY,
      if (scale != null) 'scale': scale,
      if (rotation != null) 'rotation': rotation,
      if (canvasWidth != null) 'canvas_width': canvasWidth,
      if (canvasHeight != null) 'canvas_height': canvasHeight,
    };
  }
}

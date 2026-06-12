class AiCreation {
  final String id;
  final String userId;
  final String productId;
  final String generatedImageUrl;
  final String roomImageUrl;
  final String transparentProductUrl;
  final String selectedProductImageUrl;
  final String productName;
  final String? productDescription;
  final String generationPrompt;
  final DateTime createdAt;
  final String generationVersion;
  final double? positionX;
  final double? positionY;
  final double? scale;
  final double? rotation;
  final double? canvasWidth;
  final double? canvasHeight;

  const AiCreation({
    required this.id,
    required this.userId,
    required this.productId,
    required this.generatedImageUrl,
    required this.roomImageUrl,
    required this.transparentProductUrl,
    required this.selectedProductImageUrl,
    required this.productName,
    this.productDescription,
    required this.generationPrompt,
    required this.createdAt,
    required this.generationVersion,
    this.positionX,
    this.positionY,
    this.scale,
    this.rotation,
    this.canvasWidth,
    this.canvasHeight,
  });

  factory AiCreation.fromJson(Map<String, dynamic> json) {
    return AiCreation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      generatedImageUrl: json['generated_image_url'] as String,
      roomImageUrl: json['room_image_url'] as String,
      transparentProductUrl: json['transparent_product_url'] as String,
      selectedProductImageUrl: json['selected_product_image_url'] as String,
      productName: json['product_name'] as String? ?? 'Luxury Furniture',
      productDescription: json['product_description'] as String?,
      generationPrompt: json['generation_prompt'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      generationVersion: json['generation_version'] as String? ?? 'v1',
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
      'generated_image_url': generatedImageUrl,
      'room_image_url': roomImageUrl,
      'transparent_product_url': transparentProductUrl,
      'selected_product_image_url': selectedProductImageUrl,
      'product_name': productName,
      'product_description': productDescription,
      'generation_prompt': generationPrompt,
      'generation_version': generationVersion,
      if (positionX != null) 'position_x': positionX,
      if (positionY != null) 'position_y': positionY,
      if (scale != null) 'scale': scale,
      if (rotation != null) 'rotation': rotation,
      if (canvasWidth != null) 'canvas_width': canvasWidth,
      if (canvasHeight != null) 'canvas_height': canvasHeight,
    };
  }
}

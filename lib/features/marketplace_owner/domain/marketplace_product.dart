import 'package:freezed_annotation/freezed_annotation.dart';

part 'marketplace_product.freezed.dart';
part 'marketplace_product.g.dart';

@freezed
abstract class MarketplaceProduct with _$MarketplaceProduct {
  const MarketplaceProduct._();

  const factory MarketplaceProduct({
    required String id,
    @JsonKey(name: 'shopkeeper_id') required String ownerId,
    @JsonKey(name: 'owner_id') String? ownerIdField,
    @JsonKey(name: 'marketplace_profile_id') String? marketplaceProfileId,
    /// Falls back to 'name' column if 'title' is null
    String? title,
    String? name,
    String? description,
    @JsonKey(name: 'category_id') String? categoryId,
    @Default(0) double price,
    @JsonKey(name: 'stock_quantity') @Default(0) int stock,
    @Default('') String dimensions,
    @Default('') String material,
    @Default([]) List<String> colors,
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
    @JsonKey(name: 'image_urls') @Default([]) List<String> imageUrls,
    @JsonKey(name: 'is_featured') @Default(false) bool isFeatured,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _MarketplaceProduct;

  factory MarketplaceProduct.fromJson(Map<String, dynamic> json) =>
      _$MarketplaceProductFromJson(json);

  /// Returns title if set, otherwise falls back to name
  String get displayTitle => title ?? name ?? 'Untitled Product';

  /// Returns first image URL or null
  String? get primaryImage => thumbnailUrl ?? (imageUrls.isNotEmpty ? imageUrls.first : null);

  /// Returns true if stock is low (≤ 5)
  bool get isLowStock => stock > 0 && stock <= 5;

  /// Returns true if out of stock
  bool get isOutOfStock => stock <= 0;
}

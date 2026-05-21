import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';
part 'product.g.dart';

@freezed
abstract class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required double price,
    @JsonKey(name: 'thumbnail_url', defaultValue: '') required String imageUrl,
    @JsonKey(name: 'category_id', defaultValue: '') required String category,
    required String description,
    @JsonKey(name: 'owner_id') String? ownerId,
    @JsonKey(name: 'marketplace_profile_id') String? marketplaceProfileId,
    @JsonKey(name: 'image_urls') @Default([]) List<String> imageUrls,
    @JsonKey(name: 'stock_quantity') @Default(0) int stock,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
}

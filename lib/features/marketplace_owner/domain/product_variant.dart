import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_variant.freezed.dart';
part 'product_variant.g.dart';

@freezed
abstract class ProductVariant with _$ProductVariant {
  const ProductVariant._();

  const factory ProductVariant({
    required String id,
    @JsonKey(name: 'product_id') required String productId,
    @JsonKey(name: 'variant_type') required String variantType, // 'color' or 'layout'
    @JsonKey(name: 'color_name') String? colorName,
    @JsonKey(name: 'hex_code') String? hexCode,
    @JsonKey(name: 'layout_type') String? layoutType, // 'horizontal' or 'vertical'
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ProductVariant;

  factory ProductVariant.fromJson(Map<String, dynamic> json) =>
      _$ProductVariantFromJson(json);

  bool get isColor => variantType == 'color';
  bool get isLayout => variantType == 'layout';
  
  String? get displayThumbnail => thumbnailUrl ?? imageUrl;
}

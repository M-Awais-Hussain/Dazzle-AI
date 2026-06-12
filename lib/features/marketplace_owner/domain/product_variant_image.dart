import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_variant_image.freezed.dart';
part 'product_variant_image.g.dart';

@freezed
abstract class ProductVariantImage with _$ProductVariantImage {
  const ProductVariantImage._();

  const factory ProductVariantImage({
    required String id,
    @JsonKey(name: 'product_id') required String productId,
    @JsonKey(name: 'color_variant_id') String? colorVariantId,
    @JsonKey(name: 'layout_variant_id') String? layoutVariantId,
    @JsonKey(name: 'image_url') required String imageUrl,
    @JsonKey(name: 'thumbnail_url') String? thumbnailUrl,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ProductVariantImage;

  factory ProductVariantImage.fromJson(Map<String, dynamic> json) =>
      _$ProductVariantImageFromJson(json);

  String get displayThumbnail => thumbnailUrl ?? imageUrl;
}

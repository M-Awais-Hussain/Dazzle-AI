import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/user/marketplace/domain/product_variant.dart';
import 'package:ayyy/features/user/marketplace/domain/product_variant_image.dart';
import 'package:ayyy/core/errors/exceptions.dart';

abstract class ProductVariantRepository {
  Future<List<ProductVariant>> getVariantsForProduct(String productId);
  Future<List<ProductVariant>> getColorVariants(String productId);
  Future<List<ProductVariant>> getLayoutVariants(String productId);
  Future<List<ProductVariantImage>> getVariantImages(String productId);
  Future<void> updateTransparentImageUrl(String imageId, String url);
}

class SupabaseProductVariantRepository implements ProductVariantRepository {
  final SupabaseClient _supabase;

  SupabaseProductVariantRepository(this._supabase);

  @override
  Future<List<ProductVariant>> getVariantsForProduct(String productId) async {
    try {
      final response = await _supabase
          .from('product_variants')
          .select()
          .eq('product_id', productId)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);
      return (response as List)
          .map((json) => ProductVariant.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch variants: $e');
    }
  }

  @override
  Future<List<ProductVariant>> getColorVariants(String productId) async {
    try {
      final response = await _supabase
          .from('product_variants')
          .select()
          .eq('product_id', productId)
          .eq('variant_type', 'color')
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);
      return (response as List)
          .map((json) => ProductVariant.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch color variants: $e');
    }
  }

  @override
  Future<List<ProductVariant>> getLayoutVariants(String productId) async {
    try {
      final response = await _supabase
          .from('product_variants')
          .select()
          .eq('product_id', productId)
          .eq('variant_type', 'layout')
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);
      return (response as List)
          .map((json) => ProductVariant.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch layout variants: $e');
    }
  }

  @override
  Future<List<ProductVariantImage>> getVariantImages(String productId) async {
    try {
      final response = await _supabase
          .from('product_variant_images')
          .select()
          .eq('product_id', productId)
          .order('created_at', ascending: true);
      return (response as List)
          .map((json) => ProductVariantImage.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch variant images: $e');
    }
  }

  @override
  Future<void> updateTransparentImageUrl(String imageId, String url) async {
    try {
      await _supabase
          .from('product_variant_images')
          .update({'transparent_image_url': url})
          .eq('id', imageId);
    } catch (e) {
      throw ServerException('Failed to update transparent image URL: $e');
    }
  }
}

final userProductVariantRepositoryProvider = Provider<ProductVariantRepository>((ref) {
  return SupabaseProductVariantRepository(Supabase.instance.client);
});

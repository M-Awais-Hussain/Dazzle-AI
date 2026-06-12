import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/core/config/env_config.dart';
import 'package:ayyy/features/marketplace_owner/domain/product_variant.dart';
import 'package:ayyy/features/marketplace_owner/domain/product_variant_image.dart';
import 'package:ayyy/core/errors/exceptions.dart';

abstract class ProductVariantRepository {
  Future<List<ProductVariant>> getVariantsForProduct(String productId);
  Future<List<ProductVariant>> getVariantsByType(String productId, String variantType);
  Future<ProductVariant> createVariant(Map<String, dynamic> data);
  Future<ProductVariant> updateVariant(String id, Map<String, dynamic> data);
  Future<void> deleteVariant(String id);
  Future<List<ProductVariantImage>> getVariantImages(String productId);
  Future<ProductVariantImage> createVariantImage(Map<String, dynamic> data);
  Future<void> deleteVariantImage(String id);
  Future<String> uploadVariantImageFile(String productId, XFile file);
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
  Future<List<ProductVariant>> getVariantsByType(String productId, String variantType) async {
    try {
      final response = await _supabase
          .from('product_variants')
          .select()
          .eq('product_id', productId)
          .eq('variant_type', variantType)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);
      return (response as List)
          .map((json) => ProductVariant.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch variants by type: $e');
    }
  }

  @override
  Future<ProductVariant> createVariant(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('product_variants')
          .insert(data)
          .select()
          .single();
      return ProductVariant.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to create variant: $e');
    }
  }

  @override
  Future<ProductVariant> updateVariant(String id, Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('product_variants')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return ProductVariant.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to update variant: $e');
    }
  }

  @override
  Future<void> deleteVariant(String id) async {
    try {
      await _supabase.from('product_variants').delete().eq('id', id);
    } catch (e) {
      throw ServerException('Failed to delete variant: $e');
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
  Future<ProductVariantImage> createVariantImage(Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('product_variant_images')
          .insert(data)
          .select()
          .single();
      return ProductVariantImage.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to create variant image: $e');
    }
  }

  @override
  Future<void> deleteVariantImage(String id) async {
    try {
      await _supabase.from('product_variant_images').delete().eq('id', id);
    } catch (e) {
      throw ServerException('Failed to delete variant image: $e');
    }
  }

  @override
  Future<String> uploadVariantImageFile(String productId, XFile file) async {
    try {
      try {
        await _supabase.storage.createBucket('product-images', const BucketOptions(public: true));
      } catch (_) {
        // Ignore if bucket already exists
      }

      final fileExt = file.name.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'variants/$productId/$timestamp.$fileExt';
      final bytes = await file.readAsBytes();

      await _supabase.storage.from('product-images').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      return _supabase.storage.from('product-images').getPublicUrl(path);
    } catch (e) {
      throw ServerException('Failed to upload variant image: $e');
    }
  }
}

final ownerProductVariantRepositoryProvider = Provider<ProductVariantRepository>((ref) {
  final secretKey = EnvConfig.supabaseSecretKey;
  final client = secretKey.isNotEmpty
      ? SupabaseClient(EnvConfig.supabaseUrl, secretKey)
      : Supabase.instance.client;
  return SupabaseProductVariantRepository(client);
});

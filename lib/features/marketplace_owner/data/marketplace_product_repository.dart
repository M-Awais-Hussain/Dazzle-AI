import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/core/config/env_config.dart';
import 'package:ayyy/features/marketplace_owner/domain/marketplace_product.dart';
import 'package:ayyy/core/errors/exceptions.dart';

abstract class MarketplaceProductRepository {
  Future<List<MarketplaceProduct>> getOwnerProducts(String ownerId);
  Future<MarketplaceProduct> getProductById(String id);
  Future<MarketplaceProduct> createProduct(Map<String, dynamic> data);
  Future<MarketplaceProduct> updateProduct(String id, Map<String, dynamic> data);
  Future<void> deleteProduct(String id);
  Future<String> uploadProductImage(String productId, XFile file, int index);
  Future<void> deleteProductImage(String path);
  Future<void> toggleFeatured(String id, bool isFeatured);
}

class SupabaseMarketplaceProductRepository implements MarketplaceProductRepository {
  final SupabaseClient _supabase;

  SupabaseMarketplaceProductRepository(this._supabase);

  @override
  Future<List<MarketplaceProduct>> getOwnerProducts(String ownerId) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('shopkeeper_id', ownerId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => MarketplaceProduct.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch products: $e');
    }
  }

  @override
  Future<MarketplaceProduct> getProductById(String id) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('id', id)
          .single();
      return MarketplaceProduct.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to fetch product: $e');
    }
  }

  @override
  Future<MarketplaceProduct> createProduct(Map<String, dynamic> data) async {
    try {
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();
      // Ensure name is synced with title for backward compatibility
      if (data['title'] != null && data['name'] == null) {
        data['name'] = data['title'];
      }
      final response = await _supabase
          .from('products')
          .insert(data)
          .select()
          .single();
      return MarketplaceProduct.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to create product: $e');
    }
  }

  @override
  Future<MarketplaceProduct> updateProduct(String id, Map<String, dynamic> data) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();
      if (data['title'] != null) {
        data['name'] = data['title'];
      }
      final response = await _supabase
          .from('products')
          .update(data)
          .eq('id', id)
          .select()
          .single();
      return MarketplaceProduct.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to update product: $e');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await _supabase.from('products').delete().eq('id', id);
    } catch (e) {
      throw ServerException('Failed to delete product: $e');
    }
  }

  @override
  Future<String> uploadProductImage(String productId, XFile file, int index) async {
    try {
      // Auto-create bucket 'product-images' with public read permissions
      try {
        await _supabase.storage.createBucket('product-images', const BucketOptions(public: true));
      } catch (_) {
        // Ignore if bucket already exists
      }

      final fileExt = file.name.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'products/$productId/${timestamp}_$index.$fileExt';
      final bytes = await file.readAsBytes();

      await _supabase.storage.from('product-images').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      return _supabase.storage.from('product-images').getPublicUrl(path);
    } catch (e) {
      throw ServerException('Failed to upload product image: $e');
    }
  }

  @override
  Future<void> deleteProductImage(String path) async {
    try {
      await _supabase.storage.from('product-images').remove([path]);
    } catch (e) {
      throw ServerException('Failed to delete product image: $e');
    }
  }

  @override
  Future<void> toggleFeatured(String id, bool isFeatured) async {
    try {
      await _supabase
          .from('products')
          .update({'is_featured': isFeatured, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw ServerException('Failed to toggle featured: $e');
    }
  }
}

final marketplaceProductRepositoryProvider = Provider<MarketplaceProductRepository>((ref) {
  final secretKey = EnvConfig.supabaseSecretKey;
  final client = secretKey.isNotEmpty
      ? SupabaseClient(EnvConfig.supabaseUrl, secretKey)
      : Supabase.instance.client;
  return SupabaseMarketplaceProductRepository(client);
});

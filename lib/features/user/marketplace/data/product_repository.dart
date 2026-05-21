import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/user/marketplace/domain/product.dart';
import 'package:ayyy/core/errors/exceptions.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts();
  Future<Product> getProductById(String id);
  Future<List<Product>> getProductsByShopkeeper(String shopkeeperId);
}

class SupabaseProductRepository implements ProductRepository {
  final SupabaseClient _supabase;

  SupabaseProductRepository(this._supabase);

  @override
  Future<List<Product>> getProducts() async {
    try {
      final response = await _supabase.from('products').select();
      return (response as List).map((json) {
        final map = Map<String, dynamic>.from(json as Map);
        if (map['owner_id'] == null) {
          map['owner_id'] = map['shopkeeper_id'];
        }
        if (map['marketplace_profile_id'] == null) {
          map['marketplace_profile_id'] = map['shopkeeper_id'];
        }
        return Product.fromJson(map);
      }).toList();
    } catch (e) {
      throw ServerException('Failed to fetch products: $e');
    }
  }

  @override
  Future<Product> getProductById(String id) async {
    try {
      final response = await _supabase.from('products').select().eq('id', id).single();
      final map = Map<String, dynamic>.from(response);
      if (map['owner_id'] == null) {
        map['owner_id'] = map['shopkeeper_id'];
      }
      if (map['marketplace_profile_id'] == null) {
        map['marketplace_profile_id'] = map['shopkeeper_id'];
      }
      return Product.fromJson(map);
    } catch (e) {
      throw ServerException('Failed to fetch product: $e');
    }
  }

  @override
  Future<List<Product>> getProductsByShopkeeper(String shopkeeperId) async {
    try {
      final response = await _supabase.from('products').select().eq('shopkeeper_id', shopkeeperId);
      return (response as List).map((json) {
        final map = Map<String, dynamic>.from(json as Map);
        if (map['owner_id'] == null) {
          map['owner_id'] = map['shopkeeper_id'];
        }
        if (map['marketplace_profile_id'] == null) {
          map['marketplace_profile_id'] = map['shopkeeper_id'];
        }
        return Product.fromJson(map);
      }).toList();
    } catch (e) {
      throw ServerException('Failed to fetch shopkeeper products: $e');
    }
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return SupabaseProductRepository(Supabase.instance.client);
});

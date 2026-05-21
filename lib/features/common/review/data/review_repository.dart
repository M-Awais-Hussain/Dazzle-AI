import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/review.dart';
import 'package:ayyy/core/errors/exceptions.dart';

abstract class ReviewRepository {
  Future<List<DesignerReview>> getDesignerReviews(String designerId);
  Future<List<ProductReview>> getProductReviews(String productId);
  Future<void> submitDesignerReview(DesignerReview review);
  Future<void> submitProductReview(ProductReview review);
  Future<bool> hasUserReviewedRequest(String requestId);
  Future<bool> hasUserReviewedProductInOrder(String orderId, String productId);
}

class SupabaseReviewRepository implements ReviewRepository {
  final SupabaseClient _supabase;

  SupabaseReviewRepository(this._supabase);

  @override
  Future<List<DesignerReview>> getDesignerReviews(String designerId) async {
    try {
      final response = await _supabase
          .from('designer_reviews')
          .select('*, profiles:profiles!user_id(full_name, avatar_url)')
          .eq('designer_id', designerId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => DesignerReview.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch designer reviews: $e');
    }
  }

  @override
  Future<List<ProductReview>> getProductReviews(String productId) async {
    try {
      final response = await _supabase
          .from('product_reviews')
          .select('*, profiles:profiles!user_id(full_name, avatar_url)')
          .eq('product_id', productId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => ProductReview.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch product reviews: $e');
    }
  }

  @override
  Future<void> submitDesignerReview(DesignerReview review) async {
    try {
      await _supabase
          .from('designer_reviews')
          .insert(review.toJson());
    } catch (e) {
      throw ServerException('Failed to submit designer review: $e');
    }
  }

  @override
  Future<void> submitProductReview(ProductReview review) async {
    try {
      await _supabase
          .from('product_reviews')
          .insert(review.toJson());
    } catch (e) {
      throw ServerException('Failed to submit product review: $e');
    }
  }

  @override
  Future<bool> hasUserReviewedRequest(String requestId) async {
    try {
      final response = await _supabase
          .from('designer_reviews')
          .select('id')
          .eq('request_id', requestId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      // If error occurs or table is not created yet, default to false to allow attempt
      return false;
    }
  }

  @override
  Future<bool> hasUserReviewedProductInOrder(String orderId, String productId) async {
    try {
      final response = await _supabase
          .from('product_reviews')
          .select('id')
          .eq('order_id', orderId)
          .eq('product_id', productId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return SupabaseReviewRepository(Supabase.instance.client);
});

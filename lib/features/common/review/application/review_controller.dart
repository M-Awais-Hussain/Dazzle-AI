import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/review_repository.dart';
import '../domain/review.dart';

/// Key structure for looking up product reviews in specific orders
class ProductOrderReviewKey {
  final String orderId;
  final String productId;

  ProductOrderReviewKey({required this.orderId, required this.productId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductOrderReviewKey &&
          runtimeType == other.runtimeType &&
          orderId == other.orderId &&
          productId == other.productId;

  @override
  int get hashCode => orderId.hashCode ^ productId.hashCode;
}

/// Provider for list of reviews of a designer
final designerReviewsProvider = FutureProvider.family<List<DesignerReview>, String>((ref, designerId) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getDesignerReviews(designerId);
});

/// Provider for dynamic rating stats of a designer (calculated from their reviews list)
final designerRatingStatsProvider = Provider.family<RatingStats, String>((ref, designerId) {
  final reviewsAsync = ref.watch(designerReviewsProvider(designerId));
  return reviewsAsync.maybeWhen(
    data: (list) => RatingStats.calculate(list.map((r) => r.rating).toList()),
    orElse: () => RatingStats.empty(),
  );
});

/// Provider for list of reviews of a product
final productReviewsProvider = FutureProvider.family<List<ProductReview>, String>((ref, productId) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.getProductReviews(productId);
});

/// Provider for dynamic rating stats of a product (calculated from its reviews list)
final productRatingStatsProvider = Provider.family<RatingStats, String>((ref, productId) {
  final reviewsAsync = ref.watch(productReviewsProvider(productId));
  return reviewsAsync.maybeWhen(
    data: (list) => RatingStats.calculate(list.map((r) => r.rating).toList()),
    orElse: () => RatingStats.empty(),
  );
});

/// Provider to check if a designer request has already been reviewed
final hasUserReviewedRequestProvider = FutureProvider.family<bool, String>((ref, requestId) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.hasUserReviewedRequest(requestId);
});

/// Provider to check if a product has already been reviewed inside an order
final hasUserReviewedProductInOrderProvider = FutureProvider.family<bool, ProductOrderReviewKey>((ref, key) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.hasUserReviewedProductInOrder(key.orderId, key.productId);
});

/// State notifier controller for review submissions using Notifier
class ReviewSubmissionController extends Notifier<AsyncValue<void>> {
  late ReviewRepository _repository;

  @override
  AsyncValue<void> build() {
    _repository = ref.watch(reviewRepositoryProvider);
    return const AsyncData(null);
  }

  /// Submit a designer review
  Future<bool> submitDesignerReview({
    required String designerId,
    required String requestId,
    required int rating,
    required String reviewText,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = AsyncError('User not logged in', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    try {
      final review = DesignerReview(
        id: '',
        userId: user.id,
        designerId: designerId,
        requestId: requestId,
        rating: rating,
        review: reviewText,
        createdAt: DateTime.now(),
      );
      
      await _repository.submitDesignerReview(review);

      // Invalidate related review list cache and verification caches
      ref.invalidate(designerReviewsProvider(designerId));
      ref.invalidate(hasUserReviewedRequestProvider(requestId));

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Submit a product review
  Future<bool> submitProductReview({
    required String productId,
    required String orderId,
    required int rating,
    required String reviewText,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = AsyncError('User not logged in', StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    try {
      final review = ProductReview(
        id: '',
        productId: productId,
        userId: user.id,
        orderId: orderId,
        rating: rating,
        review: reviewText,
        createdAt: DateTime.now(),
      );

      await _repository.submitProductReview(review);

      // Invalidate related review list cache and verification caches
      ref.invalidate(productReviewsProvider(productId));
      ref.invalidate(hasUserReviewedProductInOrderProvider(
        ProductOrderReviewKey(orderId: orderId, productId: productId),
      ));

      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

/// Provider for managing review submission operations
final reviewSubmissionControllerProvider =
    NotifierProvider<ReviewSubmissionController, AsyncValue<void>>(() {
  return ReviewSubmissionController();
});

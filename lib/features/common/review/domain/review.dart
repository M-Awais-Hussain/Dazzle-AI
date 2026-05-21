class DesignerReview {
  final String id;
  final String userId;
  final String designerId;
  final String requestId;
  final int rating;
  final String review;
  final DateTime createdAt;
  
  // Joined reviewer info (optional, populated via joins)
  final String? reviewerName;
  final String? reviewerAvatarUrl;

  DesignerReview({
    required this.id,
    required this.userId,
    required this.designerId,
    required this.requestId,
    required this.rating,
    required this.review,
    required this.createdAt,
    this.reviewerName,
    this.reviewerAvatarUrl,
  });

  factory DesignerReview.fromJson(Map<String, dynamic> json) {
    // Resolve joined profiles table info
    final profile = json['profiles'] as Map<String, dynamic>?;
    final rName = profile != null ? profile['full_name'] as String? : json['reviewer_name'] as String?;
    final rAvatar = profile != null ? profile['avatar_url'] as String? : json['reviewer_avatar_url'] as String?;

    return DesignerReview(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      designerId: json['designer_id'] as String? ?? '',
      requestId: json['request_id'] as String? ?? '',
      rating: json['rating'] as int? ?? 5,
      review: json['review'] as String? ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      reviewerName: rName ?? 'Client Reviewer',
      reviewerAvatarUrl: rAvatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'designer_id': designerId,
      'request_id': requestId,
      'rating': rating,
      'review': review,
    };
  }
}

class ProductReview {
  final String id;
  final String productId;
  final String userId;
  final String orderId;
  final int rating;
  final String review;
  final DateTime createdAt;

  // Joined reviewer info (optional, populated via joins)
  final String? reviewerName;
  final String? reviewerAvatarUrl;

  ProductReview({
    required this.id,
    required this.productId,
    required this.userId,
    required this.orderId,
    required this.rating,
    required this.review,
    required this.createdAt,
    this.reviewerName,
    this.reviewerAvatarUrl,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    // Resolve joined profiles table info
    final profile = json['profiles'] as Map<String, dynamic>?;
    final rName = profile != null ? profile['full_name'] as String? : json['reviewer_name'] as String?;
    final rAvatar = profile != null ? profile['avatar_url'] as String? : json['reviewer_avatar_url'] as String?;

    return ProductReview(
      id: json['id'] as String? ?? '',
      productId: json['product_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      rating: json['rating'] as int? ?? 5,
      review: json['review'] as String? ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      reviewerName: rName ?? 'Verified Buyer',
      reviewerAvatarUrl: rAvatar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'product_id': productId,
      'user_id': userId,
      'order_id': orderId,
      'rating': rating,
      'review': review,
    };
  }
}

class RatingStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> starBreakdown;

  RatingStats({
    required this.averageRating,
    required this.totalReviews,
    required this.starBreakdown,
  });

  factory RatingStats.empty() {
    return RatingStats(
      averageRating: 0.0,
      totalReviews: 0,
      starBreakdown: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
    );
  }

  factory RatingStats.calculate(List<int> ratings) {
    if (ratings.isEmpty) {
      return RatingStats.empty();
    }

    final total = ratings.length;
    final sum = ratings.reduce((a, b) => a + b);
    final average = sum / total;

    final breakdown = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var r in ratings) {
      if (breakdown.containsKey(r)) {
        breakdown[r] = breakdown[r]! + 1;
      }
    }

    return RatingStats(
      averageRating: average,
      totalReviews: total,
      starBreakdown: breakdown,
    );
  }
}

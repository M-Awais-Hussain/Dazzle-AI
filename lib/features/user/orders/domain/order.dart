import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ayyy/features/user/marketplace/domain/cart_item.dart';

part 'order.freezed.dart';
part 'order.g.dart';

enum OrderStatus {
  @JsonValue('Pending') pending,
  @JsonValue('Confirmed') confirmed,
  @JsonValue('Shipped') shipped,
  @JsonValue('Delivered') delivered,
  @JsonValue('Cancelled') cancelled,
}

@freezed
abstract class Order with _$Order {
  const factory Order({
    required String id,
    @JsonKey(name: 'order_number') required String orderNumber,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'shipping_address') required String shippingAddress,
    @JsonKey(name: 'phone_number') required String phoneNumber,
    @JsonKey(name: 'total_amount') required double totalAmount,
    @JsonKey(name: 'payment_method') required String paymentMethod,
    required OrderStatus status,
    required List<CartItem> items,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'marketplace_owner_id') String? marketplaceOwnerId,
    @JsonKey(name: 'product_id') String? productId,
  }) = _Order;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}

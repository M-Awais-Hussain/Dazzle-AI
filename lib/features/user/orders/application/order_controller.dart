import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/user/orders/data/order_repository.dart';
import 'package:ayyy/features/user/orders/domain/order.dart';
import 'package:ayyy/features/user/marketplace/application/cart_controller.dart';

class OrderController extends AsyncNotifier<List<Order>> {
  @override
  Future<List<Order>> build() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    return ref.read(orderRepositoryProvider).getUserOrders(user.id);
  }

  Future<String?> placeOrder({
    required String address,
    required String phone,
    required double totalAmount,
  }) async {
    state = const AsyncLoading();
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final cartItems = ref.read(cartControllerProvider).items;
      if (cartItems.isEmpty) throw Exception('Cart is empty');

      String? firstOrderNumber;

      for (final item in cartItems) {
        final product = item.product;
        // Build the insert map for each product individually
        final orderData = {
          'user_id': user.id,
          'shipping_address': address,
          'phone_number': phone,
          'total_amount': product.price * item.quantity,
          'payment_method': 'COD',
          'status': 'Pending',
          'items': [item.toJson()],
          'marketplace_owner_id': product.ownerId,
          'product_id': product.id,
        };

        final createdOrder = await ref.read(orderRepositoryProvider).createOrder(orderData);
        firstOrderNumber ??= createdOrder.orderNumber;
      }

      // Clear cart after successful checkout
      ref.read(cartControllerProvider.notifier).clearCart();

      // Refresh orders list
      ref.invalidateSelf();

      return firstOrderNumber;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    try {
      // Map the enum to its JSON string value
      final statusString = switch (status) {
        OrderStatus.pending => 'Pending',
        OrderStatus.confirmed => 'Confirmed',
        OrderStatus.shipped => 'Shipped',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };
      await ref.read(orderRepositoryProvider).updateOrderStatus(orderId, statusString);
      ref.invalidateSelf();
    } catch (e) {
      // Handle error
    }
  }
}

final orderControllerProvider = AsyncNotifierProvider<OrderController, List<Order>>(() {
  return OrderController();
});

final allOrdersProvider = FutureProvider<List<Order>>((ref) async {
  return ref.read(orderRepositoryProvider).getAllOrders();
});

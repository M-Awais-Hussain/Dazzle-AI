import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayyy/features/marketplace_owner/data/marketplace_order_repository.dart';
import 'package:ayyy/features/user/orders/domain/order.dart';

/// All marketplace orders provider
final marketplaceOrdersProvider = FutureProvider<List<Order>>((ref) async {
  final repo = ref.watch(marketplaceOrderRepositoryProvider);
  return repo.getAllOrders();
});

/// Pending orders count provider
final pendingOrdersCountProvider = Provider<int>((ref) {
  final ordersAsync = ref.watch(marketplaceOrdersProvider);
  return ordersAsync.when(
    data: (orders) => orders.where((o) => o.status == OrderStatus.pending).length,
    loading: () => 0,
    error: (e, s) => 0,
  );
});

/// Order stats provider (totals, revenue, etc.)
final orderStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(marketplaceOrderRepositoryProvider);
  return repo.getOrderStats();
});

/// Controller for marketplace order management
class MarketplaceOrderController extends AsyncNotifier<List<Order>> {
  late MarketplaceOrderRepository _repo;

  @override
  Future<List<Order>> build() async {
    _repo = ref.watch(marketplaceOrderRepositoryProvider);
    return _repo.getAllOrders();
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    try {
      final statusString = switch (status) {
        OrderStatus.pending => 'Pending',
        OrderStatus.confirmed => 'Confirmed',
        OrderStatus.shipped => 'Shipped',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };
      await _repo.updateOrderStatus(orderId, statusString);
      ref.invalidateSelf();
      ref.invalidate(marketplaceOrdersProvider);
      ref.invalidate(orderStatsProvider);
    } catch (e) {
      debugPrint('[MarketplaceOrderController] Error updating status: $e');
    }
  }

  Future<void> refreshOrders() async {
    ref.invalidateSelf();
  }
}

final marketplaceOrderControllerProvider =
    AsyncNotifierProvider<MarketplaceOrderController, List<Order>>(() {
  return MarketplaceOrderController();
});

/// Filtered orders by status tab
final filteredOrdersProvider = Provider.family<List<Order>, String?>((ref, statusFilter) {
  final ordersAsync = ref.watch(marketplaceOrderControllerProvider);
  return ordersAsync.when(
    data: (orders) {
      if (statusFilter == null || statusFilter == 'All') return orders;
      return orders.where((o) => o.status.name.toLowerCase() == statusFilter.toLowerCase()).toList();
    },
    loading: () => [],
    error: (e, s) => [],
  );
});

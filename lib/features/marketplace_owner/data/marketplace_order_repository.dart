import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/user/orders/domain/order.dart';
import 'package:ayyy/core/errors/exceptions.dart';

/// Repository for marketplace owner order management.
/// Marketplace owners see ALL orders (enforced by RLS policies).
abstract class MarketplaceOrderRepository {
  Future<List<Order>> getAllOrders();
  Future<List<Order>> getOrdersByStatus(String status);
  Future<void> updateOrderStatus(String orderId, String status);
  Future<Map<String, dynamic>> getOrderStats();
}

class SupabaseMarketplaceOrderRepository implements MarketplaceOrderRepository {
  final SupabaseClient _supabase;

  SupabaseMarketplaceOrderRepository(this._supabase);

  @override
  Future<List<Order>> getAllOrders() async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .order('created_at', ascending: false);
      return (response as List).map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch orders: $e');
    }
  }

  @override
  Future<List<Order>> getOrdersByStatus(String status) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('status', status)
          .order('created_at', ascending: false);
      return (response as List).map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch orders by status: $e');
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': status})
          .eq('id', orderId);
    } catch (e) {
      throw ServerException('Failed to update order status: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getOrderStats() async {
    try {
      final allOrders = await getAllOrders();

      final totalOrders = allOrders.length;
      final pendingOrders = allOrders.where((o) => o.status == OrderStatus.pending).length;
      final totalRevenue = allOrders
          .where((o) => o.status == OrderStatus.delivered)
          .fold<double>(0, (sum, o) => sum + o.totalAmount);

      // Monthly revenue (current month)
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthlyRevenue = allOrders
          .where((o) =>
              o.createdAt.isAfter(monthStart) &&
              o.status == OrderStatus.delivered)
          .fold<double>(0, (sum, o) => sum + o.totalAmount);

      return {
        'total_orders': totalOrders,
        'pending_orders': pendingOrders,
        'total_revenue': totalRevenue,
        'monthly_revenue': monthlyRevenue,
      };
    } catch (e) {
      throw ServerException('Failed to compute order stats: $e');
    }
  }
}

final marketplaceOrderRepositoryProvider = Provider<MarketplaceOrderRepository>((ref) {
  return SupabaseMarketplaceOrderRepository(Supabase.instance.client);
});

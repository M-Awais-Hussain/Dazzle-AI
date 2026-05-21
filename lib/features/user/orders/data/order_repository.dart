import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/user/orders/domain/order.dart';
import 'package:ayyy/core/errors/exceptions.dart';

abstract class OrderRepository {
  Future<List<Order>> getUserOrders(String userId);
  Future<Order> createOrder(Map<String, dynamic> orderData);
  Future<List<Order>> getAllOrders();
  Future<void> updateOrderStatus(String orderId, String status);
}

class SupabaseOrderRepository implements OrderRepository {
  final SupabaseClient _supabase;

  SupabaseOrderRepository(this._supabase);

  @override
  Future<List<Order>> getUserOrders(String userId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (response as List).map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch orders: $e');
    }
  }

  @override
  Future<Order> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await _supabase
          .from('orders')
          .insert(orderData)
          .select()
          .single();
      return Order.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to create order: $e');
    }
  }

  @override
  Future<List<Order>> getAllOrders() async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .order('created_at', ascending: false);
      return (response as List).map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch all orders: $e');
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
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return SupabaseOrderRepository(Supabase.instance.client);
});

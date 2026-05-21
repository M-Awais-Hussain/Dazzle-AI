import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/marketplace_owner/domain/analytics_metric.dart';
import 'package:ayyy/features/user/orders/domain/order.dart';
import 'package:ayyy/core/errors/exceptions.dart';

/// Repository for marketplace analytics — computes sales data, revenue growth,
/// and product performance from orders table.
abstract class MarketplaceAnalyticsRepository {
  Future<List<SalesDataPoint>> getDailySales(int days);
  Future<List<SalesDataPoint>> getWeeklySales(int weeks);
  Future<List<SalesDataPoint>> getMonthlySales(int months);
  Future<List<Map<String, dynamic>>> getTopProducts(int limit);
  Future<Map<String, double>> getRevenueGrowth();
}

class SupabaseMarketplaceAnalyticsRepository implements MarketplaceAnalyticsRepository {
  final SupabaseClient _supabase;

  SupabaseMarketplaceAnalyticsRepository(this._supabase);

  Future<List<Order>> _fetchAllOrders() async {
    try {
      final response = await _supabase
          .from('orders')
          .select()
          .order('created_at', ascending: true);
      return (response as List).map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch orders for analytics: $e');
    }
  }

  @override
  Future<List<SalesDataPoint>> getDailySales(int days) async {
    final orders = await _fetchAllOrders();
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));

    final Map<String, SalesDataPoint> dailyMap = {};

    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      dailyMap[key] = SalesDataPoint(date: date, amount: 0, orderCount: 0);
    }

    for (final order in orders) {
      if (order.createdAt.isAfter(startDate)) {
        final key = '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}-${order.createdAt.day.toString().padLeft(2, '0')}';
        if (dailyMap.containsKey(key)) {
          final existing = dailyMap[key]!;
          dailyMap[key] = SalesDataPoint(
            date: existing.date,
            amount: existing.amount + order.totalAmount,
            orderCount: existing.orderCount + 1,
          );
        }
      }
    }

    return dailyMap.values.toList();
  }

  @override
  Future<List<SalesDataPoint>> getWeeklySales(int weeks) async {
    final orders = await _fetchAllOrders();
    final now = DateTime.now();
    final List<SalesDataPoint> weeklyData = [];

    for (int i = weeks - 1; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: (i + 1) * 7));
      final weekEnd = now.subtract(Duration(days: i * 7));

      double total = 0;
      int count = 0;
      for (final order in orders) {
        if (order.createdAt.isAfter(weekStart) && order.createdAt.isBefore(weekEnd)) {
          total += order.totalAmount;
          count++;
        }
      }
      weeklyData.add(SalesDataPoint(date: weekEnd, amount: total, orderCount: count));
    }

    return weeklyData;
  }

  @override
  Future<List<SalesDataPoint>> getMonthlySales(int months) async {
    final orders = await _fetchAllOrders();
    final now = DateTime.now();
    final List<SalesDataPoint> monthlyData = [];

    for (int i = months - 1; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);

      double total = 0;
      int count = 0;
      for (final order in orders) {
        if (order.createdAt.isAfter(monthDate) && order.createdAt.isBefore(nextMonth)) {
          total += order.totalAmount;
          count++;
        }
      }
      monthlyData.add(SalesDataPoint(date: monthDate, amount: total, orderCount: count));
    }

    return monthlyData;
  }

  @override
  Future<List<Map<String, dynamic>>> getTopProducts(int limit) async {
    final orders = await _fetchAllOrders();
    final Map<String, Map<String, dynamic>> productSales = {};

    for (final order in orders) {
      for (final item in order.items) {
        final productId = item.product.id;
        if (!productSales.containsKey(productId)) {
          productSales[productId] = {
            'product_id': productId,
            'product_name': item.product.name,
            'total_sold': 0,
            'total_revenue': 0.0,
          };
        }
        productSales[productId]!['total_sold'] =
            (productSales[productId]!['total_sold'] as int) + item.quantity;
        productSales[productId]!['total_revenue'] =
            (productSales[productId]!['total_revenue'] as double) +
                (item.product.price * item.quantity);
      }
    }

    final sorted = productSales.values.toList()
      ..sort((a, b) => (b['total_sold'] as int).compareTo(a['total_sold'] as int));

    return sorted.take(limit).toList();
  }

  @override
  Future<Map<String, double>> getRevenueGrowth() async {
    final orders = await _fetchAllOrders();
    final now = DateTime.now();

    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    double thisMonthRevenue = 0;
    double lastMonthRevenue = 0;

    for (final order in orders) {
      if (order.createdAt.isAfter(thisMonthStart)) {
        thisMonthRevenue += order.totalAmount;
      } else if (order.createdAt.isAfter(lastMonthStart) &&
          order.createdAt.isBefore(thisMonthStart)) {
        lastMonthRevenue += order.totalAmount;
      }
    }

    final growthPercent = lastMonthRevenue > 0
        ? ((thisMonthRevenue - lastMonthRevenue) / lastMonthRevenue) * 100
        : 0.0;

    return {
      'this_month': thisMonthRevenue,
      'last_month': lastMonthRevenue,
      'growth_percent': growthPercent,
    };
  }
}

final marketplaceAnalyticsRepositoryProvider = Provider<MarketplaceAnalyticsRepository>((ref) {
  return SupabaseMarketplaceAnalyticsRepository(Supabase.instance.client);
});

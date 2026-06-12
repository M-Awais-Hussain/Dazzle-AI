import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayyy/features/marketplace_owner/domain/analytics_metric.dart';
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
  SupabaseMarketplaceAnalyticsRepository();


  @override
  Future<List<SalesDataPoint>> getDailySales(int days) async {
    return [];
  }

  @override
  Future<List<SalesDataPoint>> getWeeklySales(int weeks) async {
    return [];
  }

  @override
  Future<List<SalesDataPoint>> getMonthlySales(int months) async {
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getTopProducts(int limit) async {
    return [];
  }

  @override
  Future<Map<String, double>> getRevenueGrowth() async {
    return {
      'this_month': 0.0,
      'last_month': 0.0,
      'growth_percent': 0.0,
    };
  }
}

final marketplaceAnalyticsRepositoryProvider = Provider<MarketplaceAnalyticsRepository>((ref) {
  return SupabaseMarketplaceAnalyticsRepository();
});

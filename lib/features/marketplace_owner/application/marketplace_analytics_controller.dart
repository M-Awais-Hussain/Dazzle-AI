import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayyy/features/marketplace_owner/data/marketplace_analytics_repository.dart';
import 'package:ayyy/features/marketplace_owner/domain/analytics_metric.dart';

/// Selected time range for analytics views
enum AnalyticsTimeRange { daily, weekly, monthly }

class _AnalyticsTimeRangeNotifier extends Notifier<AnalyticsTimeRange> {
  @override
  AnalyticsTimeRange build() => AnalyticsTimeRange.monthly;
  void set(AnalyticsTimeRange value) => state = value;
}

final analyticsTimeRangeProvider = NotifierProvider<_AnalyticsTimeRangeNotifier, AnalyticsTimeRange>(() {
  return _AnalyticsTimeRangeNotifier();
});

/// Daily sales data provider
final dailySalesProvider = FutureProvider<List<SalesDataPoint>>((ref) async {
  final repo = ref.watch(marketplaceAnalyticsRepositoryProvider);
  return repo.getDailySales(30); // Last 30 days
});

/// Weekly sales data provider
final weeklySalesProvider = FutureProvider<List<SalesDataPoint>>((ref) async {
  final repo = ref.watch(marketplaceAnalyticsRepositoryProvider);
  return repo.getWeeklySales(12); // Last 12 weeks
});

/// Monthly sales data provider
final monthlySalesProvider = FutureProvider<List<SalesDataPoint>>((ref) async {
  final repo = ref.watch(marketplaceAnalyticsRepositoryProvider);
  return repo.getMonthlySales(12); // Last 12 months
});

/// Active sales data based on selected time range
final activeSalesDataProvider = Provider<AsyncValue<List<SalesDataPoint>>>((ref) {
  final range = ref.watch(analyticsTimeRangeProvider);
  return switch (range) {
    AnalyticsTimeRange.daily => ref.watch(dailySalesProvider),
    AnalyticsTimeRange.weekly => ref.watch(weeklySalesProvider),
    AnalyticsTimeRange.monthly => ref.watch(monthlySalesProvider),
  };
});

/// Top products provider
final topProductsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(marketplaceAnalyticsRepositoryProvider);
  return repo.getTopProducts(10);
});

/// Revenue growth provider
final revenueGrowthProvider = FutureProvider<Map<String, double>>((ref) async {
  final repo = ref.watch(marketplaceAnalyticsRepositoryProvider);
  return repo.getRevenueGrowth();
});

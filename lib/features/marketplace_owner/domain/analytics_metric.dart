import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_metric.freezed.dart';
part 'analytics_metric.g.dart';

@freezed
abstract class AnalyticsMetric with _$AnalyticsMetric {
  const factory AnalyticsMetric({
    required String id,
    @JsonKey(name: 'owner_id') required String ownerId,
    @JsonKey(name: 'metric_type') required String metricType,
    @JsonKey(name: 'metric_value') @Default({}) Map<String, dynamic> metricValue,
    @JsonKey(name: 'period_start') DateTime? periodStart,
    @JsonKey(name: 'period_end') DateTime? periodEnd,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _AnalyticsMetric;

  factory AnalyticsMetric.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsMetricFromJson(json);
}

/// Dashboard summary stats (computed, not from DB)
class DashboardStats {
  final int totalProducts;
  final int totalOrders;
  final double totalRevenue;
  final double monthlyRevenue;
  final int pendingOrders;
  final int lowStockCount;

  const DashboardStats({
    this.totalProducts = 0,
    this.totalOrders = 0,
    this.totalRevenue = 0,
    this.monthlyRevenue = 0,
    this.pendingOrders = 0,
    this.lowStockCount = 0,
  });
}

/// Sales data point for charting
class SalesDataPoint {
  final DateTime date;
  final double amount;
  final int orderCount;

  const SalesDataPoint({
    required this.date,
    required this.amount,
    this.orderCount = 0,
  });
}

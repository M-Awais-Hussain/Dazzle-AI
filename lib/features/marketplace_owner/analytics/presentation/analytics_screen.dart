import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/features/marketplace_owner/application/marketplace_analytics_controller.dart';
import 'package:ayyy/features/marketplace_owner/application/marketplace_order_controller.dart';
import 'package:ayyy/features/marketplace_owner/domain/analytics_metric.dart';
import 'package:ayyy/features/marketplace_owner/presentation/widgets/analytics_card.dart';
import 'package:ayyy/features/marketplace_owner/presentation/widgets/common_widgets.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeRange = ref.watch(analyticsTimeRangeProvider);
    final salesDataAsync = ref.watch(activeSalesDataProvider);
    final statsAsync = ref.watch(orderStatsProvider);
    final growthAsync = ref.watch(revenueGrowthProvider);
    final topProductsAsync = ref.watch(topProductsProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text('Analytics', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text('Track your marketplace performance', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 24),

              // Revenue Cards
              _buildRevenueCards(statsAsync, growthAsync),
              const SizedBox(height: 24),

              // Time Range Selector
              _TimeRangeSelector(
                selected: timeRange,
                onChanged: (range) => ref.read(analyticsTimeRangeProvider.notifier).set(range),
              ),
              const SizedBox(height: 16),

              // Sales Chart
              _buildSalesChart(salesDataAsync),
              const SizedBox(height: 28),

              // Top Products
              Text('Best Selling Products', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              _buildTopProducts(topProductsAsync),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueCards(AsyncValue<Map<String, dynamic>> statsAsync, AsyncValue<Map<String, double>> growthAsync) {
    return statsAsync.when(
      data: (stats) {
        final growthText = growthAsync.when(
          data: (g) {
            final pct = g['growth_percent'] ?? 0;
            return pct >= 0 ? '+${pct.toStringAsFixed(1)}%' : '${pct.toStringAsFixed(1)}%';
          },
          loading: () => '...',
          error: (e, s) => 'N/A',
        );
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: AnalyticsCard(
                  title: 'Total Revenue',
                  value: '\$${((stats['total_revenue'] as num?) ?? 0).toStringAsFixed(0)}',
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: AppColors.success,
                  subtitle: growthText,
                )),
                const SizedBox(width: 12),
                Expanded(child: AnalyticsCard(
                  title: 'Monthly Revenue',
                  value: '\$${((stats['monthly_revenue'] as num?) ?? 0).toStringAsFixed(0)}',
                  icon: Icons.trending_up,
                  iconColor: Colors.blue,
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: AnalyticsCard(
                  title: 'Total Orders',
                  value: '${stats['total_orders'] ?? 0}',
                  icon: Icons.receipt_long_outlined,
                  iconColor: AppColors.primary,
                )),
                const SizedBox(width: 12),
                Expanded(child: AnalyticsCard(
                  title: 'Pending Orders',
                  value: '${stats['pending_orders'] ?? 0}',
                  icon: Icons.pending_actions,
                  iconColor: Colors.orange,
                )),
              ],
            ),
          ],
        );
      },
      loading: () => const MarketplaceLoadingState(),
      error: (e, s) => const Center(child: Text('Unable to load stats')),
    );
  }

  Widget _buildSalesChart(AsyncValue<List<SalesDataPoint>> salesAsync) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: salesAsync.when(
        data: (dataPoints) {
          if (dataPoints.isEmpty) {
            return const Center(child: Text('No sales data available'));
          }
          final maxY = dataPoints.fold<double>(0, (max, p) => p.amount > max ? p.amount : max);
          return LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 0.5),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (val, _) => Text('\$${val.toInt()}', style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary)),
                )),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: dataPoints.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.amount)).toList(),
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 2.5,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
              minY: 0,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (e, s) => const Center(child: Text('Chart unavailable')),
      ),
    );
  }

  Widget _buildTopProducts(AsyncValue<List<Map<String, dynamic>>> topAsync) {
    return topAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return const MarketplaceEmptyState(
            icon: Icons.star_border,
            title: 'No Sales Data',
            subtitle: 'Product performance will appear after orders are placed.',
          );
        }
        return Column(
          children: products.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: idx < 3 ? AppColors.primary.withValues(alpha: 0.15) : const Color(0xFFF5F3EE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('#${idx + 1}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: idx < 3 ? AppColors.primary : AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['product_name'] ?? 'Product', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${p['total_sold']} sold', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Text('\$${(p['total_revenue'] as num).toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            );
          }).toList(),
        );
      },
      loading: () => const MarketplaceLoadingState(),
      error: (e, s) => const Center(child: Text('Unable to load')),
    );
  }
}

class _TimeRangeSelector extends StatelessWidget {
  final AnalyticsTimeRange selected;
  final ValueChanged<AnalyticsTimeRange> onChanged;

  const _TimeRangeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: AnalyticsTimeRange.values.map((range) {
        final isActive = range == selected;
        final label = switch (range) {
          AnalyticsTimeRange.daily => 'Daily',
          AnalyticsTimeRange.weekly => 'Weekly',
          AnalyticsTimeRange.monthly => 'Monthly',
        };
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(range),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
              ),
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

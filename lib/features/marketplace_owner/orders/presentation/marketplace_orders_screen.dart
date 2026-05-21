import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/features/marketplace_owner/application/marketplace_order_controller.dart';
import 'package:ayyy/features/marketplace_owner/presentation/widgets/order_tile.dart';
import 'package:ayyy/features/marketplace_owner/presentation/widgets/common_widgets.dart';
import 'package:ayyy/features/user/orders/domain/order.dart';

class MarketplaceOrdersScreen extends ConsumerStatefulWidget {
  const MarketplaceOrdersScreen({super.key});

  @override
  ConsumerState<MarketplaceOrdersScreen> createState() => _MarketplaceOrdersScreenState();
}

class _MarketplaceOrdersScreenState extends ConsumerState<MarketplaceOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = ['All', 'Pending', 'Confirmed', 'Shipped', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text('Orders', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            ),
            const SizedBox(height: 16),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                dividerHeight: 0,
                tabs: _tabs.map((t) => Tab(text: t.toUpperCase())).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Orders list
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) => _OrderTab(statusFilter: tab)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTab extends ConsumerWidget {
  final String statusFilter;
  const _OrderTab({required this.statusFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(marketplaceOrderControllerProvider);

    return ordersAsync.when(
      data: (orders) {
        List<Order> filtered;
        if (statusFilter == 'All') {
          filtered = orders;
        } else {
          filtered = orders.where((o) => o.status.name.toLowerCase() == statusFilter.toLowerCase()).toList();
        }

        if (filtered.isEmpty) {
          return MarketplaceEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No ${statusFilter == 'All' ? '' : '$statusFilter '}Orders',
            subtitle: statusFilter == 'All'
                ? 'Orders will appear here when customers make purchases.'
                : 'No orders with status "$statusFilter" found.',
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async => ref.invalidate(marketplaceOrderControllerProvider),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final order = filtered[index];
              return OrderTile(
                order: order,
                onStatusChanged: (status) {
                  ref.read(marketplaceOrderControllerProvider.notifier).updateStatus(order.id, status);
                },
              );
            },
          ),
        );
      },
      loading: () => const MarketplaceLoadingState(message: 'Loading orders...'),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayyy/core/widgets/dazzle_bottom_nav.dart';
import 'package:ayyy/features/marketplace_owner/dashboard/presentation/marketplace_dashboard_screen.dart';
import 'package:ayyy/features/marketplace_owner/products/presentation/products_list_screen.dart';
import 'package:ayyy/features/marketplace_owner/analytics/presentation/analytics_screen.dart';
import 'package:ayyy/features/marketplace_owner/profile/presentation/marketplace_profile_screen.dart';

/// Marketplace Shell — IndexedStack-based tab navigation
class MarketplaceShellScreen extends ConsumerWidget {
  const MarketplaceShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(marketplaceTabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          MarketplaceDashboardScreen(),
          ProductsListScreen(),
          AnalyticsScreen(),
          MarketplaceProfileScreen(),
        ],
      ),
      bottomNavigationBar: DazzleBottomNav(
        currentIndex: currentIndex,
      ),
    );
  }
}

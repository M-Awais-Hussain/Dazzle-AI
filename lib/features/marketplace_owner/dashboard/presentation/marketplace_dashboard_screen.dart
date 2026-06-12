import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/widgets/dazzle_app_bar.dart';
import 'package:ayyy/features/marketplace_owner/application/marketplace_profile_controller.dart';
import 'package:ayyy/features/marketplace_owner/application/marketplace_product_controller.dart';
import 'package:ayyy/features/marketplace_owner/presentation/widgets/analytics_card.dart';
import 'package:ayyy/features/marketplace_owner/presentation/widgets/common_widgets.dart';

class MarketplaceDashboardScreen extends ConsumerWidget {
  const MarketplaceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(marketplaceProfileControllerProvider);
    final productsAsync = ref.watch(marketplaceProductControllerProvider);

    final storeName = profileAsync.when(
      data: (p) => p?.storeName ?? 'Your Store',
      loading: () => 'Loading...',
      error: (e, s) => 'Your Store',
    );

    return Scaffold(
      appBar: const DazzleAppBar(),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(marketplaceProfileControllerProvider);
          ref.invalidate(marketplaceProductControllerProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Welcome Header
              Text(
                'Hello, $storeName',
                style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Your marketplace command center.\nManage products, orders & performance.',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),

              // Stats Cards
              _buildStatsSection(productsAsync),
              const SizedBox(height: 28),

              // Top Products
              _sectionHeader('Top Products'),
              const SizedBox(height: 12),
              _buildTopProducts(productsAsync),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
    );
  }

  Widget _buildStatsSection(
    AsyncValue productsAsync,
  ) {
    final totalProducts = productsAsync.when(
      data: (products) => (products as List).length,
      loading: () => 0,
      error: (e, s) => 0,
    );
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          CompactStatCard(title: 'Products', value: '$totalProducts', icon: Icons.inventory_2_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          CompactStatCard(title: 'Store Visits', value: '0', icon: Icons.people_outline, color: Colors.blue),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildTopProducts(AsyncValue productsAsync) {
    return productsAsync.when(
      data: (products) {
        final list = products as List;
        if (list.isEmpty) {
          return const MarketplaceEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No Products Yet',
            subtitle: 'Add your first product to get started.',
          );
        }
        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: list.length > 5 ? 5 : list.length,
            itemBuilder: (context, index) {
              final product = list[index];
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 70,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0EDE6),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: product.primaryImage != null && product.primaryImage!.isNotEmpty
                            ? Image.network(
                                product.primaryImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(child: Icon(Icons.broken_image, color: AppColors.textSecondary, size: 24)),
                              )
                            : const Center(child: Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 24)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        product.displayTitle,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/widgets/dazzle_app_bar.dart';
import 'package:ayyy/core/widgets/dazzle_bottom_nav.dart';
import 'package:ayyy/features/user/marketplace/application/product_controller.dart';

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final response = await Supabase.instance.client.from('categories').select();
    final names = (response as List).map((json) => json['name'] as String).toList();
    return ['All', ...names];
  } catch (e) {
    return ['All', 'Seating', 'Lighting', 'Tables', 'Decor'];
  }
});

final categoryMapProvider = FutureProvider<Map<String, String>>((ref) async {
  try {
    final response = await Supabase.instance.client.from('categories').select();
    return {for (var item in response as List) item['id'] as String: item['name'] as String};
  } catch (e) {
    return {};
  }
});

class MarketplaceHomeScreen extends ConsumerStatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  ConsumerState<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends ConsumerState<MarketplaceHomeScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(productsProvider);
    final categoriesState = ref.watch(categoriesProvider);
    final categoryMapState = ref.watch(categoryMapProvider);

    return Scaffold(
      appBar: DazzleAppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.textPrimary),
            onPressed: () => context.push('/marketplace/cart'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: const DazzleBottomNav(currentIndex: 1),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  // Subtitle
                  Text(
                    'CURATED BY DESIGN ENGINE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    'Curated Pieces',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category chips
                  categoriesState.when(
                    data: (categories) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedCategory = cat),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    loading: () => const SizedBox(height: 40),
                    error: (error, stackTrace) => const SizedBox(height: 40),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Product list (vertical cards with large images)
            productsState.when(
              data: (products) {
                final categoryMap = categoryMapState.value ?? {};
                final filteredProducts = products.where((product) {
                  if (_selectedCategory == 'All') return true;
                  final productCategoryName = categoryMap[product.category] ?? product.category;
                  return productCategoryName.toLowerCase() == _selectedCategory.toLowerCase();
                }).toList();

                if (filteredProducts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chair_outlined, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'No pieces in this category yet',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: filteredProducts.map((product) {
                    final isLarge = filteredProducts.indexOf(product) == 0;
                    return GestureDetector(
                      onTap: () => context.push('/marketplace/product/${product.id}'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product image
                            Container(
                              width: double.infinity,
                              height: isLarge ? 260 : 200,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0EDE6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: product.imageUrl.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        product.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Center(
                                          child: Icon(
                                            _getIconForCategory(categoryMap[product.category] ?? product.category),
                                            size: isLarge ? 56 : 44,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Icon(
                                        _getIconForCategory(categoryMap[product.category] ?? product.category),
                                        size: isLarge ? 56 : 44,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                            ),
                            // Product info
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          product.description,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Rs. ${product.price.toStringAsFixed(0)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
                child: Center(
                  child: Text(
                    'Failed to load products: $e',
                    style: GoogleFonts.inter(color: Colors.redAccent),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'seating':
      case 'chairs':
        return Icons.chair_outlined;
      case 'lighting':
        return Icons.light_outlined;
      case 'tables':
        return Icons.table_bar_outlined;
      case 'decor':
        return Icons.spa_outlined;
      default:
        return Icons.weekend_outlined;
    }
  }
}

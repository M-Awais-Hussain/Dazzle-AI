import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/features/marketplace_owner/application/marketplace_product_controller.dart';
import 'package:ayyy/features/marketplace_owner/domain/marketplace_product.dart';
import 'package:ayyy/features/marketplace_owner/presentation/widgets/product_card.dart';
import 'package:ayyy/features/marketplace_owner/presentation/widgets/common_widgets.dart';
import 'package:ayyy/features/marketplace_owner/products/presentation/add_edit_product_screen.dart';

class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({super.key});

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  String _searchQuery = '';
  bool _gridView = true;

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(marketplaceProductControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Products', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(_gridView ? Icons.view_list : Icons.grid_view, color: AppColors.textSecondary),
                        onPressed: () => setState(() => _gridView = !_gridView),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Products
            Expanded(
              child: productsAsync.when(
                data: (products) {
                  final filtered = _searchQuery.isEmpty
                      ? products
                      : products.where((p) => p.displayTitle.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                  if (filtered.isEmpty) {
                    return MarketplaceEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: _searchQuery.isEmpty ? 'No Products Yet' : 'No Results',
                      subtitle: _searchQuery.isEmpty
                          ? 'Tap + to add your first product.'
                          : 'Try a different search term.',
                      actionLabel: _searchQuery.isEmpty ? 'Add Product' : null,
                      onAction: _searchQuery.isEmpty ? () => _openAddProduct(context) : null,
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async => ref.invalidate(marketplaceProductControllerProvider),
                    child: _gridView ? _buildGrid(filtered) : _buildList(filtered),
                  );
                },
                loading: () => const MarketplaceLoadingState(message: 'Loading products...'),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddProduct(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildGrid(List<MarketplaceProduct> products) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return MarketplaceProductCard(
          product: product,
          onTap: () => _openEditProduct(context, product),
          onDelete: () => _deleteProduct(product.id),
        );
      },
    );
  }

  Widget _buildList(List<MarketplaceProduct> products) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ProductListTile(
            product: product,
            onTap: () => _openEditProduct(context, product),
            onDelete: () => _deleteProduct(product.id),
            onToggleFeatured: (v) {
              ref.read(marketplaceProductControllerProvider.notifier).toggleFeatured(product.id, v);
            },
          ),
        );
      },
    );
  }

  void _openAddProduct(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
    );
  }

  void _openEditProduct(BuildContext context, MarketplaceProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEditProductScreen(product: product)),
    );
  }

  void _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Product', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(marketplaceProductControllerProvider.notifier).deleteProduct(id);
    }
  }
}

class _ProductListTile extends StatelessWidget {
  final MarketplaceProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggleFeatured;

  const _ProductListTile({required this.product, this.onTap, this.onDelete, this.onToggleFeatured});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: const Color(0xFFF0EDE6), borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.displayTitle, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('\$${product.price.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(width: 12),
                      StockIndicator(stock: product.stock),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
              onSelected: (val) {
                if (val == 'delete') onDelete?.call();
                if (val == 'featured') onToggleFeatured?.call(!product.isFeatured);
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'featured', child: Text(product.isFeatured ? 'Remove Featured' : 'Mark Featured', style: GoogleFonts.inter(fontSize: 13))),
                PopupMenuItem(value: 'delete', child: Text('Delete', style: GoogleFonts.inter(fontSize: 13, color: AppColors.error))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

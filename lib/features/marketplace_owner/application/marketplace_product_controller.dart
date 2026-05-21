// ignore_for_file: use_null_aware_elements
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/marketplace_owner/data/marketplace_product_repository.dart';
import 'package:ayyy/features/marketplace_owner/domain/marketplace_product.dart';

/// Provider to load current marketplace owner's products
final ownerProductsProvider = FutureProvider<List<MarketplaceProduct>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  final repo = ref.watch(marketplaceProductRepositoryProvider);
  return repo.getOwnerProducts(user.id);
});

/// Upload progress state
class _UploadProgressNotifier extends Notifier<double> {
  @override
  double build() => 0.0;
  void set(double value) => state = value;
}

final productUploadProgressProvider = NotifierProvider<_UploadProgressNotifier, double>(() {
  return _UploadProgressNotifier();
});

/// Controller for product CRUD operations
class MarketplaceProductController extends AsyncNotifier<List<MarketplaceProduct>> {
  late MarketplaceProductRepository _repo;

  @override
  Future<List<MarketplaceProduct>> build() async {
    _repo = ref.watch(marketplaceProductRepositoryProvider);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];
    return _repo.getOwnerProducts(user.id);
  }

  Future<MarketplaceProduct?> createProduct({
    required String title,
    required String description,
    required double price,
    required int stock,
    String? categoryId,
    String? dimensions,
    String? material,
    List<String>? colors,
    bool isFeatured = false,
    List<XFile>? imageFiles,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Upload images first if provided
      List<String> imageUrls = [];
      String? thumbnailUrl;

      if (imageFiles != null && imageFiles.isNotEmpty) {
        final tempProductId = DateTime.now().millisecondsSinceEpoch.toString();
        for (int i = 0; i < imageFiles.length; i++) {
          ref.read(productUploadProgressProvider.notifier).set((i + 1) / imageFiles.length);
          final url = await _repo.uploadProductImage(tempProductId, imageFiles[i], i);
          imageUrls.add(url);
        }
        thumbnailUrl = imageUrls.first;
      }

      final data = <String, dynamic>{
        'shopkeeper_id': user.id,
        'title': title,
        'name': title,
        'description': description,
        'price': price,
        'stock_quantity': stock,
        'dimensions': dimensions ?? '',
        'material': material ?? '',
        'colors': colors ?? [],
        'image_urls': imageUrls,
        'thumbnail_url': thumbnailUrl,
        'is_featured': isFeatured,
        if (categoryId != null) 'category_id': categoryId,
      };

      final product = await _repo.createProduct(data);
      ref.read(productUploadProgressProvider.notifier).set(0);
      ref.invalidateSelf();
      return product;
    } catch (e) {
      debugPrint('[MarketplaceProductController] Error creating product: $e');
      ref.read(productUploadProgressProvider.notifier).set(0);
      return null;
    }
  }

  Future<bool> updateProduct({
    required String id,
    String? title,
    String? description,
    double? price,
    int? stock,
    String? categoryId,
    String? dimensions,
    String? material,
    List<String>? colors,
    bool? isFeatured,
    List<String>? imageUrls,
    String? thumbnailUrl,
  }) async {
    try {
      final data = <String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (price != null) 'price': price,
        if (stock != null) 'stock_quantity': stock,
        if (categoryId != null) 'category_id': categoryId,
        if (dimensions != null) 'dimensions': dimensions,
        if (material != null) 'material': material,
        if (colors != null) 'colors': colors,
        if (isFeatured != null) 'is_featured': isFeatured,
        if (imageUrls != null) 'image_urls': imageUrls,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      };

      await _repo.updateProduct(id, data);
      ref.invalidateSelf();
      return true;
    } catch (e) {
      debugPrint('[MarketplaceProductController] Error updating product: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await _repo.deleteProduct(id);
      ref.invalidateSelf();
      return true;
    } catch (e) {
      debugPrint('[MarketplaceProductController] Error deleting product: $e');
      return false;
    }
  }

  Future<void> toggleFeatured(String id, bool isFeatured) async {
    try {
      await _repo.toggleFeatured(id, isFeatured);
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('[MarketplaceProductController] Error toggling featured: $e');
    }
  }

  /// Upload additional images for an existing product
  Future<List<String>> uploadImages(String productId, List<XFile> files) async {
    final urls = <String>[];
    try {
      for (int i = 0; i < files.length; i++) {
        ref.read(productUploadProgressProvider.notifier).set(
            (i + 1) / files.length);
        final url = await _repo.uploadProductImage(productId, files[i], i);
        urls.add(url);
      }
      ref.read(productUploadProgressProvider.notifier).set(0);
      return urls;
    } catch (e) {
      ref.read(productUploadProgressProvider.notifier).set(0);
      debugPrint('[MarketplaceProductController] Error uploading images: $e');
      return urls;
    }
  }
}

final marketplaceProductControllerProvider =
    AsyncNotifierProvider<MarketplaceProductController, List<MarketplaceProduct>>(() {
  return MarketplaceProductController();
});

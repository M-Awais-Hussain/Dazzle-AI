import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ayyy/features/marketplace_owner/data/product_variant_repository.dart';
import 'package:ayyy/features/marketplace_owner/domain/product_variant.dart';
import 'package:ayyy/features/marketplace_owner/domain/product_variant_image.dart';

class _VariantUploadProgressNotifier extends Notifier<double> {
  @override
  double build() => 0.0;
  void set(double value) => state = value;
}

final variantUploadProgressProvider = NotifierProvider<_VariantUploadProgressNotifier, double>(() {
  return _VariantUploadProgressNotifier();
});

final ownerProductVariantsProvider = FutureProvider.family<List<ProductVariant>, String>((ref, productId) async {
  final repo = ref.watch(ownerProductVariantRepositoryProvider);
  return repo.getVariantsForProduct(productId);
});

final ownerProductVariantImagesProvider = FutureProvider.family<List<ProductVariantImage>, String>((ref, productId) async {
  final repo = ref.watch(ownerProductVariantRepositoryProvider);
  return repo.getVariantImages(productId);
});

class ProductVariantController extends AsyncNotifier<void> {
  late ProductVariantRepository _repo;

  @override
  Future<void> build() async {
    _repo = ref.watch(ownerProductVariantRepositoryProvider);
  }

  Future<ProductVariant?> createColorVariant({
    required String productId,
    required String colorName,
    required String hexCode,
    int sortOrder = 0,
  }) async {
    try {
      final data = {
        'product_id': productId,
        'variant_type': 'color',
        'color_name': colorName,
        'hex_code': hexCode,
        'sort_order': sortOrder,
      };

      final variant = await _repo.createVariant(data);
      ref.invalidate(ownerProductVariantsProvider(productId));
      return variant;
    } catch (e) {
      debugPrint('[ProductVariantController] Error creating color variant: $e');
      return null;
    }
  }



  Future<bool> deleteVariant(String variantId, String productId) async {
    try {
      await _repo.deleteVariant(variantId);
      ref.invalidate(ownerProductVariantsProvider(productId));
      ref.invalidate(ownerProductVariantImagesProvider(productId));
      return true;
    } catch (e) {
      debugPrint('[ProductVariantController] Error deleting variant: $e');
      return false;
    }
  }

  Future<bool> uploadVariantImage({
    required String productId,
    required XFile imageFile,
    String? colorVariantId,
  }) async {
    try {
      ref.read(variantUploadProgressProvider.notifier).set(0.1);
      
      final imageUrl = await _repo.uploadVariantImageFile(productId, imageFile);
      
      ref.read(variantUploadProgressProvider.notifier).set(0.7);

      final data = {
        'product_id': productId,
        'color_variant_id': colorVariantId,
        'image_url': imageUrl,
        'thumbnail_url': imageUrl,
      };

      await _repo.createVariantImage(data);
      ref.read(variantUploadProgressProvider.notifier).set(1.0);
      ref.invalidate(ownerProductVariantImagesProvider(productId));
      
      return true;
    } catch (e) {
      debugPrint('[ProductVariantController] Error uploading variant image: $e');
      return false;
    } finally {
      ref.read(variantUploadProgressProvider.notifier).set(0.0);
    }
  }

  Future<bool> deleteVariantImage(String imageId, String productId) async {
    try {
      await _repo.deleteVariantImage(imageId);
      ref.invalidate(ownerProductVariantImagesProvider(productId));
      return true;
    } catch (e) {
      debugPrint('[ProductVariantController] Error deleting variant image: $e');
      return false;
    }
  }
  Future<bool> linkVariantImage({
    required String productId,
    required String imageUrl,
    String? colorVariantId,
  }) async {
    try {
      final data = {
        'product_id': productId,
        'color_variant_id': colorVariantId,
        'image_url': imageUrl,
        'thumbnail_url': imageUrl,
      };

      await _repo.createVariantImage(data);
      ref.invalidate(ownerProductVariantImagesProvider(productId));
      return true;
    } catch (e) {
      debugPrint('[ProductVariantController] Error linking variant image: $e');
      return false;
    }
  }
}

final productVariantControllerProvider = AsyncNotifierProvider<ProductVariantController, void>(() {
  return ProductVariantController();
});

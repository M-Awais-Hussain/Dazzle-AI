import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayyy/features/user/marketplace/data/product_variant_repository.dart';
import 'package:ayyy/features/user/marketplace/domain/product_variant.dart';
import 'package:ayyy/features/user/marketplace/domain/product_variant_image.dart';
import 'package:ayyy/features/user/marketplace/application/product_controller.dart';

final productVariantsProvider = FutureProvider.family<List<ProductVariant>, String>((ref, productId) async {
  final repo = ref.watch(userProductVariantRepositoryProvider);
  return repo.getVariantsForProduct(productId);
});

final productColorVariantsProvider = FutureProvider.family<List<ProductVariant>, String>((ref, productId) async {
  final repo = ref.watch(userProductVariantRepositoryProvider);
  return repo.getColorVariants(productId);
});

final productLayoutVariantsProvider = FutureProvider.family<List<ProductVariant>, String>((ref, productId) async {
  final repo = ref.watch(userProductVariantRepositoryProvider);
  return repo.getLayoutVariants(productId);
});

final productVariantImagesProvider = FutureProvider.family<List<ProductVariantImage>, String>((ref, productId) async {
  final repo = ref.watch(userProductVariantRepositoryProvider);
  return repo.getVariantImages(productId);
});

// Currently selected variants on the product details page
class SelectedColorVariantNotifier extends Notifier<Map<String, ProductVariant>> {
  @override
  Map<String, ProductVariant> build() => {};
  
  void select(String productId, ProductVariant? variant) {
    if (variant == null) {
      state = {...state}..remove(productId);
    } else {
      state = {...state, productId: variant};
    }
  }
}

final selectedColorVariantProvider = NotifierProvider<SelectedColorVariantNotifier, Map<String, ProductVariant>>(() {
  return SelectedColorVariantNotifier();
});

class SelectedLayoutVariantNotifier extends Notifier<Map<String, ProductVariant>> {
  @override
  Map<String, ProductVariant> build() => {};
  
  void select(String productId, ProductVariant? variant) {
    if (variant == null) {
      state = {...state}..remove(productId);
    } else {
      state = {...state, productId: variant};
    }
  }
}

final selectedLayoutVariantProvider = NotifierProvider<SelectedLayoutVariantNotifier, Map<String, ProductVariant>>(() {
  return SelectedLayoutVariantNotifier();
});

// Computed provider that determines the active product image URL to show
final activeProductImageUrlProvider = Provider.family<String?, String>((ref, productId) {
  final selectedColors = ref.watch(selectedColorVariantProvider);
  final selectedLayouts = ref.watch(selectedLayoutVariantProvider);
  
  final selectedColor = selectedColors[productId];
  final selectedLayout = selectedLayouts[productId];
  
  // If we have selected variants, try to find an exact matching image
  if (selectedColor != null || selectedLayout != null) {
    final imagesAsync = ref.watch(productVariantImagesProvider(productId));
    if (imagesAsync.hasValue) {
      final images = imagesAsync.value!;
      
      // Try to find image that matches BOTH color and layout if both are selected
      if (selectedColor != null && selectedLayout != null) {
        final match = images.where((i) => 
          i.colorVariantId == selectedColor.id && 
          i.layoutVariantId == selectedLayout.id
        ).firstOrNull;
        if (match != null) return match.imageUrl;
      }
      
      // Fallback to finding just color match
      if (selectedColor != null) {
        final match = images.where((i) => i.colorVariantId == selectedColor.id).firstOrNull;
        if (match != null) return match.imageUrl;
      }
      
      // Fallback to finding just layout match
      if (selectedLayout != null) {
        final match = images.where((i) => i.layoutVariantId == selectedLayout.id).firstOrNull;
        if (match != null) return match.imageUrl;
      }
    }
  }
  
  // Fallback to the product's primary image
  final productAsyncValue = ref.watch(productDetailsProvider(productId));
  return productAsyncValue.whenOrNull(
    data: (product) => product.imageUrls.isNotEmpty ? product.imageUrls.first : product.imageUrl,
  );
});

// Canvas specific state
class AiCanvasVariantNotifier extends Notifier<ProductVariant?> {
  @override
  ProductVariant? build() => null;
  void set(ProductVariant? variant) => state = variant;
}

final aiCanvasVariantProvider = NotifierProvider<AiCanvasVariantNotifier, ProductVariant?>(() {
  return AiCanvasVariantNotifier();
});

// Computed provider that determines the active product images list to show in the carousel
final activeProductVariantImagesProvider = Provider.family<List<String>, String>((ref, productId) {
  final selectedColors = ref.watch(selectedColorVariantProvider);
  final selectedColor = selectedColors[productId];
  
  final productAsyncValue = ref.watch(productDetailsProvider(productId));
  
  // If a color is selected, return all its associated images
  if (selectedColor != null) {
    final imagesAsync = ref.watch(productVariantImagesProvider(productId));
    if (imagesAsync.hasValue) {
      final images = imagesAsync.value!;
      final colorImages = images
          .where((i) => i.colorVariantId == selectedColor.id)
          .map((i) => i.imageUrl)
          .toList();
          
      if (colorImages.isNotEmpty) {
        return colorImages;
      }
    }
  }
  
  // Fallback to the product's default images
  return productAsyncValue.whenOrNull(
    data: (product) {
      final list = <String>[];
      if (product.imageUrl.isNotEmpty) list.add(product.imageUrl);
      for (final url in product.imageUrls) {
        if (url.isNotEmpty && !list.contains(url)) {
          list.add(url);
        }
      }
      return list;
    },
  ) ?? [];
});

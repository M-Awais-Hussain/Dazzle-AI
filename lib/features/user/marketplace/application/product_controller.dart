import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayyy/features/user/marketplace/data/product_repository.dart';
import 'package:ayyy/features/user/marketplace/domain/product.dart';

final productsProvider = FutureProvider<List<Product>>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProducts();
});

final productDetailsProvider = FutureProvider.family<Product, String>((ref, id) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProductById(id);
});

final shopkeeperProductsProvider = FutureProvider.family<List<Product>, String>((ref, shopkeeperId) {
  final repository = ref.watch(productRepositoryProvider);
  return repository.getProductsByShopkeeper(shopkeeperId);
});

class ProductController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  // Additional methods like addProduct, updateProduct, deleteProduct can go here.
}

final productControllerProvider = NotifierProvider<ProductController, AsyncValue<void>>(() {
  return ProductController();
});

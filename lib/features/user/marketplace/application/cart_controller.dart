import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayyy/features/user/marketplace/domain/cart_item.dart';
import 'package:ayyy/features/user/marketplace/domain/product.dart';

class CartState {
  final List<CartItem> items;
  CartState({this.items = const []});

  double get subtotal => items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  double get discount => 0.0; // Dynamic discount system (or 0.0 initially)
  double get total => subtotal - discount;

  CartState copyWith({List<CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }
}

class CartController extends Notifier<CartState> {
  @override
  CartState build() {
    // Start with a clean empty cart for real user collection items
    return CartState(items: const []);
  }

  void addItem(Product product) {
    final existingIndex = state.items.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final currentQuantity = state.items[existingIndex].quantity;
      if (currentQuantity >= product.stock) {
        return;
      }
      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: currentQuantity + 1,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      if (product.stock <= 0) {
        return;
      }
      state = state.copyWith(items: [...state.items, CartItem(product: product, quantity: 1)]);
    }
  }

  void removeItem(String productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.product.id != productId).toList(),
    );
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    state = state.copyWith(
      items: state.items.map((item) {
        if (item.product.id == productId) {
          final clampedQuantity = quantity > item.product.stock ? item.product.stock : quantity;
          return item.copyWith(quantity: clampedQuantity);
        }
        return item;
      }).toList(),
    );
  }

  void clearCart() {
    state = state.copyWith(items: []);
  }
}

final cartControllerProvider = NotifierProvider<CartController, CartState>(() {
  return CartController();
});

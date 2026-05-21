import 'package:flutter_riverpod/flutter_riverpod.dart';

// Placeholder class for Designer Portfolio
class DesignerPortfolio {
  final String id;
  final String bio;
  final bool isAvailable;

  DesignerPortfolio({required this.id, required this.bio, this.isAvailable = true});
}

// In a real app, you would have a DesignerRepository talking to Supabase designer_portfolios table.

class DesignerController extends Notifier<AsyncValue<DesignerPortfolio?>> {
  @override
  AsyncValue<DesignerPortfolio?> build() {
    return const AsyncData(null);
  }

  Future<void> fetchPortfolio(String designerId) async {
    state = const AsyncLoading();
    try {
      // Simulate network request
      await Future.delayed(const Duration(seconds: 1));
      state = AsyncData(DesignerPortfolio(id: designerId, bio: 'Expert Interior Designer'));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateAvailability(bool isAvailable) async {
    if (state.value == null) return;
    
    state = const AsyncLoading();
    try {
      // Simulate network request
      await Future.delayed(const Duration(seconds: 1));
      state = AsyncData(DesignerPortfolio(id: state.value!.id, bio: state.value!.bio, isAvailable: isAvailable));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final designerControllerProvider = NotifierProvider<DesignerController, AsyncValue<DesignerPortfolio?>>(() {
  return DesignerController();
});

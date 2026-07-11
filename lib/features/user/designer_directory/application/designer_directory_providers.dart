import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/designer/profile/data/designer_profile_repository.dart';
import 'package:ayyy/features/designer/portfolio/domain/portfolio_project.dart';

class PendingHireRequestState {
  final List<String> urls;
  final String? productId;
  final Map<String, dynamic>? canvasState;

  const PendingHireRequestState({
    this.urls = const [],
    this.productId,
    this.canvasState,
  });
}

class PendingHireAttachmentNotifier extends Notifier<PendingHireRequestState> {
  @override
  PendingHireRequestState build() => const PendingHireRequestState();

  void setMultiple(List<String> urls, {String? productId, Map<String, dynamic>? canvasState}) {
    state = PendingHireRequestState(
      urls: urls,
      productId: productId,
      canvasState: canvasState,
    );
  }

  void clear() {
    state = const PendingHireRequestState();
  }
}

final pendingHireAttachmentProvider = NotifierProvider<PendingHireAttachmentNotifier, PendingHireRequestState>(
  PendingHireAttachmentNotifier.new,
);

final publicDesignersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(designerProfileRepositoryProvider);
  return repository.getPublicDesignerCards();
});

final publicDesignerDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final supabase = Supabase.instance.client;
  
  // Fetch profiles table with joined designer_profiles details for this id
  final response = await supabase
      .from('profiles')
      .select('*, designer_profiles:designer_profiles!designer_profiles_id_fkey(*)')
      .eq('id', id)
      .single();
      
  return Map<String, dynamic>.from(response);
});

final publicDesignerPortfolioProvider = FutureProvider.family<List<PortfolioProject>, String>((ref, id) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('designer_portfolios')
      .select()
      .eq('designer_id', id)
      .order('created_at', ascending: false);
      
  return (response as List<dynamic>)
      .map((e) => PortfolioProject.fromJson(e as Map<String, dynamic>))
      .toList();
});

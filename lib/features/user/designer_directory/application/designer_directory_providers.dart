import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/designer/profile/data/designer_profile_repository.dart';

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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/designer_profile.dart';
import 'package:ayyy/core/errors/exceptions.dart';

abstract class DesignerProfileRepository {
  Future<DesignerProfile?> getProfile(String designerId);
  Future<void> updateProfile(DesignerProfile profile);
  Future<List<Map<String, dynamic>>> getPublicDesignerCards();
}

class SupabaseDesignerProfileRepository implements DesignerProfileRepository {
  final SupabaseClient _supabase;

  SupabaseDesignerProfileRepository(this._supabase);

  @override
  Future<DesignerProfile?> getProfile(String designerId) async {
    try {
      final response = await _supabase
          .from('designer_profiles')
          .select()
          .eq('id', designerId)
          .maybeSingle();

      if (response != null) {
        return DesignerProfile.fromJson(response);
      }

      // Self-heal: If profile exists in 'profiles' but not 'designer_profiles', create it
      final coreProfile = await _supabase
          .from('profiles')
          .select()
          .eq('id', designerId)
          .maybeSingle();

      if (coreProfile != null && coreProfile['role'] == 'designer') {
        final newProfile = DesignerProfile(
          id: designerId,
          bio: 'Luxury minimalist interior architect & design specialist.',
          experienceYears: 2,
          expertise: ['Minimal', 'Modern', 'Luxe'],
          socialLinks: {},
          certifications: [],
          isAvailable: true,
          consultationPrice: 49.00,
          responseTime: 'Within a few hours',
        );
        await _supabase.from('designer_profiles').insert(newProfile.toJson());
        return newProfile;
      }

      return null;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateProfile(DesignerProfile profile) async {
    try {
      await _supabase
          .from('designer_profiles')
          .upsert(profile.toJson());
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPublicDesignerCards() async {
    try {
      // Query profiles with role = 'designer' and join designer_profiles specifying foreign key
      final response = await _supabase
          .from('profiles')
          .select('*, designer_profiles:designer_profiles!designer_profiles_id_fkey(*)')
          .eq('role', 'designer');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

final designerProfileRepositoryProvider = Provider<DesignerProfileRepository>((ref) {
  return SupabaseDesignerProfileRepository(Supabase.instance.client);
});

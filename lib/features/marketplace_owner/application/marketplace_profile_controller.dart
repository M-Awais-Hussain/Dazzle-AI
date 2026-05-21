// ignore_for_file: use_null_aware_elements
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/marketplace_owner/data/marketplace_profile_repository.dart';
import 'package:ayyy/features/marketplace_owner/domain/marketplace_profile.dart';

/// Provider to load the current marketplace owner's profile
final marketplaceProfileProvider = FutureProvider<MarketplaceProfile?>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  final repo = ref.watch(marketplaceProfileRepositoryProvider);
  return repo.getProfile(user.id);
});

/// Controller for marketplace profile CRUD operations
class MarketplaceProfileController extends AsyncNotifier<MarketplaceProfile?> {
  late MarketplaceProfileRepository _repo;

  @override
  Future<MarketplaceProfile?> build() async {
    _repo = ref.watch(marketplaceProfileRepositoryProvider);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    return _repo.getProfile(user.id);
  }

  Future<bool> saveProfile({
    required String storeName,
    String? storeDescription,
    String? contactPhone,
    String? contactEmail,
    String? address,
    Map<String, dynamic>? socialLinks,
  }) async {
    state = const AsyncLoading();
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final data = <String, dynamic>{
        'id': user.id,
        'store_name': storeName,
        if (storeDescription != null) 'store_description': storeDescription,
        if (contactPhone != null) 'contact_phone': contactPhone,
        if (contactEmail != null) 'contact_email': contactEmail,
        if (address != null) 'address': address,
        if (socialLinks != null) 'social_links': socialLinks,
      };

      final profile = await _repo.upsertProfile(data);
      state = AsyncData(profile);
      return true;
    } catch (e, st) {
      debugPrint('[MarketplaceProfileController] Error saving profile: $e');
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<String?> uploadLogo(XFile file) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final url = await _repo.uploadStoreLogo(user.id, file);

      // Update profile with new logo URL
      await _repo.upsertProfile({
        'id': user.id,
        'store_logo_url': url,
      });

      ref.invalidateSelf();
      return url;
    } catch (e) {
      debugPrint('[MarketplaceProfileController] Error uploading logo: $e');
      return null;
    }
  }

  Future<String?> uploadBanner(XFile file) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final url = await _repo.uploadStoreBanner(user.id, file);

      await _repo.upsertProfile({
        'id': user.id,
        'store_banner_url': url,
      });

      ref.invalidateSelf();
      return url;
    } catch (e) {
      debugPrint('[MarketplaceProfileController] Error uploading banner: $e');
      return null;
    }
  }
}

final marketplaceProfileControllerProvider =
    AsyncNotifierProvider<MarketplaceProfileController, MarketplaceProfile?>(() {
  return MarketplaceProfileController();
});

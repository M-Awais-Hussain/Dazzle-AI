import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/marketplace_owner/domain/marketplace_profile.dart';
import 'package:ayyy/core/errors/exceptions.dart';

abstract class MarketplaceProfileRepository {
  Future<MarketplaceProfile?> getProfile(String ownerId);
  Future<MarketplaceProfile> upsertProfile(Map<String, dynamic> data);
  Future<String> uploadStoreLogo(String ownerId, XFile file);
  Future<String> uploadStoreBanner(String ownerId, XFile file);
}

class SupabaseMarketplaceProfileRepository implements MarketplaceProfileRepository {
  final SupabaseClient _supabase;

  SupabaseMarketplaceProfileRepository(this._supabase);

  @override
  Future<MarketplaceProfile?> getProfile(String ownerId) async {
    try {
      final response = await _supabase
          .from('marketplace_profiles')
          .select()
          .eq('id', ownerId)
          .maybeSingle();

      if (response == null) return null;
      return MarketplaceProfile.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to fetch marketplace profile: $e');
    }
  }

  @override
  Future<MarketplaceProfile> upsertProfile(Map<String, dynamic> data) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('marketplace_profiles')
          .upsert(data)
          .select()
          .single();
      return MarketplaceProfile.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to save marketplace profile: $e');
    }
  }

  @override
  Future<String> uploadStoreLogo(String ownerId, XFile file) async {
    try {
      final fileExt = file.name.split('.').last;
      final path = 'store-logos/$ownerId.$fileExt';
      final bytes = await file.readAsBytes();

      await _supabase.storage.from('product-images').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      return _supabase.storage.from('product-images').getPublicUrl(path);
    } catch (e) {
      throw ServerException('Failed to upload store logo: $e');
    }
  }

  @override
  Future<String> uploadStoreBanner(String ownerId, XFile file) async {
    try {
      final fileExt = file.name.split('.').last;
      final path = 'store-banners/$ownerId.$fileExt';
      final bytes = await file.readAsBytes();

      await _supabase.storage.from('product-images').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      return _supabase.storage.from('product-images').getPublicUrl(path);
    } catch (e) {
      throw ServerException('Failed to upload store banner: $e');
    }
  }
}

final marketplaceProfileRepositoryProvider = Provider<MarketplaceProfileRepository>((ref) {
  return SupabaseMarketplaceProfileRepository(Supabase.instance.client);
});

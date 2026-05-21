import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ayyy/core/config/env_config.dart';

abstract class StorageRepository {
  Future<String> uploadAvatar(String userId, XFile file);
  Future<String> uploadDesignAsset(String designId, XFile file);
  Future<void> deleteAsset(String bucketId, String path);
}

class SupabaseStorageRepository implements StorageRepository {
  final SupabaseClient _supabase;

  SupabaseStorageRepository(this._supabase);

  @override
  Future<String> uploadAvatar(String userId, XFile file) async {
    final fileExt = file.name.split('.').last;
    final fileName = '$userId-${DateTime.now().toIso8601String()}.$fileExt';
    final path = 'avatars/$fileName';
    
    final bytes = await file.readAsBytes();
    await _supabase.storage.from('avatars').uploadBinary(path, bytes);
    
    return _supabase.storage.from('avatars').getPublicUrl(path);
  }

  @override
  Future<String> uploadDesignAsset(String designId, XFile file) async {
    final fileExt = file.name.split('.').last;
    final fileName = '$designId-${DateTime.now().toIso8601String()}.$fileExt';
    final path = 'designs/$fileName';
    
    final bytes = await file.readAsBytes();
    await _supabase.storage.from('assets').uploadBinary(path, bytes);
    
    return _supabase.storage.from('assets').getPublicUrl(path);
  }

  @override
  Future<void> deleteAsset(String bucketId, String path) async {
    await _supabase.storage.from(bucketId).remove([path]);
  }
}

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  final secretKey = EnvConfig.supabaseSecretKey;
  final client = secretKey.isNotEmpty
      ? SupabaseClient(EnvConfig.supabaseUrl, secretKey)
      : Supabase.instance.client;
  return SupabaseStorageRepository(client);
});

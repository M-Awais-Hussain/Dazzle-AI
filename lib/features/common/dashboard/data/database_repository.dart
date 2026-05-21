import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/auth/domain/app_user.dart';

abstract class DatabaseRepository {
  Future<AppUser?> getProfile(String userId);
  Future<void> updateProfile(String userId, {String? name, String? role, String? avatarUrl});
}

class SupabaseDatabaseRepository implements DatabaseRepository {
  final SupabaseClient _supabase;

  SupabaseDatabaseRepository(this._supabase);

  @override
  Future<AppUser?> getProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;

      return AppUser(
        id: data['id'] as String,
        email: data['email'] as String? ?? '',
        username: data['username'] as String? ?? data['full_name'] as String? ?? '',
        name: data['full_name'] as String? ?? data['name'] as String? ?? 'User',
        role: data['role'] as String? ?? 'user',
      );
    } catch (e) {
      log('Error fetching profile: $e');
      return null;
    }
  }

  @override
  Future<void> updateProfile(String userId, {String? name, String? role, String? avatarUrl}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['full_name'] = name;
    if (role != null) updates['role'] = role;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    if (updates.isNotEmpty) {
      await _supabase.from('profiles').update(updates).eq('id', userId);
    }
  }
}

final databaseRepositoryProvider = Provider<DatabaseRepository>((ref) {
  return SupabaseDatabaseRepository(Supabase.instance.client);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/auth/domain/app_user.dart';
import 'package:ayyy/core/errors/exceptions.dart';

abstract class AuthRepository {
  Future<User?> login(String email, String password);
  Future<User?> signUp(String email, String password, String name, String role, {String? username});
  Future<void> logout();
  User? getCurrentUser();
  Future<AppUser?> getUserProfile(String userId);
  Future<AppUser> createProfile(String id, String email, String name, String role, {String? username});
  Future<void> updateProfileName(String userId, String newName);
  Future<void> updatePassword(String newPassword);
}

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabase;

  SupabaseAuthRepository(this._supabase);

  @override
  Future<AppUser> createProfile(String id, String email, String name, String role, {String? username}) async {
    try {
      final usernameVal = username ?? email.split('@').first;
      await _supabase.from('profiles').upsert({
        'id': id,
        'full_name': name,
        'email': email,
        'username': usernameVal,
        'role': role,
      });
      return AppUser(
        id: id,
        email: email,
        username: usernameVal,
        name: name,
        role: role,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<User?> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } on AuthException catch (e) {
      throw ServerException(e.message, code: e.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<User?> signUp(String email, String password, String name, String role, {String? username}) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': name,
          'role': role,
        },
      );
      
      // The trigger in Supabase (if set up) or manual insertion should handle the profile.
      // If we need to manually create the profile:
      if (response.user != null) {
        await _supabase.from('profiles').upsert({
          'id': response.user!.id,
          'full_name': name,
          'email': email,
          'username': username ?? name.toLowerCase().replaceAll(' ', ''),
          'role': role,
        });
      }
      
      return response.user;
    } on AuthException catch (e) {
      throw ServerException(e.message, code: e.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  @override
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  @override
  Future<AppUser?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
          
      if (response != null) {
        return AppUser(
          id: response['id'] as String,
          email: response['email'] as String? ?? response['email_address'] as String? ?? '',
          username: response['username'] as String? ?? response['full_name'] as String? ?? '',
          name: response['full_name'] as String? ?? 'User',
          role: response['role'] as String? ?? 'user',
        );
      }
      return null;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateProfileName(String userId, String newName) async {
    try {
      await _supabase.from('profiles').update({
        'full_name': newName,
      }).eq('id', userId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw ServerException(e.message, code: e.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(Supabase.instance.client);
});

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/auth/data/auth_repository.dart';
import 'package:ayyy/features/auth/domain/app_user.dart';
import 'package:ayyy/features/auth/presentation/role_selection_screen.dart';
import 'package:ayyy/features/designer/requests/application/designer_request_controller.dart';
import 'package:ayyy/features/designer/earnings/application/designer_earnings_controller.dart';
import 'package:ayyy/features/designer/portfolio/application/portfolio_controller.dart';

// Provides the auth state from Supabase
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

// A provider to fetch the current user's profile from the database.
// This provider does NOT watch authStateProvider to avoid race conditions
// during login (where the profile may not exist yet while login is creating it).
// Instead, it is manually invalidated after login/signup/logout completes.
final currentUserProfileProvider = FutureProvider<AppUser?>((ref) async {
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) {
    debugPrint('[Profile Provider] No session, returning null.');
    return null;
  }

  try {
    final authRepo = ref.watch(authRepositoryProvider);
    final profile = await authRepo.getUserProfile(session.user.id);

    if (profile == null) {
      debugPrint('[Profile Provider] No profile row found for user ${session.user.id}.');
      // Don't auto-logout here — the login flow may still be creating the profile.
      // The router will handle unauthenticated redirects.
      return null;
    }

    debugPrint('[Profile Provider] Profile loaded: role=${profile.role}');
    return profile;
  } catch (e) {
    debugPrint('[Profile Provider] Error fetching profile: $e');
    return null;
  }
});

// A simple provider to get the role of the logged in user
final userRoleProvider = Provider<String?>((ref) {
  final profile = ref.watch(currentUserProfileProvider).value;
  return profile?.role;
});

class AuthController extends AsyncNotifier<void> {
  late AuthRepository _authRepository;

  @override
  FutureOr<void> build() {
    _authRepository = ref.watch(authRepositoryProvider);
    return null;
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _authRepository.login(email, password);
      if (user != null) {
        final selectedRole = ref.read(selectedRoleProvider);
        var profile = await _authRepository.getUserProfile(user.id);
        
        // Auto-create/self-heal missing profile row with the selected role
        if (profile == null) {
          final displayName = user.userMetadata?['full_name'] as String? ?? user.email?.split('@').first ?? 'User';
          final usernameVal = user.userMetadata?['username'] as String? ?? user.email?.split('@').first ?? 'user';
          profile = await _authRepository.createProfile(
            user.id,
            user.email ?? '',
            displayName,
            selectedRole,
            username: usernameVal,
          );
          debugPrint('[Auth] Created profile for ${user.id} with role: $selectedRole');
        }

        if (profile.role != selectedRole) {
          await _authRepository.logout();
          final userRoleFriendly = profile.role == 'marketplace_owner' 
              ? 'Marketplace Owner' 
              : (profile.role == 'designer' ? 'Designer' : (profile.role == 'user' ? 'User' : 'Unknown'));
          throw Exception(
            "Access Denied: This account is registered as a $userRoleFriendly. "
            "Please return to the role selection screen and select the correct role to log in."
          );
        }
      }
      state = const AsyncData(null);

      // Now that login is complete and profile is guaranteed to exist,
      // invalidate the profile provider so the router picks up the role.
      ref.invalidate(currentUserProfileProvider);

      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name, String role, {String? username}) async {
    state = const AsyncLoading();
    try {
      await _authRepository.signUp(email, password, name, role, username: username);
      state = const AsyncData(null);

      // Profile was created during signUp, invalidate so router picks it up.
      ref.invalidate(currentUserProfileProvider);

      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await _authRepository.logout();
      state = const AsyncData(null);

      // Clear the cached profile after logout
      ref.invalidate(currentUserProfileProvider);
      
      // Invalidate designer providers so new login doesn't see old cached designer data
      ref.invalidate(designerRequestsProvider);
      ref.invalidate(designerEarningsProvider);
      ref.invalidate(designerProjectsProvider);
      ref.invalidate(designerPackagesProvider);
      ref.invalidate(designerReviewsProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(() {
  return AuthController();
});

import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:ayyy/features/common/splash/presentation/splash_screen.dart';
import 'package:ayyy/features/auth/presentation/role_selection_screen.dart';
import 'package:ayyy/features/auth/presentation/login_screen.dart';
import 'package:ayyy/features/user/home/presentation/home_dashboard_screen.dart';
import 'package:ayyy/features/user/marketplace/presentation/marketplace_home_screen.dart';
import 'package:ayyy/features/user/marketplace/presentation/product_details_screen.dart';
import 'package:ayyy/features/user/marketplace/presentation/shopping_cart_screen.dart';
import 'package:ayyy/features/user/marketplace/presentation/ai_room_result_screen.dart';
import 'package:ayyy/features/user/designer_directory/presentation/designer_directory_screen.dart';
import 'package:ayyy/features/user/chat/presentation/public_designer_profile_screen.dart';
import 'package:ayyy/features/user/designer_directory/presentation/hire_request_screen.dart';
import 'package:ayyy/features/designer/dashboard/presentation/designer_shell_screen.dart';
import 'package:ayyy/features/user/chat/presentation/designer_collaboration_screen.dart';
import 'package:ayyy/features/user/chat/presentation/rate_experience_screen.dart';
import 'package:ayyy/features/user/chat/presentation/review_submitted_screen.dart';
import 'package:ayyy/features/user/profile/presentation/settings_screen.dart';
import 'package:ayyy/features/user/orders/presentation/checkout_screen.dart';
import 'package:ayyy/features/user/orders/presentation/order_success_screen.dart';
import 'package:ayyy/features/marketplace_owner/presentation/marketplace_shell_screen.dart';
import 'package:ayyy/features/marketplace_owner/products/presentation/add_edit_product_screen.dart';
import 'package:ayyy/features/user/chat/presentation/user_chat_list_screen.dart';
import 'package:ayyy/features/user/orders/presentation/user_request_management_screen.dart';
import 'package:ayyy/features/notifications/presentation/notifications_screen.dart';
import 'package:ayyy/features/user/marketplace/presentation/ai_creations_screen.dart';
import 'package:ayyy/features/user/marketplace/presentation/ai_creation_detail_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ayyy/features/auth/application/auth_controller.dart';

/// A ChangeNotifier that listens to auth state and profile changes
/// to trigger GoRouter redirect re-evaluation WITHOUT recreating the router.
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier(Ref ref) {
    // Listen to auth state changes
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      debugPrint('[AuthChangeNotifier] Auth state changed, notifying router.');
      notifyListeners();
    });

    // Listen to profile provider changes
    ref.listen(currentUserProfileProvider, (previous, next) {
      debugPrint('[AuthChangeNotifier] Profile state changed: $next, notifying router.');
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _authSub;

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}

final _authChangeNotifierProvider = Provider<AuthChangeNotifier>((ref) {
  final notifier = AuthChangeNotifier(ref);
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final authChangeNotifier = ref.watch(_authChangeNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authChangeNotifier,
    redirect: (context, state) {
      final isAuth = Supabase.instance.client.auth.currentSession != null;
      final isSplash = state.uri.path == '/splash';
      final isLoginOrRole = state.uri.path == '/login' || state.uri.path == '/role-selection';

      // Read profile state directly (not via ref.watch, since this is a callback)
      final profileState = ref.read(currentUserProfileProvider);
      final userRole = profileState.value?.role;

      debugPrint('[GoRouter Redirect] path: ${state.uri.path}, isAuth: $isAuth, userRole: $userRole, profileLoading: ${profileState.isLoading}');

      // If not authenticated
      if (!isAuth) {
        // Allow splash, login, and role-selection
        if (isSplash || isLoginOrRole) return null;
        // Redirect everything else to role-selection
        debugPrint('[GoRouter Redirect] Not authenticated, redirecting to /role-selection');
        return '/role-selection';
      }

      // --- User IS authenticated from here ---

      // If profile is still loading, stay on current page (don't redirect)
      // unless they're on splash — keep them on splash while loading
      if (profileState.isLoading || profileState.isRefreshing) {
        if (isSplash) return null; // stay on splash
        if (isLoginOrRole) return null; // stay on login/role while profile loads
        return null;
      }

      // Profile loaded but role is null (shouldn't happen but safety net)
      if (userRole == null) {
        return null;
      }

      // Redirect authenticated users away from splash/login/role-selection to correct dashboard
      if (isLoginOrRole || isSplash) {
        if (userRole == 'designer') {
          debugPrint('[GoRouter Redirect] Authenticated designer → /designer/dashboard');
          return '/designer/dashboard';
        } else if (userRole == 'marketplace_owner') {
          debugPrint('[GoRouter Redirect] Authenticated marketplace_owner → /marketplace/dashboard');
          return '/marketplace/dashboard';
        } else {
          debugPrint('[GoRouter Redirect] Authenticated user → /dashboard');
          return '/dashboard'; // normal user
        }
      }

      // --- STRICT ACCESS CONTROL (ROUTE GUARDS) ---
      final currentPath = state.uri.path;
      
      // 1. Designer Guards
      if (userRole == 'designer') {
        final isAllowed = currentPath.startsWith('/designer/') || 
                          currentPath.startsWith('/collaboration/chat/') || 
                          currentPath == '/settings' ||
                          currentPath == '/notifications';
        if (!isAllowed) {
          return '/designer/dashboard';
        }
      }

      // 2. Marketplace Owner Guards
      if (userRole == 'marketplace_owner') {
        final isAllowed = currentPath.startsWith('/marketplace/') || 
                          currentPath.startsWith('/collaboration/chat/') || 
                          currentPath == '/settings' ||
                          currentPath == '/notifications';
        if (!isAllowed) {
          return '/marketplace/dashboard';
        }
      }

      // 3. Normal User Guards
      if (userRole == 'user') {
        final isForbidden = currentPath == '/designer/dashboard' || 
                            currentPath == '/marketplace/dashboard';
        if (isForbidden) {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const HomeDashboardScreen(),
      ),

      GoRoute(
        path: '/marketplace',
        builder: (context, state) => const MarketplaceHomeScreen(),
      ),
      GoRoute(
        path: '/marketplace/cart',
        builder: (context, state) => const ShoppingCartScreen(),
      ),
      GoRoute(
        path: '/marketplace/product/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailsScreen(id: id);
        },
      ),
      GoRoute(
        path: '/marketplace/product/:id/ai-room',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AiRoomResultScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/designers',
        builder: (context, state) => const DesignerDirectoryScreen(),
      ),
      GoRoute(
        path: '/designers/profile/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PublicDesignerProfileScreen(id: id);
        },
      ),
      GoRoute(
        path: '/designers/hire/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return HireRequestScreen(id: id);
        },
      ),
      GoRoute(
        path: '/designer/dashboard',
        builder: (context, state) => const DesignerShellScreen(),
      ),
      GoRoute(
        path: '/collaboration/chat/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DesignerCollaborationScreen(id: id);
        },
      ),
      GoRoute(
        path: '/review/success',
        builder: (context, state) => const ReviewSubmittedScreen(),
      ),
      GoRoute(
        path: '/review/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RateExperienceScreen(id: id);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/marketplace/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/marketplace/order-success',
        builder: (context, state) {
          final orderId = state.uri.queryParameters['orderId'] ?? 'N/A';
          return OrderSuccessScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/marketplace/dashboard',
        builder: (context, state) => const MarketplaceShellScreen(),
      ),
      GoRoute(
        path: '/marketplace/products/add',
        builder: (context, state) => const AddEditProductScreen(),
      ),
      GoRoute(
        path: '/chats',
        builder: (context, state) => const UserChatListScreen(),
      ),
      GoRoute(
        path: '/creations',
        builder: (context, state) => const AiCreationsScreen(),
      ),
      GoRoute(
        path: '/creations/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AiCreationDetailScreen(creationId: id);
        },
      ),
      GoRoute(
        path: '/orders-requests',
        builder: (context, state) {
          final tabStr = state.uri.queryParameters['tab'];
          final initialTab = tabStr == 'orders' ? 1 : 0;
          return UserRequestManagementScreen(initialTab: initialTab);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});

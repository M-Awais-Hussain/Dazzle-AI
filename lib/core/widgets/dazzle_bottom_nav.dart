import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/features/auth/presentation/role_selection_screen.dart';
import 'package:ayyy/features/auth/application/auth_controller.dart';

// --- Marketplace Tab State ---
class MarketplaceTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

final marketplaceTabIndexProvider = NotifierProvider<MarketplaceTabNotifier, int>(() {
  return MarketplaceTabNotifier();
});

// --- Designer Tab State ---
class DesignerTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

final designerTabIndexProvider = NotifierProvider<DesignerTabNotifier, int>(() {
  return DesignerTabNotifier();
});

class DazzleBottomNav extends ConsumerWidget {
  final int currentIndex;

  const DazzleBottomNav({
    super.key,
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRole = ref.watch(selectedRoleProvider);
    final activeRole = ref.watch(currentUserProfileProvider).value?.role ?? selectedRole;

    // 1. Bottom Nav for Marketplace Owner
    if (activeRole == 'marketplace_owner') {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'DASHBOARD',
                  isActive: currentIndex == 0,
                  onTap: () {
                    ref.read(marketplaceTabIndexProvider.notifier).setTab(0);
                    context.go('/marketplace/dashboard');
                  },
                ),
                _NavItem(
                  icon: Icons.inventory_2_outlined,
                  activeIcon: Icons.inventory_2,
                  label: 'PRODUCTS',
                  isActive: currentIndex == 1,
                  onTap: () {
                    ref.read(marketplaceTabIndexProvider.notifier).setTab(1);
                    context.go('/marketplace/dashboard');
                  },
                ),
                _NavItem(
                  icon: Icons.analytics_outlined,
                  activeIcon: Icons.analytics,
                  label: 'ANALYTICS',
                  isActive: currentIndex == 2,
                  onTap: () {
                    ref.read(marketplaceTabIndexProvider.notifier).setTab(2);
                    context.go('/marketplace/dashboard');
                  },
                ),
                _NavItem(
                  icon: Icons.storefront_outlined,
                  activeIcon: Icons.storefront,
                  label: 'PROFILE',
                  isActive: currentIndex == 3,
                  onTap: () {
                    ref.read(marketplaceTabIndexProvider.notifier).setTab(3);
                    context.go('/marketplace/dashboard');
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Bottom Nav for Designer
    if (activeRole == 'designer') {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'STUDIO',
                  isActive: currentIndex == 0,
                  onTap: () {
                    ref.read(designerTabIndexProvider.notifier).setTab(0);
                    context.go('/designer/dashboard');
                  },
                ),
                _NavItem(
                  icon: Icons.brush_outlined,
                  activeIcon: Icons.brush,
                  label: 'PORTFOLIO',
                  isActive: currentIndex == 1,
                  onTap: () {
                    ref.read(designerTabIndexProvider.notifier).setTab(1);
                    context.go('/designer/dashboard');
                  },
                ),
                _NavItem(
                  icon: Icons.mail_outline,
                  activeIcon: Icons.mail,
                  label: 'REQUESTS',
                  isActive: currentIndex == 2,
                  onTap: () {
                    ref.read(designerTabIndexProvider.notifier).setTab(2);
                    context.go('/designer/dashboard');
                  },
                ),
                _NavItem(
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: 'CHATS',
                  isActive: currentIndex == 3,
                  onTap: () {
                    ref.read(designerTabIndexProvider.notifier).setTab(3);
                    context.go('/designer/dashboard');
                  },
                ),
                _NavItem(
                  icon: Icons.payments_outlined,
                  activeIcon: Icons.payments,
                  label: 'EARNINGS',
                  isActive: currentIndex == 4,
                  onTap: () {
                    ref.read(designerTabIndexProvider.notifier).setTab(4);
                    context.go('/designer/dashboard');
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Bottom Nav for Standard User
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'STUDIO',
                isActive: currentIndex == 0,
                onTap: () {
                  context.go('/dashboard');
                },
              ),
              _NavItem(
                icon: Icons.storefront_outlined,
                activeIcon: Icons.storefront,
                label: 'MARKET',
                isActive: currentIndex == 1,
                onTap: () => context.go('/marketplace'),
              ),
              _NavItem(
                icon: Icons.auto_awesome_outlined,
                activeIcon: Icons.auto_awesome,
                label: 'DESIGNS',
                isActive: currentIndex == 2,
                onTap: () => context.go('/creations'),
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'CHATS',
                isActive: currentIndex == 3,
                onTap: () => context.go('/chats'),
              ),
              _NavItem(
                icon: Icons.receipt_long_outlined,
                activeIcon: Icons.receipt_long,
                label: 'REQUESTS',
                isActive: currentIndex == 4,
                onTap: () => context.go('/requests'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? activeIcon : icon,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

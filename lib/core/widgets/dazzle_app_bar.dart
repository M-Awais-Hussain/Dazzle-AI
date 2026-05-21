import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/features/notifications/application/notification_provider.dart';

class DazzleAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final List<Widget>? actions;
  final bool showProfileIcon;
  final String? title;

  const DazzleAppBar({
    super.key,
    this.showBackButton = false,
    this.actions,
    this.showProfileIcon = true,
    this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read realtime unread notification count
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            )
          : null,
      title: Text(
        title ?? 'DAZZLE',
        style: TextStyle(
          fontSize: title != null ? 18 : 16,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: title != null ? 0.5 : 4,
        ),
      ),
      centerTitle: true,
      actions: [
        if (actions != null) ...actions!,
        
        // Premium Real-time Notification Bell (Only shown if profile icon is visible to keep top right clean)
        if (showProfileIcon) ...[
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              onPressed: () => context.push('/notifications'),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_outlined,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 14,
                          minHeight: 14,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Profile Avatar Icon
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => context.push('/settings'),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.textPrimary,
                child: Icon(Icons.person, color: AppColors.textInverse, size: 18),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

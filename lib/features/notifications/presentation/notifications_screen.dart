import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/widgets/dazzle_app_bar.dart';
import 'package:ayyy/core/widgets/dazzle_bottom_nav.dart';
import 'package:ayyy/features/notifications/domain/notification.dart';
import 'package:ayyy/features/notifications/application/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationStreamProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: DazzleAppBar(
        showBackButton: true,
        title: 'Notifications',
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
                ref.read(notificationControllerProvider.notifier).markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Text(
                'Mark all read',
                style: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const DazzleBottomNav(currentIndex: -1),
      body: SafeArea(
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return _buildEmptyState();
            }

            final grouped = _groupNotifications(notifications);

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final group = grouped[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 10, left: 4),
                      child: Text(
                        group.title.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: group.items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, itemIndex) {
                        final notification = group.items[itemIndex];
                        return _buildNotificationCard(context, ref, notification);
                      },
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Failed to load notifications: $err',
              style: GoogleFonts.inter(color: Colors.redAccent),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F3EE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_outlined,
                size: 36,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'All Caught Up!',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You have no new notifications at the moment. We\'ll alert you when something exciting happens.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    final String timeAgo = _formatTimeAgo(notification.createdAt);

    return GestureDetector(
      onTap: () => _handleNotificationTap(context, ref, notification),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.surface : const Color(0xFFFAF8F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead ? AppColors.border : AppColors.primary.withValues(alpha: 0.3),
            width: notification.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            if (!notification.isRead)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar / Icon
            _buildLeadingWidget(notification),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeAgo,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _cleanBody(notification.body),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: notification.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Unread indicator dot
            if (!notification.isRead) ...[
              const SizedBox(width: 8),
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _cleanBody(String rawBody) {
    if (rawBody.startsWith('[ATTACHMENT]|||')) {
      final parts = rawBody.split('|||');
      if (parts.length >= 4) {
        final textContent = parts.sublist(3).join('|||');
        final attachmentName = parts[2].isEmpty ? 'Attachment' : parts[2];
        return textContent.isNotEmpty ? '📎 $textContent' : '📎 $attachmentName';
      }
    }
    return rawBody;
  }

  Widget _buildLeadingWidget(AppNotification notification) {
    // If sender has an avatar, render it
    if (notification.senderAvatarUrl != null && notification.senderAvatarUrl!.isNotEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3EE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            notification.senderAvatarUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildIconFallback(notification.type),
          ),
        ),
      );
    }

    return _buildIconFallback(notification.type);
  }

  Widget _buildIconFallback(String type) {
    IconData iconData = Icons.notifications_outlined;
    Color iconColor = AppColors.textSecondary;
    Color bgColor = const Color(0xFFF5F3EE);

    switch (type) {
      case 'marketplace_order':
        iconData = Icons.shopping_bag_outlined;
        iconColor = AppColors.primary;
        bgColor = const Color(0xFFFAF7F0);
        break;
      case 'designer_request':
        iconData = Icons.design_services_outlined;
        iconColor = AppColors.primary;
        bgColor = const Color(0xFFFAF7F0);
        break;
      case 'designer_response':
        iconData = Icons.assignment_turned_in_outlined;
        iconColor = AppColors.success;
        bgColor = const Color(0xFFEDFBF0);
        break;
      case 'chat':
        iconData = Icons.chat_bubble_outline;
        iconColor = AppColors.primary;
        bgColor = const Color(0xFFFAF7F0);
        break;
      case 'order_status':
        iconData = Icons.local_shipping_outlined;
        iconColor = AppColors.success;
        bgColor = const Color(0xFFEDFBF0);
        break;
      default:
        iconData = Icons.notifications_none_outlined;
        iconColor = AppColors.textSecondary;
        bgColor = const Color(0xFFF5F3EE);
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) async {
    // 1. Mark as read immediately in the DB
    if (!notification.isRead) {
      ref.read(notificationControllerProvider.notifier).markAsRead(notification.id);
    }

    final String? refId = notification.referenceId;

    // 2. Perform role-based contextual routing based on type
    switch (notification.type) {
      case 'chat':
        if (refId != null && refId.isNotEmpty) {
          context.push('/collaboration/chat/$refId');
        } else {
          context.go('/chats');
        }
        break;

      case 'designer_request':
        // Designers manage their hire requests in tab index 2 of the Designer Dashboard shell
        ref.read(designerTabIndexProvider.notifier).setTab(2);
        context.go('/designer/dashboard');
        break;

      case 'designer_response':
        // Users manage their sent designer requests in the Collaborations tab of Request Management
        context.go('/orders-requests?tab=collaborations');
        break;

      case 'marketplace_order':
        // Marketplace Owners manage their incoming orders in tab index 2 of the Marketplace Dashboard shell
        ref.read(marketplaceTabIndexProvider.notifier).setTab(2);
        context.go('/marketplace/dashboard');
        break;

      case 'order_status':
        // Users view their order status history in the Orders tab of Request Management
        context.go('/orders-requests?tab=orders');
        break;

      default:
        // For general or unknown notifications, fallback to role dashboard
        final role = notification.role;
        if (role == 'designer') {
          context.go('/designer/dashboard');
        } else if (role == 'marketplace_owner') {
          context.go('/marketplace/dashboard');
        } else {
          context.go('/dashboard');
        }
        break;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins m ago';
    } else if (difference.inHours < 24) {
      final hrs = difference.inHours;
      return '$hrs h ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days d ago';
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }

  List<_NotificationGroup> _groupNotifications(List<AppNotification> list) {
    final Map<String, List<AppNotification>> map = {};
    final now = DateTime.now();

    for (final item in list) {
      String key = 'Earlier';
      final diff = now.difference(item.createdAt);

      if (diff.inDays == 0 && now.day == item.createdAt.day) {
        key = 'Today';
      } else if (diff.inDays <= 1 || (diff.inDays == 2 && now.day - item.createdAt.day == 1)) {
        key = 'Yesterday';
      } else if (diff.inDays < 7) {
        key = 'This Week';
      }

      if (!map.containsKey(key)) {
        map[key] = [];
      }
      map[key]!.add(item);
    }

    // Sort order: Today first, then Yesterday, then This Week, then Earlier
    final List<String> sortedKeys = [];
    if (map.containsKey('Today')) sortedKeys.add('Today');
    if (map.containsKey('Yesterday')) sortedKeys.add('Yesterday');
    if (map.containsKey('This Week')) sortedKeys.add('This Week');
    if (map.containsKey('Earlier')) sortedKeys.add('Earlier');

    // Add any remaining keys
    for (final k in map.keys) {
      if (!sortedKeys.contains(k)) {
        sortedKeys.add(k);
      }
    }

    return sortedKeys.map((key) => _NotificationGroup(key, map[key]!)).toList();
  }
}

class _NotificationGroup {
  final String title;
  final List<AppNotification> items;

  _NotificationGroup(this.title, this.items);
}

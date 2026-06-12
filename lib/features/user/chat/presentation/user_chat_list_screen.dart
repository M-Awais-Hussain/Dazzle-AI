import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/widgets/dazzle_app_bar.dart';
import 'package:ayyy/core/widgets/dazzle_bottom_nav.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/user/chat/data/chat_repository.dart';
import 'package:intl/intl.dart';

final userChatRoomsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser == null) return const Stream.empty();
  return ref.watch(chatRepositoryProvider).watchChatRooms(currentUser.id);
});

class UserChatListScreen extends ConsumerStatefulWidget {
  const UserChatListScreen({super.key});

  @override
  ConsumerState<UserChatListScreen> createState() => _UserChatListScreenState();
}

class _UserChatListScreenState extends ConsumerState<UserChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatRoomsState = ref.watch(userChatRoomsProvider);

    return Scaffold(
      appBar: const DazzleAppBar(
        showProfileIcon: true,
      ),
      bottomNavigationBar: const DazzleBottomNav(currentIndex: 3),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Search / Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3EE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search conversations...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Active list
            Expanded(
              child: chatRoomsState.when(
                data: (rooms) {
                  final filtered = rooms.where((room) {
                    final name = (room['name'] as String? ?? '').toLowerCase();
                    return name.contains(_searchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final room = filtered[index];
                      return _buildChatRoomItem(room);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Failed to load chats: $e',
                    style: GoogleFonts.inter(color: Colors.redAccent),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatRoomItem(Map<String, dynamic> room) {
    final String roomId = room['id'];
    final String name = room['name'] ?? 'Anonymous';
    final String? avatarUrl = room['avatar_url'];
    final String roleLabel = room['role_label'] ?? 'Client';
    final String lastMessage = room['last_message'] ?? 'No messages yet';
    final DateTime lastMessageTime = room['last_message_time'] ?? DateTime.now();

    // Format timestamp nicely
    String timeStr = '';
    final now = DateTime.now();
    final difference = now.difference(lastMessageTime);

    if (lastMessageTime.year == 1970) {
      timeStr = '';
    } else if (difference.inDays == 0) {
      timeStr = DateFormat('hh:mm a').format(lastMessageTime);
    } else if (difference.inDays == 1) {
      timeStr = 'Yesterday';
    } else {
      timeStr = DateFormat('MMM dd').format(lastMessageTime);
    }

    // Role label color
    Color roleBg = Colors.grey.withValues(alpha: 0.12);
    Color roleText = AppColors.textSecondary;

    if (roleLabel == 'Designer') {
      roleBg = AppColors.primary.withValues(alpha: 0.12);
      roleText = AppColors.textPrimary;
    } else if (roleLabel == 'Shop Owner') {
      roleBg = AppColors.success.withValues(alpha: 0.12);
      roleText = AppColors.success;
    }

    return InkWell(
      onTap: () => context.push('/collaboration/chat/$roomId'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3EE),
                    shape: BoxShape.circle,
                  ),
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: AppColors.textSecondary),
                          ),
                        )
                      : const Icon(Icons.person, color: AppColors.textSecondary),
                ),
                // Premium online dot (can be dynamically toggled)
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: roleBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          roleLabel.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: roleText,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lastMessage,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Time / Badges
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtly simulated unread badge
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.transparent, // Keeps alignment neat, can set to AppColors.primary
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F3EE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 32,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Conversations Yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Active chats with verified designers and marketplace partners will stream live here once your requests are accepted.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/designers'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'BROWSE PARTNERS',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

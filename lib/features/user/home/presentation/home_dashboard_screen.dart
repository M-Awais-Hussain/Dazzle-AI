import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/widgets/dazzle_app_bar.dart';
import 'package:ayyy/core/widgets/dazzle_bottom_nav.dart';
import 'package:ayyy/features/auth/application/auth_controller.dart';
import 'package:ayyy/features/user/home/application/user_studio_stats_provider.dart';
import 'package:ayyy/features/user/marketplace/application/ai_creations_provider.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider).value;
    final userName = userProfile?.name ?? 'Julian';
    final statsAsync = ref.watch(userStudioStatsStreamProvider);

    return Scaffold(
      appBar: const DazzleAppBar(),
      bottomNavigationBar: const DazzleBottomNav(currentIndex: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Greeting
            Text(
              'Hello, $userName',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your AI interior concierge is ready.\nWhat shall we transform today?',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Live Studio Stats Grid
            statsAsync.when(
              data: (stats) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'STUDIO STATUS',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _StatsCard(
                        title: 'AI Creations',
                        value: stats.aiCreationsCount.toString(),
                        icon: Icons.auto_awesome_outlined,
                        iconColor: const Color(0xFF9C27B0),
                        onTap: () {},
                      ),
                      _StatsCard(
                        title: 'Active Consults',
                        value: stats.activeConsultationsCount.toString(),
                        icon: Icons.design_services_outlined,
                        iconColor: const Color(0xFF2196F3),
                        onTap: () => context.push('/orders-requests'),
                      ),
                      _StatsCard(
                        title: 'Pending Bookings',
                        value: stats.pendingBookingsCount.toString(),
                        icon: Icons.pending_actions_outlined,
                        iconColor: const Color(0xFFFF9800),
                        onTap: () => context.push('/orders-requests'),
                      ),
                      _StatsCard(
                        title: 'Active Orders',
                        value: stats.activeOrdersCount.toString(),
                        icon: Icons.shopping_bag_outlined,
                        iconColor: const Color(0xFF4CAF50),
                        onTap: () => context.push('/orders-requests?tab=orders'),
                      ),
                    ],
                  ),
                  const _RecentGenerations(),
                  const SizedBox(height: 24),
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
              error: (err, _) => const SizedBox.shrink(),
            ),

            // Hire a Designer Card
            _ActionCard(
              icon: Icons.architecture_outlined,
              title: 'Hire a Designer',
              description: 'Connect with our curated network of world-class interior architects for a bespoke consultation.',
              onTap: () => context.push('/designers'),
            ),
            const SizedBox(height: 20),

            // Explore Marketplace Card
            _ActionCard(
              icon: Icons.storefront_outlined,
              title: 'Explore Marketplace',
              description: 'Shop the exact pieces featured in your AI renders from our premium furniture partners.',
              showAvatars: true,
              onTap: () => context.push('/marketplace'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}



// Simple action card with icon + text
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool showAvatars;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    this.showAvatars = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3EE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.textSecondary, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            if (showAvatars) ...[
              const SizedBox(height: 12),
              Row(
                children: List.generate(
                  3,
                  (i) => Container(
                    margin: EdgeInsets.only(left: i == 0 ? 0 : 0),
                    transform: Matrix4.translationValues(i * -8.0, 0, 0),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: [
                        AppColors.primary,
                        const Color(0xFF555555),
                        const Color(0xFFAAA089),
                      ][i],
                      child: Icon(Icons.person, size: 14, color: AppColors.textInverse),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _StatsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<_StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends State<_StatsCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.05),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.iconColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.iconColor,
                      size: 16,
                    ),
                  ),
                ],
              ),
              Text(
                widget.value,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentGenerations extends ConsumerWidget {
  const _RecentGenerations();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentCreationsAsync = ref.watch(recentCreationsProvider);

    return recentCreationsAsync.when(
      data: (creations) {
        if (creations.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT STUDIO DESIGNS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '${creations.length} Total',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: creations.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final creation = creations[index];
                  return GestureDetector(
                    onTap: () => context.push('/creations/${creation.id}'),
                    child: Container(
                      width: 140,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.05),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (creation.generatedImageUrl.isNotEmpty)
                              Image.network(
                                creation.generatedImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFFF5F3EE),
                                  child: const Icon(
                                    Icons.broken_image_outlined,
                                    color: AppColors.textSecondary,
                                    size: 28,
                                  ),
                                ),
                              )
                            else
                              Container(
                                color: const Color(0xFFF5F3EE),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                            // Subtle Dark overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.7),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: 10,
                              right: 10,
                              child: Text(
                                creation.productName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/features/auth/application/auth_controller.dart';
import 'package:ayyy/core/widgets/dazzle_app_bar.dart';
import 'package:ayyy/core/widgets/dazzle_bottom_nav.dart';
import 'package:ayyy/features/designer/earnings/application/designer_earnings_controller.dart';
import 'package:ayyy/features/designer/requests/application/designer_request_controller.dart';
import 'package:ayyy/features/designer/portfolio/application/portfolio_controller.dart';

class DesignerDashboardScreen extends ConsumerWidget {
  const DesignerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(currentUserProfileProvider).value;
    final userName = userProfile?.name ?? 'Designer';

    final stats = ref.watch(designerStatsProvider);
    final requestsAsync = ref.watch(designerRequestsProvider);
    final projectsAsync = ref.watch(designerProjectsProvider);

    return Scaffold(
      appBar: const DazzleAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(designerEarningsProvider);
          ref.invalidate(designerRequestsProvider);
          ref.invalidate(designerProjectsProvider);
          ref.invalidate(designerReviewsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Welcome back,\n$userName',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage your projects and client collaborations.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Stats Cards Grid
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.work_outline,
                      value: '${stats.activeProjects}',
                      label: 'Active Projects',
                      iconColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.attach_money,
                      value: '\$${stats.totalEarnings.toStringAsFixed(0)}',
                      label: 'Earnings',
                      iconColor: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.star_outline,
                      value: '${stats.averageRating}',
                      label: 'Avg Rating',
                      iconColor: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.people_outline,
                      value: '${stats.activeProjects + stats.pendingRequests}',
                      label: 'Total Clients',
                      iconColor: const Color(0xFF7C8FFF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Client Requests Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Client Requests',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ref.read(designerTabIndexProvider.notifier).setTab(2);
                    },
                    child: Text(
                      'View All',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              requestsAsync.when(
                data: (requests) {
                  final pending = requests.where((r) => r.status == 'pending').toList();
                  if (pending.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          'No pending client requests.',
                          style: GoogleFonts.inter(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pending.length > 2 ? 2 : pending.length,
                    itemBuilder: (context, index) {
                      final req = pending[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F3EE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.person, color: AppColors.textSecondary, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${req.userName} — ${req.roomType}',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Budget: ${req.budget}',
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                ref.read(designerTabIndexProvider.notifier).setTab(2);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                                textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              child: const Text('Respond'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (err, st) => Center(child: Text('Error loading requests: $err')),
              ),
              const SizedBox(height: 28),

              // Portfolio Highlights Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Portfolio',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ref.read(designerTabIndexProvider.notifier).setTab(1);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add, color: AppColors.textPrimary, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              projectsAsync.when(
                data: (projects) {
                  if (projects.isEmpty) {
                    return Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'No portfolio projects added yet.',
                          style: GoogleFonts.inter(color: AppColors.textSecondary),
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: projects.length > 4 ? 4 : projects.length,
                    itemBuilder: (context, index) {
                      final proj = projects[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F3EE),
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(proj.images.first),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(12),
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            proj.title,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (err, st) => Center(child: Text('Error loading projects: $err')),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

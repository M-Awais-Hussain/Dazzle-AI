import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/widgets/dazzle_app_bar.dart';
import 'package:ayyy/core/widgets/dazzle_bottom_nav.dart';
import 'package:ayyy/features/user/designer_directory/application/designer_directory_providers.dart';
import 'package:ayyy/features/common/review/application/review_controller.dart';
import 'package:ayyy/features/designer/portfolio/domain/portfolio_project.dart';
class PublicDesignerProfileScreen extends ConsumerWidget {
  final String id;
  const PublicDesignerProfileScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final designerDetailsState = ref.watch(publicDesignerDetailsProvider(id));

    return Scaffold(
      appBar: DazzleAppBar(
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: const DazzleBottomNav(currentIndex: -1),
      body: designerDetailsState.when(
        data: (designer) {
          final String name = designer['full_name'] ?? 'Designer';
          final String avatarUrl = designer['avatar_url'] ?? '';
          final designerProfile = designer['designer_profiles'] as Map<String, dynamic>?;
          final List<String> tags = List<String>.from(designerProfile?['expertise'] ?? []);
          final String specialty = tags.isNotEmpty
              ? '${tags.join(" & ")} Specialist'
              : 'Interior Architect';
          final int experience = designerProfile?['experience_years'] ?? 0;
          final double consultationPrice = (designerProfile?['consultation_price'] as num?)?.toDouble() ?? 0.0;
          final String responseTime = designerProfile?['response_time'] ?? 'Within hours';
          final String bio = designerProfile?['bio'] ?? 'Luxury minimalist interior architect & design specialist.';

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Avatar
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3EE),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: avatarUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 44, color: AppColors.textSecondary),
                          ),
                        )
                      : const Icon(Icons.person, size: 44, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  specialty,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        final stats = ref.watch(designerRatingStatsProvider(id));
                        return Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 16,
                              color: stats.totalReviews > 0
                                  ? Colors.amber
                                  : AppColors.textSecondary.withValues(alpha: 0.4),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              stats.totalReviews > 0
                                  ? '${stats.averageRating.toStringAsFixed(1)} (${stats.totalReviews} ${stats.totalReviews == 1 ? "Review" : "Reviews"})'
                                  : 'No Reviews Yet',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Bio Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    bio,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Stats
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3EE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ProfileStat(value: 'Rs. ${consultationPrice.toStringAsFixed(0)}', label: 'Consultation'),
                      Container(width: 1, height: 32, color: AppColors.border),
                      _ProfileStat(value: '$experience Yrs', label: 'Experience'),
                      Container(width: 1, height: 32, color: AppColors.border),
                      _ProfileStat(value: responseTime, label: 'Response'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Hire button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => context.push('/designers/hire/$id'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Hire Designer',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Portfolio Showcase
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Portfolio Showcase',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Consumer(
                        builder: (context, ref, child) {
                          final portfolioState = ref.watch(publicDesignerPortfolioProvider(id));
                          return portfolioState.when(
                            data: (projects) {
                              if (projects.isEmpty) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 48),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.collections_outlined, size: 36, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No portfolio projects yet',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return SizedBox(
                                height: 260,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: projects.length,
                                  itemBuilder: (context, index) {
                                    final project = projects[index];
                                    final imageUrl = project.images.isNotEmpty ? project.images.first : '';

                                    return GestureDetector(
                                      onTap: () {
                                        // Open sliding window full screen
                                        _showPortfolioFullScreen(context, project);
                                      },
                                      child: Container(
                                        width: 200,
                                        margin: const EdgeInsets.only(right: 16),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: imageUrl.isNotEmpty
                                                  ? Image.network(
                                                      imageUrl,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, color: AppColors.textSecondary)),
                                                    )
                                                  : Container(
                                                      width: double.infinity,
                                                      color: const Color(0xFFF5F3EE),
                                                      child: const Icon(Icons.image, color: AppColors.textSecondary),
                                                    ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    project.title,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.textPrimary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    project.projectType,
                                                    style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            error: (e, _) => Center(
                              child: Text(
                                'Error loading portfolio',
                                style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Reviews Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Consumer(
                    builder: (context, ref, child) {
                      final stats = ref.watch(designerRatingStatsProvider(id));
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Client Reviews & Feedback',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Ratings Summary Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                // Big Rating Number
                                Column(
                                  children: [
                                    Text(
                                      stats.totalReviews > 0
                                          ? stats.averageRating.toStringAsFixed(1)
                                          : '0.0',
                                      style: GoogleFonts.inter(
                                        fontSize: 44,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: List.generate(
                                        5,
                                        (index) => Icon(
                                          Icons.star,
                                          size: 14,
                                          color: index < stats.averageRating.round()
                                              ? Colors.amber
                                              : AppColors.textSecondary.withValues(alpha: 0.3),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${stats.totalReviews} ${stats.totalReviews == 1 ? "review" : "reviews"}',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 24),
                                // Star breakdown progress lines
                                Expanded(
                                  child: Column(
                                    children: List.generate(5, (index) {
                                      final starLevel = 5 - index;
                                      final count = stats.starBreakdown[starLevel] ?? 0;
                                      final double percent = stats.totalReviews > 0
                                          ? count / stats.totalReviews
                                          : 0.0;

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                                        child: Row(
                                          children: [
                                            Text(
                                              '$starLevel',
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(2),
                                                child: LinearProgressIndicator(
                                                  value: percent,
                                                  backgroundColor: const Color(0xFFF5F3EE),
                                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                                    AppColors.primary,
                                                  ),
                                                  minHeight: 5,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 18,
                                              child: Text(
                                                '$count',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: AppColors.textSecondary,
                                                ),
                                                textAlign: TextAlign.end,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // List of reviews
                          ref.watch(designerReviewsProvider(id)).when(
                                data: (reviews) {
                                  if (reviews.isEmpty) {
                                    return Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 36),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F3EE),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'No client reviews shared yet.',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  return ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: reviews.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final r = reviews[index];
                                      final dateFormatted = '${r.createdAt.year}/${r.createdAt.month}/${r.createdAt.day}';

                                      return Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF5F3EE),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: r.reviewerAvatarUrl != null && r.reviewerAvatarUrl!.isNotEmpty
                                                      ? ClipRRect(
                                                          borderRadius: BorderRadius.circular(10),
                                                          child: Image.network(
                                                            r.reviewerAvatarUrl!,
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (context, e, st) =>
                                                                const Icon(Icons.person, size: 18, color: AppColors.textSecondary),
                                                          ),
                                                        )
                                                      : const Icon(Icons.person, size: 18, color: AppColors.textSecondary),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        r.reviewerName ?? 'Client Reviewer',
                                                        style: GoogleFonts.inter(
                                                          fontSize: 13,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppColors.textPrimary,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        dateFormatted,
                                                        style: GoogleFonts.inter(
                                                          fontSize: 11,
                                                          color: AppColors.textSecondary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Row(
                                                  children: List.generate(
                                                    5,
                                                    (i) => Icon(
                                                      Icons.star,
                                                      size: 12,
                                                      color: i < r.rating
                                                          ? Colors.amber
                                                          : AppColors.textSecondary.withValues(alpha: 0.2),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              r.review,
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: AppColors.textPrimary,
                                                height: 1.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                loading: () => const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                error: (e, _) => const SizedBox.shrink(),
                              ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Failed to load designer profile: $e',
              style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

void _showPortfolioFullScreen(BuildContext context, PortfolioProject project) {
  showDialog(
    context: context,
    barrierColor: AppColors.surface, // Full screen background
    builder: (BuildContext context) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const DazzleAppBar(
          title: 'Project Portfolio',
          showBackButton: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image slider
              if (project.images.isNotEmpty)
                SizedBox(
                  height: 350,
                  child: PageView.builder(
                    itemCount: project.images.length,
                    itemBuilder: (context, index) {
                      return Image.network(
                        project.images[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 48, color: AppColors.textSecondary)),
                      );
                    },
                  ),
                )
              else
                Container(
                  height: 350,
                  color: const Color(0xFFF5F3EE),
                  child: const Center(child: Icon(Icons.image, size: 48, color: AppColors.textSecondary)),
                ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${project.projectType} • ${project.completionTime}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      project.description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (project.styleTags.isNotEmpty) ...[
                      Text(
                        'Style & Aesthetics',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: project.styleTags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3EE),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

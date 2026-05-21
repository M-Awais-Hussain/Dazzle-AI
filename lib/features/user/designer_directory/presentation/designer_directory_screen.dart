import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/widgets/dazzle_app_bar.dart';
import 'package:ayyy/core/widgets/dazzle_bottom_nav.dart';
import 'package:ayyy/features/user/designer_directory/application/designer_directory_providers.dart';

class DesignerDirectoryScreen extends ConsumerStatefulWidget {
  const DesignerDirectoryScreen({super.key});

  @override
  ConsumerState<DesignerDirectoryScreen> createState() => _DesignerDirectoryScreenState();
}

class _DesignerDirectoryScreenState extends ConsumerState<DesignerDirectoryScreen> {
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
    final designersState = ref.watch(publicDesignersProvider);

    return Scaffold(
      appBar: const DazzleAppBar(),
      bottomNavigationBar: const DazzleBottomNav(currentIndex: -1),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Header
            Text(
              'CURATED EXPERTISE',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Design Partners',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Connect with our elite circle of AI-enhanced interior architects. Each designer is verified for aesthetic excellence and technical precision.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Search bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name or aesthetic...',
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
            const SizedBox(height: 20),

            // Designer list
            designersState.when(
              data: (designers) {
                final filtered = designers.where((designer) {
                  final name = (designer['full_name'] as String? ?? '').toLowerCase();
                  final designerProfile = designer['designer_profiles'] as Map<String, dynamic>?;
                  final expertise = List<String>.from(designerProfile?['expertise'] ?? []);
                  final matchesExpertise = expertise.any((tag) => tag.toLowerCase().contains(_searchQuery));
                  return name.contains(_searchQuery) || matchesExpertise;
                }).toList();

                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.face_retouching_natural, size: 44, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'No designers match your query',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final designer = filtered[index];
                    final designerProfile = designer['designer_profiles'] as Map<String, dynamic>?;
                    final String id = designer['id'] ?? '';
                    final String name = designer['full_name'] ?? 'Anonymous';
                    final String avatarUrl = designer['avatar_url'] ?? '';
                    final List<String> tags = List<String>.from(designerProfile?['expertise'] ?? []);
                    final bool isAvailable = designerProfile?['is_available'] ?? true;
                    final int experience = designerProfile?['experience_years'] ?? 0;

                    return _DesignerCard(
                      name: name,
                      avatarUrl: avatarUrl,
                      rating: 5.0, // Standard verified partner rating
                      experienceYears: experience,
                      tags: tags.take(3).toList(),
                      status: isAvailable ? 'AVAILABLE' : 'IN SESSION',
                      statusColor: isAvailable ? AppColors.success : AppColors.primary,
                      onTap: () => context.push('/designers/profile/$id'),
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Text(
                    'Failed to load designers: $e',
                    style: GoogleFonts.inter(color: Colors.redAccent),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DesignerCard extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final double rating;
  final int experienceYears;
  final List<String> tags;
  final String status;
  final Color statusColor;
  final VoidCallback onTap;

  const _DesignerCard({
    required this.name,
    required this.avatarUrl,
    required this.rating,
    required this.experienceYears,
    required this.tags,
    required this.status,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3EE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: avatarUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            avatarUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: AppColors.textSecondary, size: 28),
                          ),
                        )
                      : const Icon(Icons.person, color: AppColors.textSecondary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(5, (i) {
                            return Icon(
                              Icons.star,
                              size: 12,
                              color: i < rating.floor() ? Colors.amber : const Color(0xFFE0E0E0),
                            );
                          }),
                          const SizedBox(width: 6),
                          Text(
                            '($rating)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (status.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Experience & Tags
            Row(
              children: [
                Text(
                  'EXPERIENCE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$experienceYears Yrs',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                ...tags.map((tag) {
                  return Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3EE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

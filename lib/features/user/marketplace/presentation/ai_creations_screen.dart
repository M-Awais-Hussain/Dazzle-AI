import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/widgets/dazzle_app_bar.dart';
import 'package:ayyy/core/widgets/dazzle_bottom_nav.dart';
import 'package:ayyy/features/user/marketplace/application/ai_creations_provider.dart';
import 'package:ayyy/features/user/marketplace/application/ai_room_controller.dart';
import 'package:ayyy/features/user/marketplace/data/product_repository.dart';
import 'package:ayyy/features/user/marketplace/domain/ai_creation.dart';

class AiCreationsScreen extends ConsumerStatefulWidget {
  const AiCreationsScreen({super.key});

  @override
  ConsumerState<AiCreationsScreen> createState() => _AiCreationsScreenState();
}

class _AiCreationsScreenState extends ConsumerState<AiCreationsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(aiCreationsProvider.notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(aiCreationsProvider);
    final filter = ref.watch(aiCreationsFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DazzleAppBar(showBackButton: false),
      bottomNavigationBar: const DazzleBottomNav(
        currentIndex: 2,
      ), // Index 2 is DESIGNS
      body: RefreshIndicator(
        onRefresh: () => ref.read(aiCreationsProvider.notifier).refresh(),
        color: AppColors.primaryDark,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ── Header Title & Subtitle ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STUDIO DESIGN ARCHIVE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'My AI Creations',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Search & Filter Controls ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search by product...',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (val) {
                            ref
                                .read(aiCreationsFilterProvider.notifier)
                                .update(
                                  (state) => state.copyWith(searchQuery: val),
                                );
                          },
                        ),
                      ),
                      if (filter.searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            ref
                                .read(aiCreationsFilterProvider.notifier)
                                .update(
                                  (state) => state.copyWith(searchQuery: ''),
                                );
                          },
                          child: const Icon(
                            Icons.close,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        height: 24,
                        width: 1,
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.tune,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                        tooltip: 'Sort creations',
                        onSelected: (val) {
                          ref
                              .read(aiCreationsFilterProvider.notifier)
                              .update((state) => state.copyWith(sortBy: val));
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'newest',
                            child: Text(
                              'Newest First',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: filter.sortBy == 'newest'
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'oldest',
                            child: Text(
                              'Oldest First',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: filter.sortBy == 'oldest'
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'product',
                            child: Text(
                              'Product Name',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: filter.sortBy == 'product'
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Gallery Body ──
            stateAsync.when(
              data: (data) {
                if (data.creations.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index < data.creations.length) {
                          final creation = data.creations[index];
                          return _CreationCard(creation: creation);
                        } else {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }
                      },
                      childCount:
                          data.creations.length + (data.isFetchingMore ? 1 : 0),
                    ),
                  ),
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const _ShimmerCreationCard(),
                    childCount: 4,
                  ),
                ),
              ),
              error: (err, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Connection Error',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          err.toString(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 40,
                color: Color(0xFFDCD5C5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Creations Yet',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore our curated marketplace, pick a luxury piece, and visualize it inside your room in real-time!',
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
              width: 220,
              child: ElevatedButton(
                onPressed: () {
                  context.go('/marketplace');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'EXPLORE CURATED PIECES',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
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

// ──────────────────────────────────────────
// Creation Gallery Card Widget
// ──────────────────────────────────────────

class _CreationCard extends ConsumerWidget {
  final AiCreation creation;

  const _CreationCard({required this.creation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('MMMM d, yyyy').format(creation.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Composite Image Stack ──
          GestureDetector(
            onTap: () => context.push('/creations/${creation.id}'),
            child: AspectRatio(
              aspectRatio: 1.3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: Image.network(
                      creation.generatedImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFFF5F3EE),
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textSecondary,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  // Dark bottom gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                  // ── Original room bubble in corner ──
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.network(
                          creation.roomImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: Colors.white,
                            child: const Icon(
                              Icons.home_outlined,
                              size: 20,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Version Badge ──
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        creation.generationVersion.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Details Area ──
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        creation.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (creation.productDescription != null &&
                    creation.productDescription!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    creation.productDescription!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0x0A000000)),
                const SizedBox(height: 14),

                // ── Card Action Row ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Deletion with confirmation
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      tooltip: 'Delete Creation',
                      onPressed: () {
                        _showDeleteConfirmDialog(context, ref);
                      },
                    ),
                    const Spacer(),
                    // Prepopulated Regeneration Button
                    TextButton.icon(
                      onPressed: () => _triggerRegeneration(context, ref),
                      icon: const Icon(
                        Icons.refresh,
                        size: 14,
                        color: AppColors.textPrimary,
                      ),
                      label: Text(
                        'REGENERATE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete saved design?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to remove this design and delete the generated image from history?',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(deleteCreationProvider.notifier)
                  .initiateDeletion(context, creation);
            },
            child: const Text(
              'DELETE',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerRegeneration(BuildContext context, WidgetRef ref) async {
    // 1. Fetch complete Product from ID to make sure it matches the pipeline requirements
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final product = await ref
          .read(productRepositoryProvider)
          .getProductById(creation.productId);

      if (context.mounted) {
        Navigator.pop(context); // pop loading

        // 2. Prepare state in aiRoomControllerProvider
        ref.read(aiRoomControllerProvider.notifier).prepareCanvas(
          product: product,
          selectedImageUrl: creation.selectedProductImageUrl,
          roomImagePath: creation.roomImageUrl,
        );

        // 3. Navigate directly to canvas editor to reposition
        context.push('/marketplace/product/${product.id}/canvas-editor');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // pop loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize regeneration: $e')),
        );
      }
    }
  }
}

// ──────────────────────────────────────────
// Shimmer Skeleton Creation Card Widget
// ──────────────────────────────────────────

class _ShimmerCreationCard extends StatefulWidget {
  const _ShimmerCreationCard();

  @override
  State<_ShimmerCreationCard> createState() => _ShimmerCreationCardState();
}

class _ShimmerCreationCardState extends State<_ShimmerCreationCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerGradient = LinearGradient(
          colors: const [
            Color(0xFFEBE9E2),
            Color(0xFFF6F4ED),
            Color(0xFFEBE9E2),
          ],
          stops: [
            (_shimmerController.value - 0.3).clamp(0.0, 1.0),
            _shimmerController.value,
            (_shimmerController.value + 0.3).clamp(0.0, 1.0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          height: 380,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.04),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: shimmerGradient,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            height: 18,
                            width: 150,
                            decoration: BoxDecoration(
                              gradient: shimmerGradient,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            height: 12,
                            width: 80,
                            decoration: BoxDecoration(
                              gradient: shimmerGradient,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: shimmerGradient,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0x0A000000)),
                      Row(
                        children: [
                          Container(
                            height: 20,
                            width: 20,
                            decoration: BoxDecoration(
                              gradient: shimmerGradient,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            height: 32,
                            width: 120,
                            decoration: BoxDecoration(
                              gradient: shimmerGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

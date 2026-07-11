import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/widgets/dazzle_app_bar.dart';
import 'package:ayyy/features/user/marketplace/application/design_creations_provider.dart';
import 'package:ayyy/features/user/marketplace/application/room_design_controller.dart';
import 'package:ayyy/features/user/marketplace/data/product_repository.dart';
import 'package:ayyy/features/user/marketplace/domain/design_creation.dart';
import 'package:ayyy/features/user/marketplace/domain/product.dart';
import 'package:ayyy/features/user/designer_directory/application/designer_directory_providers.dart';

class DesignCreationDetailScreen extends ConsumerStatefulWidget {
  final String creationId;

  const DesignCreationDetailScreen({
    super.key,
    required this.creationId,
  });

  @override
  ConsumerState<DesignCreationDetailScreen> createState() => _DesignCreationDetailScreenState();
}

class _DesignCreationDetailScreenState extends ConsumerState<DesignCreationDetailScreen> {
  // Comparative mode: 0 = Slider, 1 = Generated, 2 = Original
  int _viewMode = 0;
  double _sliderPos = 0.5;

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(aiCreationDetailProvider(widget.creationId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const DazzleAppBar(
        showBackButton: true,
        showProfileIcon: false,
        title: 'DESIGN DETAILS',
      ),
      body: detailAsync.when(
        data: (creation) => _buildContent(context, creation),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load creation details',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('GO BACK'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DesignCreation creation) {
    final dateStr = DateFormat('MMMM d, yyyy • hh:mm a').format(creation.createdAt);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── COMPARATIVE IMAGE CONTAINER ──
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
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
              children: [
                // Image display based on mode
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: AspectRatio(
                    aspectRatio: 1.3,
                    child: _buildComparisonImage(creation),
                  ),
                ),

                // Mode Tabs (Slider / Generated / Original)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ViewModeTabButton(
                          label: 'COMPARE',
                          isActive: _viewMode == 0,
                          onPressed: () => setState(() => _viewMode = 0),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _ViewModeTabButton(
                          label: 'GENERATED',
                          isActive: _viewMode == 1,
                          onPressed: () => setState(() => _viewMode = 1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _ViewModeTabButton(
                          label: 'ORIGINAL',
                          isActive: _viewMode == 2,
                          onPressed: () => setState(() => _viewMode = 2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── METADATA & PROMPT PANEL ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.04),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GENERATION ARCHIVE',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    creation.productName,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0x0A000000)),
                  const SizedBox(height: 16),

                  // Prompt Container
                  Text(
                    'GENERATION PROMPT',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.03),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.format_quote_rounded,
                          color: Color(0xFFDCD5C5),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            creation.generationPrompt,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textPrimary.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── PRODUCT INTEGRATION ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ProductIntegrationCard(
              creation: creation,
              ref: ref,
            ),
          ),

          const SizedBox(height: 24),

          // ── SYSTEM CONTROL ACTIONS (REGENERATE / SHARE / DELETE) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Regenerate
                Expanded(
                  flex: 5,
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _triggerRegeneration(context, ref, creation),
                      icon: const Icon(Icons.refresh, size: 16, color: AppColors.textPrimary),
                      label: Text(
                        'REGENERATE DESIGN',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.textPrimary, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Share (Link copy)
                SizedBox(
                  height: 48,
                  width: 52,
                  child: OutlinedButton(
                    onPressed: () => _copyDesignLink(context, creation),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3), width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.white,
                    ),
                    child: const Icon(Icons.ios_share, color: AppColors.textPrimary, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                // Delete
                SizedBox(
                  height: 48,
                  width: 52,
                  child: OutlinedButton(
                    onPressed: () => _showDeleteConfirmDialog(context, ref, creation),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.2), width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.white,
                    ),
                    child: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 10),
          
          // ── Share with Designer CTA ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(pendingHireAttachmentProvider.notifier).setMultiple([creation.generatedImageUrl]);
                  context.push('/designers');
                },
                icon: const Icon(Icons.people_outline, size: 16),
                label: Text(
                  'HIRE DESIGNER',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildComparisonImage(DesignCreation creation) {
    if (_viewMode == 1) {
      // Generated Image only
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            creation.generatedImageUrl,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 16,
            right: 16,
            child: _buildBadge('GENERATED DESIGN'),
          ),
        ],
      );
    } else if (_viewMode == 2) {
      // Original Space only
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            creation.roomImageUrl,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 16,
            right: 16,
            child: _buildBadge('ORIGINAL SPACE'),
          ),
        ],
      );
    } else {
      // Slider Mode
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _sliderPos = (_sliderPos + details.primaryDelta! / width).clamp(0.0, 1.0);
              });
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Base/Before Image (Original Space on right, when top is clipped out)
                Image.network(
                  creation.roomImageUrl,
                  fit: BoxFit.cover,
                ),

                // Reveal/After Image (AI Creation on left) clipped to slider position
                ClipRect(
                  clipper: _SliderClipper(_sliderPos),
                  child: Image.network(
                    creation.generatedImageUrl,
                    fit: BoxFit.cover,
                  ),
                ),

                // Sliding vertical line divider
                Positioned(
                  left: _sliderPos * width - 1,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

                // Handle Button
                Positioned(
                  left: _sliderPos * width - 18,
                  top: height / 2 - 18,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.unfold_more_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ),

                // Direction Instruction (Shows subtly)
                if (_sliderPos > 0.4 && _sliderPos < 0.6)
                  IgnorePointer(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Drag handle to compare',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<void> _triggerRegeneration(BuildContext context, WidgetRef ref, DesignCreation creation) async {
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
        
        // Prepare canvas with existing generation data
        ref.read(roomDesignControllerProvider.notifier).prepareCanvas(
          product: product,
          selectedImageUrl: creation.selectedProductImageUrl,
          roomImagePath: creation.roomImageUrl,
        );
        
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

  void _copyDesignLink(BuildContext context, DesignCreation creation) {
    Clipboard.setData(ClipboardData(text: creation.generatedImageUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Design image link copied to clipboard!',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF1E1E1E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, DesignCreation creation) {
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
              Navigator.pop(ctx); // Pop dialog
              context.pop(); // Pop details screen back to gallery
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
}

// ── COMPARATOR CLIPPER ──
class _SliderClipper extends CustomClipper<Rect> {
  final double percent;

  _SliderClipper(this.percent);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(0.0, 0.0, size.width * percent, size.height);
  }

  @override
  bool shouldReclip(_SliderClipper oldClipper) => oldClipper.percent != percent;
}

// ── VIEW MODE TAB BUTTON ──
class _ViewModeTabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _ViewModeTabButton({
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: isActive ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: isActive ? Colors.white : AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ── PRODUCT INTEGRATION CARD ──
class _ProductIntegrationCard extends ConsumerWidget {
  final DesignCreation creation;
  final WidgetRef ref;

  const _ProductIntegrationCard({
    required this.creation,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Try to watch or fetch full Product details using a FutureBuilder
    // to obtain live price, stock status, and to allow adding to cart
    final productFuture = ref.watch(productDetailsProvider(creation.productId));

    return productFuture.when(
      data: (product) => _buildLiveProductCard(context, product),
      loading: () => _buildCachedPlaceholderCard(context, isLoading: true),
      error: (_, _) => _buildCachedPlaceholderCard(context, isLoading: false),
    );
  }

  Widget _buildLiveProductCard(BuildContext context, Product product) {
    final inStock = product.stock > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.chair_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRODUCT INTEGRATED',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Rs. ${product.price.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: inStock
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            inStock ? 'IN STOCK' : 'OUT OF STOCK',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: inStock ? AppColors.success : AppColors.error,
                              letterSpacing: 0.5,
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
          const SizedBox(height: 16),
          Text(
            product.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('/marketplace/product/${product.id}');
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text(
                'VIEW PRODUCT DETAILS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                disabledBackgroundColor: AppColors.textSecondary.withValues(alpha: 0.15),
                disabledForegroundColor: AppColors.textSecondary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCachedPlaceholderCard(BuildContext context, {required bool isLoading}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    creation.selectedProductImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.chair_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRODUCT INTEGRATED',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      creation.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isLoading ? 'Fetching details...' : 'Details unavailable',
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
          if (creation.productDescription != null && creation.productDescription!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              creation.productDescription!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: null, // Disabled when details are not fully loaded or unavailable
              icon: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textSecondary))
                  : const Icon(Icons.shopping_bag_outlined, size: 16),
              label: Text(
                'ORDER INTEGRATED PIECE',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                disabledBackgroundColor: AppColors.textSecondary.withValues(alpha: 0.1),
                disabledForegroundColor: AppColors.textSecondary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── FUTURE PROVIDER FAMILY FOR PRODUCT DETAILS ──
final productDetailsProvider = FutureProvider.family<Product, String>((ref, id) async {
  final repo = ref.read(productRepositoryProvider);
  return repo.getProductById(id);
});

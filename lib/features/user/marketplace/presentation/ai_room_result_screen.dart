import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/widgets/dazzle_app_bar.dart';
import 'package:ayyy/features/user/marketplace/application/ai_room_controller.dart';
import 'package:ayyy/features/user/designer_directory/application/designer_directory_providers.dart';

class AiRoomResultScreen extends ConsumerStatefulWidget {
  final String productId;

  const AiRoomResultScreen({super.key, required this.productId});

  @override
  ConsumerState<AiRoomResultScreen> createState() =>
      _AiRoomResultScreenState();
}

class _AiRoomResultScreenState extends ConsumerState<AiRoomResultScreen>
    with TickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiRoomControllerProvider);

    // Trigger fade-in when generation completes
    if (aiState.isDone && _fadeController.status == AnimationStatus.dismissed) {
      _fadeController.forward();
    }

    return PopScope(
      canPop: !aiState.isProcessing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && aiState.isProcessing) {
          _showCancelDialog(context);
        }
      },
      child: Scaffold(
        appBar: const DazzleAppBar(showBackButton: true),
        body: _buildBody(aiState),
      ),
    );
  }

  Widget _buildBody(AiRoomState aiState) {
    if (aiState.step == AiRoomStep.error) {
      return _buildErrorState(aiState);
    }

    if (aiState.isProcessing) {
      return _buildLoadingState(aiState);
    }

    if (aiState.isDone) {
      return _buildCompletedState(aiState);
    }

    // Idle / shouldn't happen — redirect back
    return Center(
      child: Text(
        'No generation in progress',
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Loading State
  // ──────────────────────────────────────────

  Widget _buildLoadingState(AiRoomState aiState) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // ── Shimmer placeholder ──
                  AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      return Container(
                        height: 300,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: const [
                              Color(0xFFF0EDE6),
                              Color(0xFFF8F6F0),
                              Color(0xFFF0EDE6),
                            ],
                            stops: [
                              (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                              _shimmerController.value,
                              (_shimmerController.value + 0.3).clamp(0.0, 1.0),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Opacity(
                                opacity: 0.3 + (_pulseController.value * 0.4),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  size: 48,
                                  color: AppColors.primaryDark,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // ── Step progress indicator ──
                  _StepProgressBar(
                    currentStep: aiState.stepIndex,
                    totalSteps: 3,
                  ),
                  const SizedBox(height: 24),

                  // ── Step message ──
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      aiState.stepMessage,
                      key: ValueKey(aiState.step),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _stepSubtext(aiState.step),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // ── Animated dots ──
                  _AnimatedDots(controller: _pulseController),
                ],
              ),
            ),
          ),
        ),

        // ── Cancel button ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => _showCancelDialog(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'CANCEL',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  // Completed State
  // ──────────────────────────────────────────

  Widget _buildCompletedState(AiRoomState aiState) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ── Generated image ──
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: aiState.generatedImageBytes != null
                            ? Image.memory(
                                aiState.generatedImageBytes!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, e, st) => _imagePlaceholder(),
                              )
                            : _imagePlaceholder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── AI badge ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              size: 12,
                              color: AppColors.primaryDark,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'AI GENERATED',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (aiState.isSaved)
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Saved',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Product info card ──
                  if (aiState.product != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3EE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                aiState.selectedProductImageUrl ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (_, e, st) => const Icon(
                                  Icons.chair_outlined,
                                  size: 20,
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
                                  aiState.product!.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Rs. ${aiState.product!.price.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ),

        // ── Bottom action area ──
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
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
            child: Column(
              children: [
                // ── Regenerate + Save row ──
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ref
                                .read(aiRoomControllerProvider.notifier)
                                .regenerate();
                            context.pushReplacement('/marketplace/product/${widget.productId}/canvas-editor');
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'REGENERATE',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: aiState.isSaved ||
                                  aiState.step == AiRoomStep.saving
                              ? null
                              : () {
                                  ref
                                      .read(aiRoomControllerProvider.notifier)
                                      .saveToHistory();
                                },
                          icon: Icon(
                            aiState.isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_outline,
                            size: 16,
                          ),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              aiState.step == AiRoomStep.saving
                                  ? 'SAVING...'
                                  : aiState.isSaved
                                      ? 'SAVED'
                                      : 'SAVE',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: aiState.isSaved
                                ? AppColors.success
                                : const Color(0xFF333333),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppColors.textSecondary.withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Order CTA ──
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate back to product and push to cart
                      context.pop(); // Go back to product details
                    },
                    icon: const Icon(Icons.shopping_bag_outlined, size: 16),
                    label: Text(
                      'ORDER THIS PRODUCT',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF333333),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Share with Designer CTA ──
                if (aiState.generatedImageUrl != null || aiState.isSaved)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (aiState.generatedImageUrl != null) {
                          ref.read(pendingHireAttachmentProvider.notifier).setMultiple([aiState.generatedImageUrl!]);
                          context.push('/designers');
                        }
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
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────
  // Error State
  // ──────────────────────────────────────────

  Widget _buildErrorState(AiRoomState aiState) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 36,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Generation Failed',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              aiState.errorMessage ?? 'Something went wrong',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(aiRoomControllerProvider.notifier).regenerate();
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(
                  'TRY AGAIN',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                ref.read(aiRoomControllerProvider.notifier).reset();
                context.pop();
              },
              child: Text(
                'Go Back',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────

  Widget _imagePlaceholder() {
    return Container(
      height: 300,
      color: const Color(0xFFF0EDE6),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  String _stepSubtext(AiRoomStep step) => switch (step) {
        AiRoomStep.removingBackground =>
          'Isolating product from its background for clean placement',
        AiRoomStep.analyzingRoom =>
          'AI is studying your room layout, lighting, and perspective',
        AiRoomStep.compositing =>
          'Rendering the product into your room with natural proportions',
        _ => '',
      };

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Cancel Generation?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: Text(
          'The AI is still working. Are you sure you want to cancel?',
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
              'Keep Working',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(aiRoomControllerProvider.notifier).cancelGeneration();
              context.pop();
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────
// Step Progress Bar Widget
// ──────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepProgressBar({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector line
          final stepBefore = index ~/ 2;
          final isActive = stepBefore < currentStep;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 40,
            height: 2,
            color: isActive ? AppColors.primary : const Color(0xFFE0DDD6),
          );
        }

        // Step dot
        final step = index ~/ 2;
        final isCompleted = step < currentStep;
        final isCurrent = step == currentStep;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isCurrent ? 28 : 20,
          height: isCurrent ? 28 : 20,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.primary
                : isCurrent
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : const Color(0xFFE0DDD6),
            shape: BoxShape.circle,
            border: isCurrent
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : isCurrent
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
          ),
        );
      }),
    );
  }
}

// ──────────────────────────────────────────
// Animated Loading Dots
// ──────────────────────────────────────────

class _AnimatedDots extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final t = (controller.value + delay) % 1.0;
            final scale = 0.6 + 0.4 * math.sin(t * math.pi);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: 0.4 + 0.6 * math.sin(t * math.pi),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

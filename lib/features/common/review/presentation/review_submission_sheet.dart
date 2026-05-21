import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import '../application/review_controller.dart';

class ReviewSubmissionSheet extends ConsumerStatefulWidget {
  final String? designerId;
  final String? requestId;
  final String? productId;
  final String? orderId;
  final String title;
  final String subtitle;

  const ReviewSubmissionSheet({
    super.key,
    this.designerId,
    this.requestId,
    this.productId,
    this.orderId,
    required this.title,
    required this.subtitle,
  }) : assert(
          (designerId != null && requestId != null) || (productId != null && orderId != null),
          'Must provide either designerId & requestId OR productId & orderId',
        );

  /// Helper method to present this premium sheet
  static void show(
    BuildContext context, {
    String? designerId,
    String? requestId,
    String? productId,
    String? orderId,
    required String title,
    required String subtitle,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ReviewSubmissionSheet(
          designerId: designerId,
          requestId: requestId,
          productId: productId,
          orderId: orderId,
          title: title,
          subtitle: subtitle,
        ),
      ),
    );
  }

  @override
  ConsumerState<ReviewSubmissionSheet> createState() => _ReviewSubmissionSheetState();
}

class _ReviewSubmissionSheetState extends ConsumerState<ReviewSubmissionSheet> {
  int _selectedRating = 5;
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    final reviewText = _commentController.text.trim();
    bool success = false;

    if (widget.designerId != null && widget.requestId != null) {
      success = await ref.read(reviewSubmissionControllerProvider.notifier).submitDesignerReview(
            designerId: widget.designerId!,
            requestId: widget.requestId!,
            rating: _selectedRating,
            reviewText: reviewText,
          );
    } else if (widget.productId != null && widget.orderId != null) {
      success = await ref.read(reviewSubmissionControllerProvider.notifier).submitProductReview(
            productId: widget.productId!,
            orderId: widget.orderId!,
            rating: _selectedRating,
            reviewText: reviewText,
          );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                'Review submitted successfully!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      final state = ref.read(reviewSubmissionControllerProvider);
      final error = state.maybeWhen(
        error: (e, _) => e.toString(),
        orElse: () => 'An unexpected error occurred. Please try again.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  error,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final submissionState = ref.watch(reviewSubmissionControllerProvider);
    final isLoading = submissionState is AsyncLoading;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull Bar Indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title & Subtitle
              Text(
                widget.title.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // 1-5 Star Ratings Row with animations
              Center(
                child: Column(
                  children: [
                    Text(
                      'TAP TO RATE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        final isSelected = starValue <= _selectedRating;
                        return GestureDetector(
                          onTap: isLoading
                              ? null
                              : () => setState(() => _selectedRating = starValue),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: AnimatedScale(
                              scale: isSelected ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isSelected ? Icons.star : Icons.star_border_outlined,
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.4),
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Written Feedback Field
              Text(
                'YOUR VALUABLE FEEDBACK',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commentController,
                maxLines: 4,
                enabled: !isLoading,
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Share your detailed experience to help others...',
                  hintStyle: GoogleFonts.inter(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 13),
                  contentPadding: const EdgeInsets.all(16),
                  fillColor: const Color(0xFFF7F6F2),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please write your review comment.';
                  }
                  if (value.trim().length < 8) {
                    return 'Please write a slightly longer review (minimum 8 characters).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submission Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isLoading ? null : _submitReview,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'SUBMIT FEEDBACK',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

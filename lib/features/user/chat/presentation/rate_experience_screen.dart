import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/widgets/dazzle_app_bar.dart';
import 'package:ayyy/features/designer/requests/data/designer_request_repository.dart';
import 'package:ayyy/features/designer/requests/domain/designer_request.dart';
import 'package:ayyy/features/common/review/application/review_controller.dart';

final designerRequestDetailProvider = FutureProvider.family.autoDispose<DesignerRequest?, String>((ref, id) async {
  return ref.watch(designerRequestRepositoryProvider).getRequestById(id);
});

class RateExperienceScreen extends ConsumerStatefulWidget {
  final String id;
  const RateExperienceScreen({super.key, required this.id});

  @override
  ConsumerState<RateExperienceScreen> createState() => _RateExperienceScreenState();
}

class _RateExperienceScreenState extends ConsumerState<RateExperienceScreen> {
  int _rating = 5;
  final TextEditingController _feedbackController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitReview(DesignerRequest req) async {
    if (!_formKey.currentState!.validate()) return;

    final feedbackText = _feedbackController.text.trim();
    
    // Call real submission
    final success = await ref.read(reviewSubmissionControllerProvider.notifier).submitDesignerReview(
          designerId: req.designerId,
          requestId: req.id,
          rating: _rating,
          reviewText: feedbackText.isEmpty ? 'Excellent design collaboration.' : feedbackText,
        );

    if (success && mounted) {
      context.push('/review/success');
    } else if (mounted) {
      final state = ref.read(reviewSubmissionControllerProvider);
      final error = state.maybeWhen(
        error: (e, _) => e.toString(),
        orElse: () => 'An error occurred during submission. Please try again.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestState = ref.watch(designerRequestDetailProvider(widget.id));
    final submissionState = ref.watch(reviewSubmissionControllerProvider);
    final isLoading = submissionState is AsyncLoading;

    return Scaffold(
      appBar: const DazzleAppBar(showBackButton: true),
      body: requestState.when(
        data: (req) {
          if (req == null) {
            return Center(
              child: Text(
                'Collaboration project not found.',
                style: GoogleFonts.inter(color: AppColors.textSecondary),
              ),
            );
          }

          final designerName = req.userName ?? 'Elite Designer';
          final avatarUrl = req.userAvatarUrl;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  
                  // Designer avatar
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3EE),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: avatarUrl != null && avatarUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person, size: 40, color: AppColors.textSecondary),
                            ),
                          )
                        : const Icon(Icons.person, size: 40, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  
                  Text(
                    'How was your\nexperience with\n$designerName?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rate your luxury collaboration journey.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),

                  // Star rating selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      final isSelected = starValue <= _rating;
                      return GestureDetector(
                        onTap: isLoading ? null : () => setState(() => _rating = starValue),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                            color: AppColors.primary,
                            size: 48,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // Feedback
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'LEAVE A DETAILED REVIEW',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _feedbackController,
                    maxLines: 5,
                    enabled: !isLoading,
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Share aesthetic, promptness, and structural details...',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary.withValues(alpha: 0.6)),
                      fillColor: const Color(0xFFF7F6F2),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
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
                  const SizedBox(height: 36),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => _submitReview(req),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFD4D4D4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'Submit Review',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.2),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Failed to fetch request: $e',
            style: GoogleFonts.inter(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}

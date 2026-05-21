import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/widgets/dazzle_app_bar.dart';
import 'package:ayyy/core/widgets/dazzle_bottom_nav.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/designer/requests/domain/designer_request.dart';
import 'package:ayyy/features/designer/requests/data/designer_request_repository.dart';
import 'package:ayyy/features/user/designer_directory/application/designer_directory_providers.dart';

class HireRequestScreen extends ConsumerStatefulWidget {
  final String id;
  const HireRequestScreen({super.key, required this.id});

  @override
  ConsumerState<HireRequestScreen> createState() => _HireRequestScreenState();
}

class _HireRequestScreenState extends ConsumerState<HireRequestScreen> {
  int _selectedAccess = 0; // 0 = Chat Only, 1 = Full Access

  @override
  Widget build(BuildContext context) {
    final designerDetailsState = ref.watch(publicDesignerDetailsProvider(widget.id));

    return Scaffold(
      appBar: const DazzleAppBar(showBackButton: true),
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
          final double consultationPrice = (designerProfile?['consultation_price'] as num?)?.toDouble() ?? 49.0;
          final double fullAccessPrice = consultationPrice * 4.0; // Dynamic scaling for premium tier

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Header
                Text(
                  'Send Request',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Confirm your selection and choose your\naccess level to begin the collaboration.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Designer profile card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Stack(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F3EE),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: avatarUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.network(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: AppColors.textSecondary, size: 36),
                                    ),
                                  )
                                : const Icon(Icons.person, color: AppColors.textSecondary, size: 36),
                          ),
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'TOP\nRATED',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        specialty,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '5.0 Verified Partner',
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
                const SizedBox(height: 24),

                // Access Level section
                Text(
                  'Access Level',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),

                // Chat Only option
                GestureDetector(
                  onTap: () => setState(() => _selectedAccess = 0),
                  child: _AccessLevelCard(
                    isSelected: _selectedAccess == 0,
                    title: 'Chat Only',
                    description: 'Direct consultation with the designer to discuss ideas and feasibility without full file sharing.',
                    price: '\$${consultationPrice.toStringAsFixed(0)}',
                    priceLabel: 'ONE-\nTIME',
                  ),
                ),
                const SizedBox(height: 12),

                // Full Access option
                GestureDetector(
                  onTap: () => setState(() => _selectedAccess = 1),
                  child: _AccessLevelCard(
                    isSelected: _selectedAccess == 1,
                    title: 'Full Access',
                    description: 'Includes source designs, 3D renderings, material lists, and unlimited direct messaging for 30 days.',
                    price: '\$${fullAccessPrice.toStringAsFixed(0)}',
                    priceLabel: 'PER\nPROJECT',
                  ),
                ),
                const SizedBox(height: 20),

                // Terms
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'By sending this request, you agree to the '),
                        TextSpan(
                          text: 'Service Level Agreement',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textPrimary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const TextSpan(text: ' and initial consultation fees.'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Send Request button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Show loading SnackBar
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sending hire request...'),
                          duration: Duration(seconds: 1),
                        ),
                      );

                      try {
                        final currentUser = Supabase.instance.client.auth.currentUser;
                        if (currentUser != null) {
                          final request = DesignerRequest(
                            id: '', // Will be generated automatically by the DB
                            userId: currentUser.id,
                            designerId: widget.id,
                            budget: _selectedAccess == 0 
                                ? '\$${consultationPrice.toStringAsFixed(2)}' 
                                : '\$${fullAccessPrice.toStringAsFixed(2)}',
                            preferences: 'Access Level: ${_selectedAccess == 0 ? "Chat Only" : "Full Access"}',
                            roomType: 'Living Room',
                            attachments: [],
                            accessLevel: _selectedAccess == 0 ? 'chat_only' : 'full_access',
                            status: 'pending',
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                          );

                          await ref.read(designerRequestRepositoryProvider).createRequest(request);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Request sent successfully!')),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Error: Not authenticated')),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to send request: $e')),
                          );
                        }
                      }

                      if (context.mounted) {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/designers');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Send Request',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
              'Failed to load designer details: $e',
              style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccessLevelCard extends StatelessWidget {
  final bool isSelected;
  final String title;
  final String description;
  final String price;
  final String priceLabel;

  const _AccessLevelCard({
    required this.isSelected,
    required this.title,
    required this.description,
    required this.price,
    required this.priceLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Radio indicator
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                priceLabel,
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/features/auth/application/auth_controller.dart';
import '../application/designer_profile_controller.dart';
import 'package:ayyy/features/designer/earnings/application/designer_earnings_controller.dart';
import 'package:ayyy/features/designer/portfolio/presentation/designer_packages_screen.dart';

class DesignerProfileScreen extends ConsumerStatefulWidget {
  const DesignerProfileScreen({super.key});

  @override
  ConsumerState<DesignerProfileScreen> createState() => _DesignerProfileScreenState();
}

class _DesignerProfileScreenState extends ConsumerState<DesignerProfileScreen> {
  final _bioController = TextEditingController();
  final _expController = TextEditingController();
  final _respController = TextEditingController();
  final _priceController = TextEditingController();
  
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _bioController.dispose();
    _expController.dispose();
    _respController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _populateFields(dynamic profile) {
    _bioController.text = profile.bio;
    _expController.text = profile.experienceYears.toString();
    _respController.text = profile.responseTime;
    _priceController.text = profile.consultationPrice.toStringAsFixed(0);
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    
    final exp = int.tryParse(_expController.text) ?? 2;
    final price = double.tryParse(_priceController.text) ?? 49.0;

    final success = await ref
        .read(designerProfileControllerProvider.notifier)
        .updateExpertiseAndDetails(
          experienceYears: exp,
          expertise: ['Minimal', 'Modern', 'Luxe'],
          certifications: ['Certified Architectural Interior Designer'],
          responseTime: _respController.text,
        );

    final successBio = await ref
        .read(designerProfileControllerProvider.notifier)
        .updateBio(_bioController.text);

    final successPrice = await ref
        .read(designerProfileControllerProvider.notifier)
        .updatePricing(price);

    setState(() {
      _isLoading = false;
      _isEditing = false;
    });

    if (success && successBio && successPrice && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Professional profile updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(designerProfileControllerProvider);
    final stats = ref.watch(designerStatsProvider);
    final earningsAsync = ref.watch(designerEarningsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'STUDIO & EARNINGS',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit_outlined, color: AppColors.textPrimary),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                profileAsync.whenData((profile) {
                  if (profile != null) {
                    _populateFields(profile);
                    setState(() => _isEditing = true);
                  }
                });
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick stats summary
                  Text(
                    'FINANCIAL ANALYTICS',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _EarningsCard(
                          label: 'MONTHLY REVENUE',
                          value: 'Rs. ${stats.monthlyRevenue.toStringAsFixed(0)}',
                          bg: AppColors.surface,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _EarningsCard(
                          label: 'TOTAL INCOME',
                          value: 'Rs. ${stats.totalEarnings.toStringAsFixed(0)}',
                          bg: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  profileAsync.when(
                    data: (profile) {
                      if (profile == null) return const SizedBox();
                      if (!_isEditing) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'STUDIO AVAILABILITY',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        profile.isAvailable ? 'AVAILABLE FOR HIRE' : 'STUDIO BOOKED / CLOSED',
                                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Accepting client requests',
                                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  Switch.adaptive(
                                    value: profile.isAvailable,
                                    activeThumbColor: AppColors.primary,
                                    activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                                    onChanged: (val) {
                                      ref
                                          .read(designerProfileControllerProvider.notifier)
                                          .updateAvailability(val);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            Text(
                              'BIOGRAPHY & SERVICE',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.bio,
                                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, height: 1.5),
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(color: AppColors.border, height: 1),
                                  const SizedBox(height: 16),
                                  _RowInfo(label: 'Experience:', value: '${profile.experienceYears} Years'),
                                  _RowInfo(label: 'Response Time:', value: profile.responseTime),
                                  _RowInfo(label: 'Consultation Fee:', value: 'Rs. ${profile.consultationPrice.toStringAsFixed(0)}'),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      // Edit mode
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EDIT STUDIO SPECIFICATIONS',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Professional Bio',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _bioController,
                                maxLines: 4,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'Describe your expertise...',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Experience (Years)',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _expController,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(color: AppColors.textPrimary),
                                      decoration: InputDecoration(
                                        hintText: 'e.g. 5',
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Consult Fee (Rs.)',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _priceController,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(color: AppColors.textPrimary),
                                      decoration: InputDecoration(
                                        hintText: 'e.g. 49',
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Response Time Description',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _respController,
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Within 24 hours',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                    loading: () => const SizedBox(),
                    error: (err, st) => const SizedBox(),
                  ),
                  const SizedBox(height: 28),

                  // Consultation Packages Shortcut
                  Text(
                    'SERVICES MANAGEMENT',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DesignerPackagesScreen()),
                        );
                      },
                      leading: const Icon(Icons.style_outlined, color: AppColors.primaryDark),
                      title: Text(
                        'Customize Service Packages',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        'Configure packages, custom prices, and deliverables',
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Earnings breakdown list
                  Text(
                    'EARNINGS LOGS',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  earningsAsync.when(
                    data: (earnings) {
                      if (earnings.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              'No recent payout logs found.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: earnings.length > 5 ? 5 : earnings.length,
                        itemBuilder: (context, index) {
                          final e = earnings[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Studio consultation credit',
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${e.createdAt.month}/${e.createdAt.day} at ${e.createdAt.hour}:${e.createdAt.minute.toString().padLeft(2, '0')}',
                                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                                Text(
                                  '+Rs. ${e.amount.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.success),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    error: (err, st) => const SizedBox(),
                  ),
                  const SizedBox(height: 28),

                  // Client Reviews Section
                  Text(
                    'CLIENT REVIEWS & RATINGS',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '4.9',
                              style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(5, (index) => const Icon(Icons.star, color: Colors.amber, size: 16)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Based on 24 completed projects',
                                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.border, height: 1),
                        const SizedBox(height: 16),
                        _ReviewItem(
                          clientName: 'Sarah M.',
                          rating: 5,
                          comment: 'Incredible attention to detail. The collaborative canvas made the process so easy!',
                          date: '2 days ago',
                        ),
                        const SizedBox(height: 12),
                        _ReviewItem(
                          clientName: 'James L.',
                          rating: 5,
                          comment: 'The AI enhanced preview really helped me visualize the final room.',
                          date: '1 week ago',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Logout action
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        await ref.read(authControllerProvider.notifier).logout();
                      },
                      icon: const Icon(Icons.logout_outlined, size: 20),
                      label: Text(
                        'SIGN OUT FROM STUDIO',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1),
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

class _EarningsCard extends StatelessWidget {
  final String label;
  final String value;
  final Color bg;

  const _EarningsCard({required this.label, required this.value, required this.bg});

  @override
  Widget build(BuildContext context) {
    final isPrimary = bg == AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
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
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: isPrimary ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowInfo extends StatelessWidget {
  final String label;
  final String value;

  const _RowInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String clientName;
  final int rating;
  final String comment;
  final String date;

  const _ReviewItem({
    required this.clientName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              clientName,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            Row(
              children: List.generate(rating, (index) => const Icon(Icons.star, color: Colors.amber, size: 12)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          comment,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

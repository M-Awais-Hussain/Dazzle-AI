import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/features/marketplace_owner/application/marketplace_profile_controller.dart';
import 'package:ayyy/features/marketplace_owner/presentation/widgets/common_widgets.dart';
import 'package:ayyy/features/auth/application/auth_controller.dart';
import 'package:go_router/go_router.dart';

class MarketplaceProfileScreen extends ConsumerStatefulWidget {
  const MarketplaceProfileScreen({super.key});

  @override
  ConsumerState<MarketplaceProfileScreen> createState() => _MarketplaceProfileScreenState();
}

class _MarketplaceProfileScreenState extends ConsumerState<MarketplaceProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _storeNameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _websiteCtrl;
  late TextEditingController _instagramCtrl;
  bool _isLoading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _storeNameCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _websiteCtrl = TextEditingController();
    _instagramCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _websiteCtrl.dispose();
    _instagramCtrl.dispose();
    super.dispose();
  }

  void _initFields(dynamic profile) {
    if (!_initialized && profile != null) {
      _storeNameCtrl.text = profile.storeName;
      _descCtrl.text = profile.storeDescription;
      _phoneCtrl.text = profile.contactPhone;
      _emailCtrl.text = profile.contactEmail;
      _addressCtrl.text = profile.address;
      _websiteCtrl.text = profile.socialLinks['website'] ?? '';
      _instagramCtrl.text = profile.socialLinks['instagram'] ?? '';
      _initialized = true;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final success = await ref.read(marketplaceProfileControllerProvider.notifier).saveProfile(
      storeName: _storeNameCtrl.text,
      storeDescription: _descCtrl.text,
      contactPhone: _phoneCtrl.text,
      contactEmail: _emailCtrl.text,
      address: _addressCtrl.text,
      socialLinks: {
        if (_websiteCtrl.text.isNotEmpty) 'website': _websiteCtrl.text,
        if (_instagramCtrl.text.isNotEmpty) 'instagram': _instagramCtrl.text,
      },
    );

    setState(() => _isLoading = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved!'), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _pickAndUploadLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      await ref.read(marketplaceProfileControllerProvider.notifier).uploadLogo(image);
    }
  }

  Future<void> _pickAndUploadBanner() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      await ref.read(marketplaceProfileControllerProvider.notifier).uploadBanner(image);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(marketplaceProfileControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: profileAsync.when(
          data: (profile) {
            _initFields(profile);
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Store Profile', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        TextButton(
                          onPressed: _isLoading ? null : _save,
                          child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text('SAVE', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 1)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Banner
                    GestureDetector(
                      onTap: _pickAndUploadBanner,
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EDE6),
                          borderRadius: BorderRadius.circular(16),
                          image: profile?.storeBannerUrl != null
                              ? DecorationImage(image: CachedNetworkImageProvider(profile!.storeBannerUrl!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: profile?.storeBannerUrl == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.panorama_outlined, color: AppColors.textSecondary, size: 32),
                                  const SizedBox(height: 8),
                                  Text('Tap to upload banner', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              )
                            : null,
                      ),
                    ),

                    // Logo overlay
                    Transform.translate(
                      offset: const Offset(0, -36),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: GestureDetector(
                            onTap: _pickAndUploadLogo,
                            child: Container(
                              width: 72, height: 72,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.surface, width: 3),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
                                image: profile?.storeLogoUrl != null
                                    ? DecorationImage(image: CachedNetworkImageProvider(profile!.storeLogoUrl!), fit: BoxFit.cover)
                                    : null,
                              ),
                              child: profile?.storeLogoUrl == null
                                  ? const Icon(Icons.add_a_photo_outlined, color: AppColors.textSecondary, size: 24)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Form fields
                    _field('Store Name', _storeNameCtrl, 'Your store name', required: true),
                    const SizedBox(height: 16),
                    _field('Description', _descCtrl, 'Tell customers about your store', maxLines: 3),
                    const SizedBox(height: 16),
                    _field('Contact Phone', _phoneCtrl, '+1 234 567 890', keyboardType: TextInputType.phone),
                    const SizedBox(height: 16),
                    _field('Contact Email', _emailCtrl, 'store@example.com', keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _field('Address', _addressCtrl, 'Store address', maxLines: 2),
                    const SizedBox(height: 24),

                    Text('Social Links', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    _field('Website', _websiteCtrl, 'https://yourstore.com'),
                    const SizedBox(height: 16),
                    _field('Instagram', _instagramCtrl, '@yourstore'),
                    const SizedBox(height: 32),

                    // Logout
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await ref.read(authControllerProvider.notifier).logout();
                          if (context.mounted) {
                            context.go('/role-selection');
                          }
                        },
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Logout'),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: BorderSide(color: AppColors.error.withValues(alpha: 0.3))),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
          loading: () => const MarketplaceLoadingState(message: 'Loading profile...'),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint, {int maxLines = 1, TextInputType? keyboardType, bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
          validator: required ? (v) => (v == null || v.isEmpty) ? '$label is required' : null : null,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

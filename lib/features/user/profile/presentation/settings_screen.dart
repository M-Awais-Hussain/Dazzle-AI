import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/features/auth/application/auth_controller.dart';
import 'package:ayyy/core/widgets/dazzle_app_bar.dart';
import 'package:ayyy/core/widgets/dazzle_bottom_nav.dart';
import 'package:ayyy/core/widgets/custom_text_field.dart';
import 'settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isNameInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(settingsControllerProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfileState = ref.watch(currentUserProfileProvider);
    final user = userProfileState.value;
    final userName = user?.name ?? 'User';
    final userEmail = user?.email ?? 'user@dazzle.ai';

    // Initialize display name in text controller once profile is loaded
    if (user != null && !_isNameInitialized) {
      _nameController.text = user.name;
      _isNameInitialized = true;
    }

    final settingsState = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: const DazzleAppBar(showProfileIcon: false),
      bottomNavigationBar: const DazzleBottomNav(currentIndex: -1),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Account',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Manage your preferences and profile.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Profile card (User Info Section)
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
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3EE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.person, size: 28, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userEmail,
                          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'PRO',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Change Name Section
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Change Name',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Display Name',
                    hintText: 'Enter your full name',
                    controller: _nameController,
                    prefixIcon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  if (settingsState.nameError != null) ...[
                    Text(
                      settingsState.nameError!,
                      style: GoogleFonts.inter(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (settingsState.nameSuccess != null) ...[
                    Text(
                      settingsState.nameSuccess!,
                      style: GoogleFonts.inter(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: settingsState.isUpdatingName
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              ref.read(settingsControllerProvider.notifier).updateName(_nameController.text);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: settingsState.isUpdatingName
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textPrimary,
                              ),
                            )
                          : Text(
                              'UPDATE NAME',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Change Password Section
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Change Password',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'New Password',
                    hintText: 'Minimum 6 characters',
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNew = !_obscureNew;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Confirm New Password',
                    hintText: 'Re-enter new password',
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirm = !_obscureConfirm;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (settingsState.passwordError != null) ...[
                    Text(
                      settingsState.passwordError!,
                      style: GoogleFonts.inter(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (settingsState.passwordSuccess != null) ...[
                    Text(
                      settingsState.passwordSuccess!,
                      style: GoogleFonts.inter(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: settingsState.isUpdatingPassword
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              ref.read(settingsControllerProvider.notifier).updatePassword(
                                    _newPasswordController.text,
                                    _confirmPasswordController.text,
                                  ).then((_) {
                                    if (ref.read(settingsControllerProvider).passwordSuccess != null) {
                                      _newPasswordController.clear();
                                      _confirmPasswordController.clear();
                                    }
                                  });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: settingsState.isUpdatingPassword
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textPrimary,
                              ),
                            )
                          : Text(
                              'UPDATE PASSWORD',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Log out Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).logout();
                  context.go('/role-selection');
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  foregroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Log Out',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'DAZZLE v1.0.0',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/storage/local_storage_service.dart';

// Notifier to store the selected role across screens, backed by LocalStorage persistence
class SelectedRoleNotifier extends Notifier<String> {
  @override
  String build() {
    final storage = ref.watch(localStorageServiceProvider);
    return storage.getString('selected_role') ?? 'user';
  }

  void setRole(String role) {
    state = role;
    ref.read(localStorageServiceProvider).setString('selected_role', role);
  }
}

final selectedRoleProvider = NotifierProvider<SelectedRoleNotifier, String>(() {
  return SelectedRoleNotifier();
});

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  String? selectedRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          selectedRole = ref.read(selectedRoleProvider);
        });
      }
    });
  }

  void _selectRole(String role) {
    setState(() {
      selectedRole = role;
    });
  }

  void _continue() {
    if (selectedRole != null) {
      // Store the selected role in the provider so login can use it
      ref.read(selectedRoleProvider.notifier).setRole(selectedRole!);
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Choose Your Role',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Select how you would like to experience the future of interior architecture and design.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              
              // Roles Grid/List
              Expanded(
                child: ListView(
                  children: [
                    _RoleCard(
                      title: 'Continue as User',
                      description: 'Browse design directories, hire professional designers, and explore curated furniture markets.',
                      isSelected: selectedRole == 'user',
                      onTap: () => _selectRole('user'),
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 24),
                    _RoleCard(
                      title: 'Continue as Designer',
                      description: 'Work with clients, manage projects, and use advanced rendering to bring professional visions to life.',
                      isSelected: selectedRole == 'designer',
                      onTap: () => _selectRole('designer'),
                      icon: Icons.brush_outlined,
                    ),
                    const SizedBox(height: 24),
                    _RoleCard(
                      title: 'Continue as Marketplace Owner',
                      description: 'Manage products, track orders, view marketplace analytics, and grow your interior design business.',
                      isSelected: selectedRole == 'marketplace_owner',
                      onTap: () => _selectRole('marketplace_owner'),
                      icon: Icons.storefront_outlined,
                    ),
                  ],
                ),
              ),
              
              // Bottom Action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedRole == null ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedRole == null ? AppColors.surface : AppColors.primary,
                    foregroundColor: selectedRole == null ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  size: 28,
                ),
                const Spacer(),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

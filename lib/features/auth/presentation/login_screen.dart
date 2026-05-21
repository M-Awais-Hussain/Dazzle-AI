import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/features/auth/application/auth_controller.dart';
import 'package:ayyy/core/widgets/custom_text_field.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/features/auth/presentation/role_selection_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final name = _nameController.text;
    final username = _usernameController.text;
    
    if (email.isEmpty || password.isEmpty) return;
    if (_isSignUp && (name.isEmpty || username.isEmpty)) return;

    final role = ref.read(selectedRoleProvider);

    if (_isSignUp) {
      await ref.read(authControllerProvider.notifier).signUp(email, password, name, role, username: username);
    } else {
      await ref.read(authControllerProvider.notifier).login(email, password);
    }
    
    // Check for errors after attempting
    if (mounted) {
      final authState = ref.read(authControllerProvider);
      if (authState.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'DAZZLE',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(height: 48),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isSignUp ? 'Create Account' : 'Welcome Back',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isSignUp 
                          ? 'Fill in your details to get started' 
                          : 'Please enter your credentials to login',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      if (_isSignUp) ...[
                        CustomTextField(
                          label: 'Full Name',
                          hintText: 'Enter your name',
                          controller: _nameController,
                          prefixIcon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: 'Username',
                          hintText: 'Choose a username',
                          controller: _usernameController,
                          prefixIcon: Icons.alternate_email,
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      CustomTextField(
                        label: 'Email Address',
                        hintText: 'your@email.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      
                      CustomTextField(
                        label: 'Password',
                        hintText: '••••••••',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: authState.isLoading 
                            ? const SizedBox(
                                height: 20, 
                                width: 20, 
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                              )
                            : Text(
                                _isSignUp ? 'CREATE ACCOUNT' : 'LOGIN',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                          });
                        },
                        child: Text(
                          _isSignUp 
                            ? 'Already have an account? Login' 
                            : 'Don\'t have an account? Sign Up',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  '© 2026 DAZZLE STUDIO',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

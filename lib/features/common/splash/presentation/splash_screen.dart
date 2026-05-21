import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/core/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _lineController;

  @override
  void initState() {
    super.initState();
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _navigateToNext();
  }

  @override
  void dispose() {
    _lineController.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final isAuth = Supabase.instance.client.auth.currentSession != null;
      if (isAuth) {
        // Router redirect will send to the correct role-based dashboard
        context.go('/dashboard');
      } else {
        context.go('/role-selection');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Soft warm gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFF9E6), // Warm yellow tint top-left
                  Color(0xFFF5F5F0), // Neutral off-white
                  Color(0xFFEEEEEE), // Light gray bottom
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo circle with shadow
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF555555),
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // App Name
                Text(
                  'DAZZLE',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    letterSpacing: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                // Tagline
                Text(
                  'Design Your Dream Space',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          // Minimalist yellow loading line
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 60,
                height: 3,
                child: AnimatedBuilder(
                  animation: _lineController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _YellowLinePainter(_lineController.value),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YellowLinePainter extends CustomPainter {
  final double progress;

  _YellowLinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    // Gray track
    final trackPaint = Paint()
      ..color = const Color(0xFFDDDDDD)
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      trackPaint,
    );

    // Yellow indicator
    final indicatorPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = size.height
      ..strokeCap = StrokeCap.round;

    final indicatorWidth = size.width * 0.4;
    final start = (size.width + indicatorWidth) * progress - indicatorWidth;
    final clampedStart = start.clamp(0.0, size.width);
    final clampedEnd = (start + indicatorWidth).clamp(0.0, size.width);

    if (clampedEnd > clampedStart) {
      canvas.drawLine(
        Offset(clampedStart, size.height / 2),
        Offset(clampedEnd, size.height / 2),
        indicatorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _YellowLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

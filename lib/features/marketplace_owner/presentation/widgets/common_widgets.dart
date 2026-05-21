import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/core/theme/app_colors.dart';

class MarketplaceEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const MarketplaceEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3EE),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 24),
            Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5), textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class MarketplaceLoadingState extends StatelessWidget {
  final String? message;
  const MarketplaceLoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class StockIndicator extends StatelessWidget {
  final int stock;
  const StockIndicator({super.key, required this.stock});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    if (stock <= 0) { color = AppColors.error; label = 'Out of Stock'; }
    else if (stock <= 5) { color = Colors.orange; label = 'Low Stock ($stock)'; }
    else { color = AppColors.success; label = 'In Stock ($stock)'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

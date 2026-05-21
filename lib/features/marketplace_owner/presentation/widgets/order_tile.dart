import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/features/user/orders/domain/order.dart';

/// Reusable order tile for marketplace orders list
class OrderTile extends StatelessWidget {
  final Order order;
  final ValueChanged<OrderStatus>? onStatusChanged;

  const OrderTile({
    super.key,
    required this.order,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              OrderStatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 12),

          // Customer details
          _InfoRow(
            icon: Icons.location_on_outlined,
            text: order.shippingAddress.isEmpty ? 'No address' : order.shippingAddress,
          ),
          const SizedBox(height: 4),
          _InfoRow(
            icon: Icons.phone_outlined,
            text: order.phoneNumber.isEmpty ? 'No phone' : order.phoneNumber,
          ),
          const SizedBox(height: 8),

          // Items summary
          Text(
            '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          // Amount + actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${order.totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (onStatusChanged != null)
                _StatusDropdown(
                  currentStatus: order.status,
                  onSelected: onStatusChanged!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Reusable status badge
class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusBadge({super.key, required this.status});

  Color get _color => switch (status) {
        OrderStatus.pending => Colors.orange,
        OrderStatus.confirmed => Colors.blue,
        OrderStatus.shipped => Colors.purple,
        OrderStatus.delivered => Colors.green,
        OrderStatus.cancelled => Colors.red,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Status dropdown picker
class _StatusDropdown extends StatelessWidget {
  final OrderStatus currentStatus;
  final ValueChanged<OrderStatus> onSelected;

  const _StatusDropdown({required this.currentStatus, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<OrderStatus>(
      initialValue: currentStatus,
      onSelected: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'UPDATE',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
      itemBuilder: (context) => OrderStatus.values
          .map((s) => PopupMenuItem(
                value: s,
                child: Text(
                  s.name.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ))
          .toList(),
    );
  }
}

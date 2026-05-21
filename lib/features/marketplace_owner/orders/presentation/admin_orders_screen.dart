import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/features/user/orders/application/order_controller.dart';
import 'package:ayyy/features/user/orders/domain/order.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/widgets/dazzle_app_bar.dart';

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allOrdersAsync = ref.watch(allOrdersProvider);

    return Scaffold(
      appBar: const DazzleAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Order Management',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: allOrdersAsync.when(
              data: (orders) => orders.isEmpty
                  ? const Center(child: Text('No orders found'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return _OrderAdminCard(order: order);
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderAdminCard extends ConsumerWidget {
  final Order order;
  const _OrderAdminCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.orderNumber,
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Address: ${order.shippingAddress}',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
          Text(
            'Phone: ${order.phoneNumber}',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Amount: \$${order.totalAmount.toStringAsFixed(0)}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Update Status: ',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              _StatusPicker(
                currentStatus: order.status,
                onSelected: (status) {
                  ref.read(orderControllerProvider.notifier).updateStatus(order.id, status);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        break;
      case OrderStatus.confirmed:
        color = Colors.blue;
        break;
      case OrderStatus.shipped:
        color = Colors.purple;
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _StatusPicker extends StatelessWidget {
  final OrderStatus currentStatus;
  final Function(OrderStatus) onSelected;

  const _StatusPicker({required this.currentStatus, required this.onSelected});

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
              currentStatus.name.toUpperCase(),
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
      itemBuilder: (context) => OrderStatus.values
          .map((s) => PopupMenuItem(
                value: s,
                child: Text(s.name.toUpperCase(), style: GoogleFonts.inter(fontSize: 12)),
              ))
          .toList(),
    );
  }
}

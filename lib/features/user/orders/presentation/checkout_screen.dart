import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/features/user/marketplace/application/cart_controller.dart';
import 'package:ayyy/features/user/orders/application/order_controller.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/widgets/dazzle_app_bar.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    final cartState = ref.read(cartControllerProvider);
    final orderNumber = await ref.read(orderControllerProvider.notifier).placeOrder(
          address: _addressController.text,
          phone: _phoneController.text,
          totalAmount: cartState.total,
        );

    setState(() => _isProcessing = false);

    if (orderNumber != null) {
      if (mounted) {
        context.go('/marketplace/order-success?orderId=$orderNumber');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to place order. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartControllerProvider);

    return Scaffold(
      appBar: const DazzleAppBar(showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Checkout',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),

              // Shipping Details
              _SectionTitle(title: 'SHIPPING DETAILS'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: _inputDecoration('Shipping Address', Icons.location_on_outlined),
                validator: (value) => value == null || value.isEmpty ? 'Please enter address' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDecoration('Phone Number', Icons.phone_outlined),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter phone';
                  if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(value)) return 'Invalid phone format';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Payment Method
              _SectionTitle(title: 'PAYMENT METHOD'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  children: [
                    Icon(Icons.payments_outlined, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cash on Delivery (COD)',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Pay with cash when order arrives',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.check_circle, color: AppColors.primary),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Order Summary
              _SectionTitle(title: 'ORDER SUMMARY'),
              const SizedBox(height: 16),
              ...cartState.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${item.product.name} x ${item.quantity}', style: GoogleFonts.inter(fontSize: 13)),
                        Text('\$${(item.product.price * item.quantity).toStringAsFixed(0)}',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('\$${cartState.total.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 40),

              // Place Order Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: AppColors.textPrimary)
                      : Text(
                          'PLACE ORDER',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: AppColors.textSecondary,
      ),
    );
  }
}

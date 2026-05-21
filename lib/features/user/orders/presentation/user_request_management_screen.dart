import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/widgets/dazzle_app_bar.dart';
import 'package:ayyy/core/widgets/dazzle_bottom_nav.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ayyy/features/designer/requests/domain/designer_request.dart';
import 'package:ayyy/features/designer/requests/data/designer_request_repository.dart';
import 'package:ayyy/features/user/orders/data/order_repository.dart';
import 'package:ayyy/features/user/orders/domain/order.dart';
import 'package:ayyy/features/user/chat/data/chat_repository.dart';
import 'package:ayyy/features/common/review/application/review_controller.dart';
import 'package:ayyy/features/common/review/presentation/review_submission_sheet.dart';

final userRequestsProvider = FutureProvider.autoDispose<List<DesignerRequest>>((ref) async {
  final currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser == null) return [];
  return ref.watch(designerRequestRepositoryProvider).getRequestsForUser(currentUser.id);
});

final userOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser == null) return [];
  return ref.watch(orderRepositoryProvider).getUserOrders(currentUser.id);
});

class UserRequestManagementScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const UserRequestManagementScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<UserRequestManagementScreen> createState() => _UserRequestManagementScreenState();
}

class _UserRequestManagementScreenState extends ConsumerState<UserRequestManagementScreen> {
  late int _activeTab;
  String _collabFilter = 'all'; // 'all', 'pending', 'accepted', 'completed'

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final requestsState = ref.watch(userRequestsProvider);
    final ordersState = ref.watch(userOrdersProvider);

    return Scaffold(
      appBar: const DazzleAppBar(
        showProfileIcon: true,
      ),
      bottomNavigationBar: const DazzleBottomNav(currentIndex: 3),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Custom premium tab selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3EE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _activeTab == 0 ? AppColors.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _activeTab == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'COLLABORATIONS',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _activeTab == 0 ? AppColors.textPrimary : AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _activeTab == 1 ? AppColors.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _activeTab == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'ORDERS',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _activeTab == 1 ? AppColors.textPrimary : AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Main body
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(userRequestsProvider);
                  ref.invalidate(userOrdersProvider);
                },
                color: AppColors.primary,
                child: _activeTab == 0
                    ? _buildCollaborationsTab(requestsState)
                    : _buildOrdersTab(ordersState),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollaborationsTab(AsyncValue<List<DesignerRequest>> state) {
    return state.when(
      data: (requests) {
        // Filter requests
        final filtered = requests.where((req) {
          if (_collabFilter == 'all') return true;
          return req.status.toLowerCase() == _collabFilter;
        }).toList();

        return Column(
          children: [
            // Horizontal filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _buildFilterChip('all', 'All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('pending', 'Pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('accepted', 'Accepted'),
                  const SizedBox(width: 8),
                  _buildFilterChip('completed', 'Completed'),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState(
                      icon: Icons.face_retouching_natural,
                      title: 'No Collaborations Yet',
                      subtitle: 'Connect with verified designers to craft your tailor-made luxury spatial design.',
                      buttonText: 'BROWSE DESIGNERS',
                      onPressed: () => context.go('/designers'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final req = filtered[index];
                        return _buildCollaborationCard(req);
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Failed to load collaborations: $e',
          style: GoogleFonts.inter(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isSelected = _collabFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _collabFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCollaborationCard(DesignerRequest req) {
    final String designerName = req.userName ?? 'Elite Designer';
    final String? avatarUrl = req.userAvatarUrl;
    final String status = req.status.toLowerCase();
    
    Color statusColor = AppColors.primary;
    String statusText = 'PENDING';

    if (status == 'accepted') {
      statusColor = AppColors.success;
      statusText = 'COLLABORATION ACTIVE';
    } else if (status == 'completed') {
      statusColor = Colors.grey;
      statusText = 'COMPLETED';
    } else if (status == 'rejected') {
      statusColor = Colors.redAccent;
      statusText = 'DECLINED';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Designer header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: AppColors.textSecondary),
                        ),
                      )
                    : const Icon(Icons.person, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      designerName,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'AI Interior Architect Partner',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),

          // Detail rows
          _buildDetailRow('Room Type', req.roomType),
          const SizedBox(height: 10),
          _buildDetailRow('Access Level', req.accessLevel == 'chat_only' ? 'Consultation & Chat' : 'Full Source Access'),
          const SizedBox(height: 10),
          _buildDetailRow('Allocated Budget', req.budget),
          const SizedBox(height: 16),

          // Chat Button (only enabled for accepted requests!)
          if (status == 'accepted') ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  // Capture context-dependent services before async gap to satisfy compiler
                  final navigator = Navigator.of(context);
                  final router = GoRouter.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  try {
                     final chatRoomId = await ref.read(chatRepositoryProvider).createOrGetChatRoom(
                          userId: req.userId,
                          designerId: req.designerId,
                          requestId: req.id,
                        );

                    if (!mounted) return;
                    navigator.pop(); // Close loading dialog
                    router.push('/collaboration/chat/$chatRoomId');
                  } catch (e) {
                    if (!mounted) return;
                    navigator.pop(); // Close loading dialog
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Failed to open chat: $e')),
                    );
                  }
                },
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: Text(
                  'CHAT WITH DESIGNER',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
          if (status == 'completed') ...[
            const SizedBox(height: 4),
            ref.watch(hasUserReviewedRequestProvider(req.id)).when(
                  data: (hasReviewed) {
                    if (hasReviewed) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'REVIEW SUBMITTED',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ReviewSubmissionSheet.show(
                            context,
                            designerId: req.designerId,
                            requestId: req.id,
                            title: 'Rate Designer Experience',
                            subtitle: 'Review your collaboration with $designerName',
                          );
                        },
                        icon: const Icon(Icons.rate_review_outlined, size: 18),
                        label: Text(
                          'REVIEW DESIGNER',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab(AsyncValue<List<Order>> state) {
    return state.when(
      data: (orders) {
        if (orders.isEmpty) {
          return _buildEmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'No Orders Found',
            subtitle: 'You haven\'t ordered any curated furniture products yet. Discover premium items in our store.',
            buttonText: 'VISIT MARKETPLACE',
            onPressed: () => context.go('/marketplace'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: orders.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Failed to load orders: $e',
          style: GoogleFonts.inter(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final dateStr = DateFormat('MMM dd, yyyy').format(order.createdAt);
    
    // Status color mapping
    Color statusColor = AppColors.primary;
    String statusText = order.status.name.toUpperCase();

    if (order.status == OrderStatus.delivered) {
      statusColor = AppColors.success;
    } else if (order.status == OrderStatus.cancelled) {
      statusColor = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.orderNumber}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // Items summary
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = order.items[index];
              return Consumer(
                builder: (context, ref, child) {
                  final key = ProductOrderReviewKey(orderId: order.id, productId: item.product.id);
                  final hasReviewedAsync = order.status == OrderStatus.delivered
                      ? ref.watch(hasUserReviewedProductInOrderProvider(key))
                      : const AsyncValue<bool>.data(false);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.product.name} x${item.quantity}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (order.status == OrderStatus.delivered) ...[
                        const SizedBox(height: 6),
                        hasReviewedAsync.when(
                          data: (hasReviewed) {
                            if (hasReviewed) {
                              return Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check, color: AppColors.success, size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Reviewed',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.success,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                height: 26,
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                                    foregroundColor: AppColors.textPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onPressed: () {
                                    ReviewSubmissionSheet.show(
                                      context,
                                      productId: item.product.id,
                                      orderId: order.id,
                                      title: 'Rate Curated Product',
                                      subtitle: 'Review your purchase of ${item.product.name}',
                                    );
                                  },
                                  icon: const Icon(Icons.star_outline, size: 12),
                                  label: Text(
                                    'Review Product',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          loading: () => const Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 1.5),
                            ),
                          ),
                          error: (err, stack) => const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // Payment and Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PAYMENT METHOD',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.paymentMethod,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TOTAL AMOUNT',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3EE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: AppColors.textSecondary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  buttonText,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

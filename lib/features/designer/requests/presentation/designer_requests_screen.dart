import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import '../application/designer_request_controller.dart';
import 'designer_request_detail_screen.dart';

class DesignerRequestsScreen extends ConsumerStatefulWidget {
  const DesignerRequestsScreen({super.key});

  @override
  ConsumerState<DesignerRequestsScreen> createState() => _DesignerRequestsScreenState();
}

class _DesignerRequestsScreenState extends ConsumerState<DesignerRequestsScreen> {
  String _selectedFilter = 'all'; // 'all', 'pending', 'accepted', 'completed'

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(designerRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CLIENT REQUESTS',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'ALL',
                    isSelected: _selectedFilter == 'all',
                    onTap: () => setState(() => _selectedFilter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'PENDING',
                    isSelected: _selectedFilter == 'pending',
                    onTap: () => setState(() => _selectedFilter = 'pending'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'ACTIVE',
                    isSelected: _selectedFilter == 'accepted',
                    onTap: () => setState(() => _selectedFilter = 'accepted'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'COMPLETED',
                    isSelected: _selectedFilter == 'completed',
                    onTap: () => setState(() => _selectedFilter = 'completed'),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(designerRequestsProvider),
              child: requestsAsync.when(
                data: (requests) {
                  // Filter requests
                  final filtered = requests.where((req) {
                    if (_selectedFilter == 'all') return true;
                    return req.status == _selectedFilter;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.mail_outline, size: 48, color: AppColors.textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              'No Requests Found',
                              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Requests from clients looking to hire you for consulting or full room designs will appear here.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final req = filtered[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => DesignerRequestDetailScreen(request: req)),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F3EE),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.person, color: AppColors.textSecondary, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            req.userName ?? 'Client',
                                            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                          ),
                                          _StatusBadge(status: req.status),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Room: ${req.roomType}',
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.payments_outlined, size: 14, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Budget: ${req.budget}',
                                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w700),
                                          ),
                                          const SizedBox(width: 16),
                                          Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textSecondary.withValues(alpha: 0.7)),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${req.createdAt.month}/${req.createdAt.day}',
                                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (err, st) => Center(child: Text('Error: $err')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text = status.toUpperCase();

    switch (status) {
      case 'pending':
        bg = AppColors.primary.withValues(alpha: 0.15);
        fg = AppColors.primaryDark;
        break;
      case 'accepted':
      case 'in_progress':
        bg = const Color(0xFFE8F0FE);
        fg = const Color(0xFF1A73E8);
        text = 'ACTIVE';
        break;
      case 'completed':
        bg = AppColors.success.withValues(alpha: 0.15);
        fg = AppColors.success;
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          color: fg,
        ),
      ),
    );
  }
}

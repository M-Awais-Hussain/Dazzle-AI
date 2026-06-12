import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import '../domain/designer_request.dart';
import '../application/designer_request_controller.dart';
import 'package:ayyy/features/designer/portfolio/application/portfolio_controller.dart';
import 'package:ayyy/features/designer/collaboration/application/designer_project_provider.dart';
import '../../collaboration/presentation/collaborative_room_editor_widget.dart';
import 'package:ayyy/features/designer/collaboration/application/shared_project_providers.dart';
import 'package:ayyy/features/designer/collaboration/presentation/shared_canvas_editor_screen.dart';

class DesignerRequestDetailScreen extends ConsumerStatefulWidget {
  final DesignerRequest request;

  const DesignerRequestDetailScreen({super.key, required this.request});

  @override
  ConsumerState<DesignerRequestDetailScreen> createState() => _DesignerRequestDetailScreenState();
}

class _DesignerRequestDetailScreenState extends ConsumerState<DesignerRequestDetailScreen> {
  final _budgetController = TextEditingController();
  bool _isNegotiating = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _budgetController.text = widget.request.budget;
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _isLoading = true);
    
    if (status == 'completed') {
      final projectNotifier = ref.read(designerProjectProvider(widget.request.id));
      final project = projectNotifier.project;
      if (project != null && project.finalImageUrl != null) {
        await projectNotifier.completeProject(project.finalImageUrl!);
        await ref.read(designerProjectsProvider.notifier).addProjectWithUrl(
          title: 'Collaborative Design for ${widget.request.roomType}',
          description: 'A custom collaborative design delivered securely.',
          imageUrls: [project.finalImageUrl!, project.roomImageUrl],
          styleTags: ['Minimal', 'Modern', 'Luxe'],
          pricing: 199.00,
          projectType: widget.request.roomType,
          completionTime: 'Just now',
        );
      }
    }

    final success = await ref
        .read(designerRequestsProvider.notifier)
        .updateRequestStatus(widget.request.id, status);
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Project status updated to ${status.toUpperCase()}!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _submitNegotiation() async {
    if (_budgetController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    final success = await ref
        .read(designerRequestsProvider.notifier)
        .negotiateBudget(widget.request.id, _budgetController.text.trim());
    setState(() {
      _isLoading = false;
      _isNegotiating = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modified budget proposal sent to user successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PROJECT SPECIFICATIONS',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Client Card
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F3EE),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.person, color: AppColors.textSecondary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                req.userName ?? 'Client Inquiry',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Inquired on ${req.createdAt.year}/${req.createdAt.month}/${req.createdAt.day}',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Room Details
                  Text(
                    'DESIGN SPECIFICATIONS',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(label: 'Room Type', value: req.roomType),
                  _DetailRow(label: 'Service Mode', value: req.accessLevel == 'chat_only' ? 'Chat Consultation Only (Rs. 49)' : 'Full Space Design Assistant (Rs. 199)'),
                  
                  // Budget & Negotiation
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Proposed Budget:',
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        if (!_isNegotiating) ...[
                          Row(
                            children: [
                              Text(
                                req.budget,
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                              ),
                              if (req.status == 'pending') ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => setState(() => _isNegotiating = true),
                                  child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primaryDark),
                                ),
                              ],
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              SizedBox(
                                width: 100,
                                height: 36,
                                child: TextFormField(
                                  controller: _budgetController,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.check, color: AppColors.success, size: 18),
                                onPressed: _submitNegotiation,
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: AppColors.error, size: 18),
                                onPressed: () => setState(() => _isNegotiating = false),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 24),

                  // Preferences
                  Text(
                    'CLIENT PREFERENCES & BRIEF',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      req.preferences.isEmpty ? 'No explicit custom requests provided.' : req.preferences,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Room Photos Uploaded
                  Text(
                    'ROOM REFERENCE PHOTOGRAPHS',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  req.attachments.isEmpty
                      ? Container(
                          width: double.infinity,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              'No reference photos provided.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: req.attachments.length,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 140,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  image: DecorationImage(
                                    image: NetworkImage(req.attachments[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: 48),

                  // Operational Buttons depending on status
                  if (req.status == 'pending') ...[
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.textPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _updateStatus('accepted'),
                              child: Text(
                                'ACCEPT PROJECT',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => _updateStatus('rejected'),
                              child: Text(
                                'DECLINE',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (req.status == 'accepted' || req.status == 'in_progress') ...[
                    if (req.attachments.isNotEmpty) ...[
                      Text(
                        'COLLABORATIVE WORKSPACE',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Consumer(
                        builder: (context, ref, child) {
                          final sharedProjectAsync = ref.watch(sharedProjectByRequestIdProvider(req.id));
                          
                          return sharedProjectAsync.when(
                            data: (project) {
                              if (project == null) {
                                return SizedBox(
                                  height: 400,
                                  width: double.infinity,
                                  child: CollaborativeRoomEditorWidget(
                                    requestId: req.id,
                                    designerId: req.designerId,
                                    userId: req.userId,
                                    roomImageUrl: req.attachments.first,
                                  ),
                                );
                              }
                              
                              return SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (context) => SharedCanvasEditorScreen(projectId: project.id),
                                    ));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.brush, color: AppColors.textPrimary),
                                  label: Text(
                                    'OPEN COLLABORATIVE CANVAS',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: AppColors.textPrimary, fontSize: 13),
                                  ),
                                ),
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                            error: (e, _) => Text('Error loading shared project: $e', style: const TextStyle(color: Colors.red)),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => _updateStatus('completed'),
                            child: Text(
                              'MARK AS COMPLETED',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              // Triggers navigation to the chat room.
                              // In designer context, it opens standard chat rooms.
                              // GoRouter `/collaboration/chat/:id`
                              // Let's launch it!
                              context.push('/collaboration/chat/${req.id}');
                            },
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: Text(
                              'LAUNCH COLLABORATION CHAT',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (req.status == 'completed') ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppColors.success, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'PROJECT COMPLETED SUCCESSFULLY',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.success, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
        ],
      ),
    );
  }
}

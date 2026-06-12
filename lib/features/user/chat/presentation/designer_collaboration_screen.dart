import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/widgets/dazzle_bottom_nav.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ayyy/core/services/storage_repository.dart';
import 'package:ayyy/features/user/chat/domain/chat_message.dart';
import 'package:ayyy/features/user/chat/application/chat_provider.dart';
import 'package:ayyy/features/designer/requests/data/designer_request_repository.dart';

class DesignerCollaborationScreen extends ConsumerStatefulWidget {
  final String id;
  const DesignerCollaborationScreen({super.key, required this.id});

  @override
  ConsumerState<DesignerCollaborationScreen> createState() => _DesignerCollaborationScreenState();
}

class _DesignerCollaborationScreenState extends ConsumerState<DesignerCollaborationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _chatRoomId;
  String? _requestId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _initializeChat());
  }

  Future<void> _initializeChat() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    String targetUserId = user.id;
    String? targetDesignerId = widget.id;
    String? resolvedRoomId;

    // 1. Check if widget.id is directly a chat room ID in Supabase
    try {
      final dbRoom = await Supabase.instance.client
          .from('chat_rooms')
          .select()
          .eq('id', widget.id)
          .maybeSingle();
      if (dbRoom != null) {
        resolvedRoomId = widget.id;
        _requestId = dbRoom['request_id'] as String?;
        
        // If _requestId is missing (e.g. chat room not updated), find the latest request
        final dbDesignerId = dbRoom['designer_id'] as String?;
        final dbUserId = dbRoom['user_id'] as String?;
        if (_requestId == null && dbDesignerId != null && dbUserId != null) {
          final latestReq = await Supabase.instance.client
              .from('designer_requests')
              .select('id')
              .eq('user_id', dbUserId)
              .eq('designer_id', dbDesignerId)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          if (latestReq != null) {
            _requestId = latestReq['id'] as String;
          }
        }
      }
    } catch (_) {}

    // 2. Check if widget.id is a request ID
    if (resolvedRoomId == null) {
      final requestRepository = ref.read(designerRequestRepositoryProvider);
      try {
        final request = await requestRepository.getRequestById(widget.id);
        if (request != null) {
          targetUserId = request.userId;
          targetDesignerId = request.designerId;
          _requestId = request.id;
          resolvedRoomId = await ref.read(chatControllerProvider.notifier).createOrGetChatRoom(
            userId: targetUserId,
            designerId: targetDesignerId,
            requestId: request.id,
          );
        }
      } catch (_) {}
    }

    // 3. Fallback: treat widget.id as designer ID
    resolvedRoomId ??= await ref.read(chatControllerProvider.notifier).createOrGetChatRoom(
      userId: targetUserId,
      designerId: targetDesignerId,
    );

    if (mounted) {
      setState(() {
        _chatRoomId = resolvedRoomId;
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || _chatRoomId == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    ref.read(chatControllerProvider.notifier).sendMessage(_chatRoomId!, text, user.id);
    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_chatRoomId == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: const Center(
          child: Text(
            'Failed to load collaboration chat.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final messagesAsync = ref.watch(chatMessagesProvider(_chatRoomId!));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return messagesAsync.when(
      data: (messages) {
        // Auto scroll on new messages
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'COLLABORATION',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.check_circle_outline, color: AppColors.success),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: Text('Finish Project?', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                      content: Text('This will complete the collaboration and take you to the review screen.', style: GoogleFonts.inter()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('CANCEL', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                            final idToPass = _requestId ?? widget.id;
                            context.push('/review/$idToPass');
                          },
                          child: Text('FINISH', style: GoogleFonts.inter(color: AppColors.success, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          bottomNavigationBar: const DazzleBottomNav(currentIndex: 2),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 40,
                      height: 28,
                      child: Stack(
                        children: [
                          CircleAvatar(radius: 14, backgroundColor: Color(0xFFEEEEEE), child: Icon(Icons.person, size: 14, color: AppColors.textSecondary)),
                          Positioned(left: 12, child: CircleAvatar(radius: 14, backgroundColor: AppColors.primary, child: Icon(Icons.person, size: 14, color: AppColors.textPrimary))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Space',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          Text(
                            'Active now',
                            style: GoogleFonts.inter(fontSize: 10, color: AppColors.success),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _ChatBubble(
                      message: message,
                      isMe: message.senderId == currentUserId,
                    );
                  },
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                          if (image != null) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Uploading design asset...'),
                                duration: Duration(seconds: 2),
                              ),
                            );

                            try {
                              final storageRepo = ref.read(storageRepositoryProvider);
                              final imageUrl = await storageRepo.uploadDesignAsset(_chatRoomId!, image);

                              await ref.read(chatControllerProvider.notifier).sendMessage(
                                _chatRoomId!,
                                imageUrl,
                                currentUserId,
                              );
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to upload image: $e'), backgroundColor: AppColors.error),
                                );
                              }
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFF5F3EE), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.add, size: 20, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          style: GoogleFonts.inter(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                            filled: true,
                            fillColor: const Color(0xFFF5F3EE),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.send, size: 20, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, st) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _ChatBubble({required this.message, required this.isMe});

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  bool _isImageUrl(String text) {
    final lowercase = text.toLowerCase();
    return lowercase.startsWith('http') && (
      lowercase.endsWith('.png') ||
      lowercase.endsWith('.jpg') ||
      lowercase.endsWith('.jpeg') ||
      lowercase.endsWith('.gif') ||
      lowercase.endsWith('.webp') ||
      lowercase.contains('/storage/v1/object/public/')
    );
  }

  @override
  Widget build(BuildContext context) {
    if (message.isAttachment && message.attachmentName == 'Final Design' && message.attachmentUrl != null) {
      return _buildFinalDesignCard(context);
    }

    final isImage = _isImageUrl(message.text);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: isImage ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : const Color(0xFFF5F3EE),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(16),
              ),
            ),
            clipBehavior: isImage ? Clip.antiAlias : Clip.none,
            child: isImage
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.network(
                      message.text,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.broken_image, color: AppColors.textSecondary),
                            const SizedBox(width: 8),
                            Text('Failed to load design asset', style: GoogleFonts.inter(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  )
                : Text(
                    message.text,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(message.timestamp),
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalDesignCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.75,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3EE),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    Image.network(
                      message.attachmentUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'FINAL DESIGN',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Design Completed',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.text,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              insetPadding: EdgeInsets.zero,
                              backgroundColor: Colors.black,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  InteractiveViewer(
                                    child: Image.network(message.attachmentUrl!, fit: BoxFit.contain),
                                  ),
                                  Positioned(
                                    top: 40,
                                    right: 16,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.open_in_full, size: 18, color: AppColors.textPrimary),
                              const SizedBox(width: 8),
                              Text(
                                'Open Design',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(message.timestamp),
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

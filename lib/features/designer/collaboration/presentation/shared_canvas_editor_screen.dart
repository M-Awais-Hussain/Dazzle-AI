
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/features/designer/collaboration/application/shared_project_providers.dart';
import 'package:ayyy/features/user/marketplace/application/product_variant_providers.dart';
import 'package:ayyy/core/services/gemini_image_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:ayyy/features/designer/portfolio/application/portfolio_controller.dart';
import 'package:ayyy/features/common/canvas/presentation/widgets/perspective_product_canvas.dart';
import 'package:ayyy/features/common/canvas/presentation/widgets/perspective_canvas_controls.dart';
import 'package:ayyy/core/services/remove_bg_service.dart';
import 'package:ayyy/core/errors/exceptions.dart';
import 'package:ayyy/features/user/chat/application/chat_provider.dart';
import 'package:ayyy/core/widgets/movable_panel.dart';
import 'package:ayyy/features/user/marketplace/data/ai_room_repository.dart';
import 'package:ayyy/features/user/marketplace/data/product_variant_repository.dart';

class SharedCanvasEditorScreen extends ConsumerStatefulWidget {
  final String projectId;
  const SharedCanvasEditorScreen({super.key, required this.projectId});

  @override
  ConsumerState<SharedCanvasEditorScreen> createState() => _SharedCanvasEditorScreenState();
}

class _SharedCanvasEditorScreenState extends ConsumerState<SharedCanvasEditorScreen> {

  Uint8List? _roomBytes;
  Uint8List? _productBytes;
  bool _isLoadingImages = true;
  String? _imageLoadError;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadInitialImages();
  }

  Future<void> _loadInitialImages() async {
    setState(() {
      _isLoadingImages = true;
      _imageLoadError = null;
    });

    try {
      final project = await ref.read(sharedProjectDetailsProvider(widget.projectId).future);
      if (project == null) {
        if (mounted) setState(() { _isLoadingImages = false; _imageLoadError = 'Project not found'; });
        return;
      }

      // Ensure transformation exists before loading
      var transformation = ref.read(projectSyncProvider(widget.projectId)).transformation;
      
      // Wait for transformation to sync if null initially
      if (transformation == null) {
        await Future.delayed(const Duration(milliseconds: 500));
        transformation = ref.read(projectSyncProvider(widget.projectId)).transformation;
      }

      final productUrl = transformation?.selectedVariant ?? '';

      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10)));
      
      // Fetch in parallel for speed
      final fetchFutures = <Future>[];
      
      fetchFutures.add(dio.get(project.roomImage, options: Options(responseType: ResponseType.bytes)).then((res) {
        _roomBytes = res.data;
      }));

      if (productUrl.isNotEmpty) {
        fetchFutures.add(dio.get(productUrl, options: Options(responseType: ResponseType.bytes)).then((res) {
          _productBytes = res.data;
        }));
      }

      await Future.wait(fetchFutures);
    } catch (e) {
      debugPrint('Failed to load images: $e');
      if (mounted) {
        setState(() {
          _imageLoadError = 'Failed to load assets: $e';
        });
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingImages = false;
      });
    }
  }

  Future<void> _switchVariant(String url, {String? transparentImageUrl, String? imageId, String? productId}) async {
    setState(() => _isLoadingImages = true);
    try {
      final removeBg = ref.read(removeBgServiceProvider);
      Uint8List transparentBytes;
      if (transparentImageUrl != null && transparentImageUrl.isNotEmpty) {
        transparentBytes = await removeBg.getOrDownloadTransparent(url, transparentImageUrl);
      } else {
        transparentBytes = await removeBg.removeBackground(url);
        if (imageId != null && productId != null) {
          final repo = ref.read(aiRoomRepositoryProvider);
          final newTransparentUrl = await repo.uploadTransparentImage(productId, transparentBytes);
          await ref.read(userProductVariantRepositoryProvider).updateTransparentImageUrl(imageId, newTransparentUrl);
        }
      }
      _productBytes = transparentBytes;
      
      final syncNotifier = ref.read(projectSyncProvider(widget.projectId));
      syncNotifier.updateTransformation(
        dx: syncNotifier.transformation!.positionX,
        dy: syncNotifier.transformation!.positionY,
        scale: syncNotifier.transformation!.scale,
        rotation: syncNotifier.transformation!.rotation,
        variant: url,
      );
    } catch (e) {
      debugPrint('Error switching variant: $e');
      if (mounted) {
        final errorMsg = e is ServerException ? e.message : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load variant image: $errorMsg')),
        );
      }
    }
    setState(() => _isLoadingImages = false);
  }

  Future<void> _completeDesign() async {
    setState(() => _isGenerating = true);
    final screenSize = MediaQuery.of(context).size;
    
    try {
      final project = await ref.read(sharedProjectDetailsProvider(widget.projectId).future);
      if (project == null) return;
      
      final syncNotifier = ref.read(projectSyncProvider(widget.projectId));
      final trans = syncNotifier.transformation!;

      final geminiService = ref.read(geminiImageServiceProvider);
      
      final compositeBytes = await geminiService.compositeImagesWithTransform(
        roomImageBytes: _roomBytes!,
        productImageBytes: _productBytes!,
        dx: trans.positionX,
        dy: trans.positionY,
        scale: trans.scale,
        rotation: trans.rotation,
        tiltX: trans.tiltX,
        tiltY: trans.tiltY,
        depthScale: trans.depthScale,
        screenSize: screenSize,
      );

      final supabase = Supabase.instance.client;
      final fileName = 'final_design_${DateTime.now().millisecondsSinceEpoch}.png';
      
      await supabase.storage.from('ai-room-generations').uploadBinary(
        fileName, 
        compositeBytes,
        fileOptions: const FileOptions(contentType: 'image/png'),
      );
      
      final finalUrl = supabase.storage.from('ai-room-generations').getPublicUrl(fileName);

      await ref.read(sharedProjectControllerProvider.notifier).updateStatus(widget.projectId, 'completed', finalDesignImage: finalUrl);
      
      // Integrate into Portfolio
      await ref.read(designerProjectsProvider.notifier).addProjectWithUrl(
        title: 'Collaborative AI Design',
        description: 'A custom collaborative design session delivered securely.',
        imageUrls: [finalUrl, project.roomImage],
        styleTags: ['AI Assisted', 'Modern', 'Collaborative'],
        pricing: 199.00,
        projectType: 'Shared Canvas',
        completionTime: 'Just now',
      );

      final chatRoomId = await ref.read(chatControllerProvider.notifier).createOrGetChatRoom(
        userId: project.userId,
        designerId: project.designerId,
        requestId: project.requestId,
      );

      if (chatRoomId != null) {
        await ref.read(chatControllerProvider.notifier).sendMessage(
          chatRoomId, 
          'I have completed the final design!', 
          project.designerId,
          isAttachment: true,
          attachmentUrl: finalUrl,
          attachmentName: 'Final Design'
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Design completed and sent to user!')));
        if (context.canPop()) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to complete design: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(sharedProjectDetailsProvider(widget.projectId));
    final syncNotifier = ref.watch(projectSyncProvider(widget.projectId));

    return ListenableBuilder(
      listenable: syncNotifier,
      builder: (context, _) {
        final transformation = syncNotifier.transformation;

        if (_isLoadingImages || projectAsync.isLoading) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text('Loading project assets...', style: GoogleFonts.inter(color: Colors.white70)),
                ],
              ),
            ),
          );
        }

        if (_imageLoadError != null) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                  const SizedBox(height: 16),
                  Text(_imageLoadError!, style: GoogleFonts.inter(color: Colors.white), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadInitialImages,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: Text('Retry', style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        }

        if (transformation == null || _roomBytes == null || _productBytes == null) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.broken_image_outlined, color: Colors.white38, size: 48),
                  const SizedBox(height: 16),
                  Text('Missing required images or state.', style: GoogleFonts.inter(color: Colors.white)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white24),
                    child: Text('Go Back', style: GoogleFonts.inter(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        }

        final project = projectAsync.value;
        if (project == null) {
          return const Scaffold(
            body: Center(child: Text('Project not found')),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Canvas Area
              Positioned.fill(
                child: PerspectiveProductCanvas(
                  roomImage: _roomBytes,
                  productBytes: _productBytes!,
                  currentDx: transformation.positionX,
                  currentDy: transformation.positionY,
                  currentScale: transformation.scale,
                  currentRotation: transformation.rotation,
                  currentTiltX: transformation.tiltX,
                  currentTiltY: transformation.tiltY,
                  currentDepthScale: transformation.depthScale,
                  shadowsEnabled: true,
                  shadowOpacity: transformation.shadowOpacity,
                  shadowBlur: transformation.shadowBlur,
                  onTransformUpdated: ({required dx, required dy, required scale, required rotation, tiltX, tiltY, depthScale}) {
                    syncNotifier.updateTransformation(
                      dx: dx,
                      dy: dy,
                      scale: scale,
                      rotation: rotation,
                      tiltX: tiltX,
                      tiltY: tiltY,
                      depthScale: depthScale,
                    );
                  },
                ),
              ),
              
              // Floating Editor Controls
              MovablePanel(
                initialRight: 16,
                initialTop: MediaQuery.of(context).size.height / 3,
                child: PerspectiveCanvasControls(
                  onReset: () {
                    syncNotifier.updateTransformation(
                      dx: 0, dy: 0, 
                      scale: 1.0, 
                      rotation: 0.0,
                      tiltX: 0.0,
                      tiltY: 0.0,
                      depthScale: 1.0,
                    );
                  },
                  onResetPerspective: () {
                    syncNotifier.updateTransformation(
                      dx: transformation.positionX,
                      dy: transformation.positionY,
                      scale: transformation.scale,
                      rotation: transformation.rotation,
                      tiltX: 0.0,
                      tiltY: 0.0,
                      depthScale: 1.0,
                    );
                  },
                  onToggleShadows: () {
                    syncNotifier.updateTransformation(
                      dx: transformation.positionX, dy: transformation.positionY,
                      scale: transformation.scale, rotation: transformation.rotation,
                      shadowOpacity: transformation.shadowOpacity > 0 ? 0.0 : 0.3,
                    );
                  },
                  shadowsEnabled: transformation.shadowOpacity > 0,
                  currentTiltX: transformation.tiltX,
                  currentTiltY: transformation.tiltY,
                  onTiltXChanged: (val) => syncNotifier.updateTransformation(
                    dx: transformation.positionX, dy: transformation.positionY,
                    scale: transformation.scale, rotation: transformation.rotation,
                    tiltX: val,
                  ),
                  onTiltYChanged: (val) => syncNotifier.updateTransformation(
                    dx: transformation.positionX, dy: transformation.positionY,
                    scale: transformation.scale, rotation: transformation.rotation,
                    tiltY: val,
                  ),
                ),
              ),

              // Top App Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                        Text(
                          'Editing Canvas',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),

              // Variant Controls
              MovablePanel(
                initialLeft: 16,
                initialBottom: 140,
                child: _buildVariantPanel(context, project.productId, transformation.selectedVariant),
              ),

              // Action Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24).copyWith(bottom: 40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _isGenerating ? null : _completeDesign,
                          icon: _isGenerating 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check_circle, color: AppColors.textPrimary),
                          label: Text(
                            _isGenerating ? 'Generating Final Image...' : 'Complete Design',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
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
    );
  }

  Widget _buildVariantPanel(BuildContext context, String productId, String? currentVariant) {
    final colorsAsync = ref.watch(productColorVariantsProvider(productId));
    final imagesAsync = ref.watch(productVariantImagesProvider(productId));

    return colorsAsync.when(
      data: (colors) {
        if (colors.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: colors.map((color) {
              String? colorImageUrl;
              String? transparentImageUrl;
              String? imageId;
              if (imagesAsync.hasValue) {
                final match = imagesAsync.value!.where((i) => i.colorVariantId == color.id).firstOrNull;
                colorImageUrl = match?.imageUrl;
                transparentImageUrl = match?.transparentImageUrl;
                imageId = match?.id;
              }
              
              if (colorImageUrl == null) return const SizedBox.shrink();

              final isSelected = currentVariant == colorImageUrl;
              final c = _hexToColor(color.hexCode ?? '#FFFFFF');
              return GestureDetector(
                onTap: () {
                  if (!isSelected) {
                    _switchVariant(
                      colorImageUrl!,
                      transparentImageUrl: transparentImageUrl,
                      imageId: imageId,
                      productId: productId,
                    );
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.white24,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

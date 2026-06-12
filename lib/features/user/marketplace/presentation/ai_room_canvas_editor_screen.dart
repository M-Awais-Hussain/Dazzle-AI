import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ayyy/core/theme/app_colors.dart';
import 'package:ayyy/core/widgets/movable_panel.dart';
import 'package:ayyy/features/user/marketplace/application/ai_room_controller.dart';
import 'package:ayyy/features/user/marketplace/application/canvas_editor_provider.dart';
import 'package:ayyy/features/user/marketplace/application/product_variant_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/user/designer_directory/application/designer_directory_providers.dart';
import 'package:ayyy/features/common/canvas/presentation/widgets/perspective_product_canvas.dart';
import 'package:ayyy/features/common/canvas/presentation/widgets/perspective_canvas_controls.dart';
class AiRoomCanvasEditorScreen extends ConsumerStatefulWidget {
  final String productId;
  const AiRoomCanvasEditorScreen({super.key, required this.productId});

  @override
  ConsumerState<AiRoomCanvasEditorScreen> createState() =>
      _AiRoomCanvasEditorScreenState();
}

class _AiRoomCanvasEditorScreenState
    extends ConsumerState<AiRoomCanvasEditorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(canvasEditorProvider.notifier).resetAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(aiRoomControllerProvider);
    final canvasState = ref.watch(canvasEditorProvider);
    final canvasNotifier = ref.read(canvasEditorProvider.notifier);

    // If still removing background or error, show loading/error
    if (roomState.step == AiRoomStep.removingBackground ||
        roomState.transparentProductBytes == null) {
      return _buildLoadingScreen(roomState.stepMessage);
    }

    if (roomState.step == AiRoomStep.error) {
      return _buildErrorScreen(roomState.errorMessage ?? 'An error occurred');
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Interactive Canvas Area
          Positioned.fill(
            child: PerspectiveProductCanvas(
              roomImage: roomState.roomImagePath,
              productBytes: roomState.transparentProductBytes!,
              currentDx: canvasState.dx,
              currentDy: canvasState.dy,
              currentScale: canvasState.scale,
              currentRotation: canvasState.rotation,
              currentTiltX: canvasState.tiltX,
              currentTiltY: canvasState.tiltY,
              currentDepthScale: canvasState.depthScale,
              shadowsEnabled: canvasState.shadowsEnabled,
              shadowOpacity: canvasState.shadowOpacity,
              shadowBlur: canvasState.shadowBlur,
              onTransformUpdated: ({required dx, required dy, required scale, required rotation, tiltX, tiltY, depthScale}) {
                canvasNotifier.updateTransformation(
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

          // 2. Top App Bar (Cancel)
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
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        ref.read(aiRoomControllerProvider.notifier).cancelGeneration();
                        context.pop();
                      },
                    ),
                    Text(
                      'Position Product',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance close button
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Editor Controls
          MovablePanel(
            initialRight: 16,
            initialTop: MediaQuery.of(context).size.height / 3,
            child: PerspectiveCanvasControls(
              onReset: canvasNotifier.resetAll,
              onResetPerspective: canvasNotifier.resetPerspective,
              onToggleShadows: canvasNotifier.toggleShadows,
              shadowsEnabled: canvasState.shadowsEnabled,
              currentTiltX: canvasState.tiltX,
              currentTiltY: canvasState.tiltY,
              onTiltXChanged: (val) => canvasNotifier.updateTilt(tiltX: val),
              onTiltYChanged: (val) => canvasNotifier.updateTilt(tiltY: val),
            ),
          ),

          // 5. Variant Controls (Bottom Left)
          MovablePanel(
            initialLeft: 16,
            initialBottom: 140,
            child: _buildVariantPanel(context, ref, roomState),
          ),

          // 4. Bottom Action Bar
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
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pinch to zoom, drag to move, twist to rotate',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(aiRoomControllerProvider.notifier).generateFromCanvas(
                              dx: canvasState.dx,
                              dy: canvasState.dy,
                              scale: canvasState.scale,
                              rotation: canvasState.rotation,
                              tiltX: canvasState.tiltX,
                              tiltY: canvasState.tiltY,
                              depthScale: canvasState.depthScale,
                              screenSize: MediaQuery.of(context).size,
                            );
                        context.pushReplacement('/marketplace/product/${widget.productId}/ai-room');
                      },
                      icon: const Icon(Icons.auto_awesome, color: AppColors.primaryDark),
                      label: Text(
                        'Generate AI Preview',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => _hireDesigner(roomState),
                      icon: const Icon(Icons.people_outline, color: Colors.white),
                      label: Text(
                        'Hire Designer Instead',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
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
  }

  Future<void> _hireDesigner(AiRoomState roomState) async {
    if (roomState.roomImagePath == null || roomState.transparentProductBytes == null) return;

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final supabase = Supabase.instance.client;
      
      final userId = supabase.auth.currentUser!.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final String roomUrl;
      if (roomState.roomImagePath!.startsWith('http')) {
        roomUrl = roomState.roomImagePath!;
      } else {
        final roomBytes = await File(roomState.roomImagePath!).readAsBytes();
        final roomFileName = '$userId/hire_requests/${timestamp}_room.png';
        await supabase.storage.from('ai-room-generations').uploadBinary(
          roomFileName, 
          roomBytes,
          fileOptions: const FileOptions(contentType: 'image/png'),
        );
        roomUrl = supabase.storage.from('ai-room-generations').getPublicUrl(roomFileName);
      }

      final productBytes = roomState.transparentProductBytes!;
      final productFileName = '$userId/hire_requests/${timestamp}_product.png';

      await supabase.storage.from('ai-room-generations').uploadBinary(
        productFileName, 
        productBytes,
        fileOptions: const FileOptions(contentType: 'image/png'),
      );

      final productUrl = supabase.storage.from('ai-room-generations').getPublicUrl(productFileName);

      final canvasState = ref.read(canvasEditorProvider);
      
      ref.read(pendingHireAttachmentProvider.notifier).setMultiple(
        [roomUrl, productUrl],
        productId: widget.productId,
        canvasState: {
          'dx': canvasState.dx,
          'dy': canvasState.dy,
          'scale': canvasState.scale,
          'rotation': canvasState.rotation,
          'tilt_x': canvasState.tiltX,
          'tilt_y': canvasState.tiltY,
          'depth_scale': canvasState.depthScale,
          'shadow_opacity': canvasState.shadowOpacity,
          'shadow_blur': canvasState.shadowBlur,
          'variantImageUrl': productUrl,
        },
      );

      if (mounted) {
        Navigator.pop(context); // close loading
        context.push('/designers');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to prepare assets: $e')),
        );
      }
    }
  }

  Widget _buildLoadingScreen(String message) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              message.isNotEmpty ? message : 'Loading...',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVariantPanel(BuildContext context, WidgetRef ref, AiRoomState aiState) {
    final colorsAsync = ref.watch(productColorVariantsProvider(widget.productId));
    final layoutsAsync = ref.watch(productLayoutVariantsProvider(widget.productId));
    final imagesAsync = ref.watch(productVariantImagesProvider(widget.productId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Layouts
        layoutsAsync.when(
          data: (layouts) {
            final currentLayouts = layouts.where((l) => 
                l.colorName == null || 
                l.colorName == aiState.selectedColorName
            ).toList();

            if (currentLayouts.isEmpty) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: currentLayouts.map((layout) {
                  String? layoutImageUrl;
                  String? transparentImageUrl;
                  String? imageId;
                  if (imagesAsync.hasValue) {
                    final match = imagesAsync.value!.where((i) => i.layoutVariantId == layout.id).firstOrNull;
                    layoutImageUrl = match?.imageUrl;
                    transparentImageUrl = match?.transparentImageUrl;
                    imageId = match?.id;
                  }
                  
                  if (layoutImageUrl == null) return const SizedBox.shrink();

                  final isSelected = aiState.selectedVariantImageUrl == layoutImageUrl;
                  final isHorizontal = layout.layoutType == 'horizontal';
                  return GestureDetector(
                    onTap: () {
                      if (!isSelected) {
                        ref.read(aiRoomControllerProvider.notifier).switchVariant(
                          layoutImageUrl!,
                          transparentImageUrl: transparentImageUrl,
                          imageId: imageId,
                        );
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isHorizontal ? Icons.stay_current_landscape : Icons.stay_current_portrait,
                        size: 20,
                        color: isSelected ? AppColors.textPrimary : Colors.white70,
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, st) => const SizedBox.shrink(),
        ),

        // Colors
        colorsAsync.when(
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

                  final isSelected = aiState.selectedColorName == color.colorName;
                  final c = _hexToColor(color.hexCode ?? '#FFFFFF');
                  return GestureDetector(
                    onTap: () {
                      if (!isSelected) {
                        ref.read(aiRoomControllerProvider.notifier).switchVariant(
                          colorImageUrl!, 
                          colorName: color.colorName,
                          transparentImageUrl: transparentImageUrl,
                          imageId: imageId,
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
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (e, st) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

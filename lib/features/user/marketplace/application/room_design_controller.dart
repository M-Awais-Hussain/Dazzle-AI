import 'dart:io';
import 'dart:ui';
import 'dart:isolate';

import 'package:image/image.dart' as img;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ayyy/core/errors/exceptions.dart';
import 'package:ayyy/core/services/remove_bg_service.dart';
import 'package:ayyy/core/services/image_compositor_service.dart';
import 'package:ayyy/features/user/marketplace/data/room_design_repository.dart';
import 'package:ayyy/features/user/marketplace/domain/room_design_generation.dart';
import 'package:ayyy/features/user/marketplace/domain/product.dart';
import 'package:ayyy/features/user/marketplace/data/design_creation_repository.dart';
import 'package:ayyy/features/user/marketplace/domain/design_creation.dart';
import 'package:ayyy/features/user/marketplace/application/design_creations_provider.dart';
import 'package:ayyy/features/user/marketplace/data/product_variant_repository.dart';

// ──────────────────────────────────────────
// State Model
// ──────────────────────────────────────────

enum RoomDesignStep {
  idle,
  removingBackground,
  canvasEditor,
  analyzingRoom,
  compositing,
  completed,
  saving,
  saved,
  error,
}

class RoomDesignState {
  final RoomDesignStep step;
  final String? errorMessage;
  final String? roomImagePath;
  final Uint8List? generatedImageBytes;
  final Uint8List? transparentProductBytes;
  final String? generatedImageUrl;
  final Product? product;
  final String? selectedProductImageUrl;
  final String? selectedVariantImageUrl;
  final String? selectedColorName;
  final String? transparentImageUrl;

  const RoomDesignState({
    this.step = RoomDesignStep.idle,
    this.errorMessage,
    this.roomImagePath,
    this.generatedImageBytes,
    this.transparentProductBytes,
    this.generatedImageUrl,
    this.product,
    this.selectedProductImageUrl,
    this.selectedVariantImageUrl,
    this.selectedColorName,
    this.transparentImageUrl,
  });

  RoomDesignState copyWith({
    RoomDesignStep? step,
    String? errorMessage,
    String? roomImagePath,
    Uint8List? generatedImageBytes,
    Uint8List? transparentProductBytes,
    String? generatedImageUrl,
    Product? product,
    String? selectedProductImageUrl,
    String? selectedVariantImageUrl,
    String? selectedColorName,
    String? transparentImageUrl,
  }) {
    return RoomDesignState(
      step: step ?? this.step,
      errorMessage: errorMessage ?? this.errorMessage,
      roomImagePath: roomImagePath ?? this.roomImagePath,
      generatedImageBytes: generatedImageBytes ?? this.generatedImageBytes,
      transparentProductBytes: transparentProductBytes ?? this.transparentProductBytes,
      generatedImageUrl: generatedImageUrl ?? this.generatedImageUrl,
      product: product ?? this.product,
      selectedProductImageUrl:
          selectedProductImageUrl ?? this.selectedProductImageUrl,
      selectedVariantImageUrl: selectedVariantImageUrl ?? this.selectedVariantImageUrl,
      selectedColorName: selectedColorName ?? this.selectedColorName,
      transparentImageUrl: transparentImageUrl ?? this.transparentImageUrl,
    );
  }

  /// Human-readable step message for the loading UI.
  String get stepMessage => switch (step) {
        RoomDesignStep.idle => '',
        RoomDesignStep.removingBackground => 'Preparing product for your room...',
        RoomDesignStep.canvasEditor => 'Position your product',
        RoomDesignStep.analyzingRoom => 'Analyzing your room...',
        RoomDesignStep.compositing => 'Refining realism and lighting...',
        RoomDesignStep.completed => 'Design complete!',
        RoomDesignStep.saving => 'Saving your design...',
        RoomDesignStep.saved => 'Saved to your history!',
        RoomDesignStep.error => errorMessage ?? 'Something went wrong',
      };

  /// Step index for progress indicator (0-based, 4 total steps).
  int get stepIndex => switch (step) {
        RoomDesignStep.idle => 0,
        RoomDesignStep.removingBackground => 0,
        RoomDesignStep.canvasEditor => 1,
        RoomDesignStep.analyzingRoom => 2,
        RoomDesignStep.compositing => 2,
        RoomDesignStep.completed => 3,
        RoomDesignStep.saving => 3,
        RoomDesignStep.saved => 3,
        RoomDesignStep.error => -1,
      };

  bool get isProcessing =>
      step == RoomDesignStep.removingBackground ||
      step == RoomDesignStep.analyzingRoom ||
      step == RoomDesignStep.compositing;

  bool get isDone =>
      step == RoomDesignStep.completed ||
      step == RoomDesignStep.saving ||
      step == RoomDesignStep.saved;

  bool get isSaved => step == RoomDesignStep.saved;
}

// ──────────────────────────────────────────
// Controller (Riverpod Notifier)
// ──────────────────────────────────────────

class RoomDesignController extends Notifier<RoomDesignState> {
  CancelToken? _cancelToken;

  @override
  RoomDesignState build() => const RoomDesignState();

  /// Step 1: Prepare canvas by removing background and returning state.
  Future<void> prepareCanvas({
    required Product product,
    required String selectedImageUrl,
    required String roomImagePath,
  }) async {
    if (state.isProcessing) return;

    _cancelToken = CancelToken();

    state = RoomDesignState(
      step: RoomDesignStep.removingBackground,
      product: product,
      selectedProductImageUrl: selectedImageUrl,
      selectedVariantImageUrl: selectedImageUrl, // initialize with the same
      roomImagePath: roomImagePath,
    );

    try {
      debugPrint('[AiRoom] Step 1: Removing background for canvas...');
      final removeBg = ref.read(removeBgServiceProvider);
      final transparentBytes = await removeBg.removeBackground(
        selectedImageUrl,
        cancelToken: _cancelToken,
      );

      if (_isCancelled) return;

      state = state.copyWith(
        step: RoomDesignStep.canvasEditor,
        transparentProductBytes: transparentBytes,
      );
    } on ServerException catch (e) {
      debugPrint('[AiRoom] prepareCanvas ServerException: ${e.message}');
      state = state.copyWith(
        step: RoomDesignStep.error,
        errorMessage: e.message,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      debugPrint('[AiRoom] prepareCanvas DioException: $e');
      state = state.copyWith(
        step: RoomDesignStep.error,
        errorMessage: _friendlyError(e.toString()),
      );
    } catch (e) {
      debugPrint('[AiRoom] prepareCanvas error: $e');
      state = state.copyWith(
        step: RoomDesignStep.error,
        errorMessage: _friendlyError(e.toString()),
      );
    }
  }

  /// Switch to a different variant image while keeping canvas state
  Future<void> switchVariant(String newImageUrl, {String? colorName, String? transparentImageUrl, String? imageId}) async {
    if (state.step != RoomDesignStep.canvasEditor) return;

    // We don't want to show the full loading screen, just update state so UI can show a small spinner
    final previousBytes = state.transparentProductBytes;
    state = state.copyWith(
      transparentProductBytes: null, // Indicates loading to the UI
      selectedVariantImageUrl: newImageUrl,
      selectedColorName: colorName ?? state.selectedColorName,
    );

    try {
      final removeBg = ref.read(removeBgServiceProvider);
      Uint8List newTransparentBytes;
      
      if (transparentImageUrl != null && transparentImageUrl.isNotEmpty) {
        newTransparentBytes = await removeBg.getOrDownloadTransparent(newImageUrl, transparentImageUrl);
      } else {
        newTransparentBytes = await removeBg.removeBackground(newImageUrl);
        
        // Save back to DB for future speedups
        if (imageId != null) {
          final repo = ref.read(roomDesignRepositoryProvider);
          final newTransparentUrl = await repo.uploadTransparentImage(state.product!.id, newTransparentBytes);
          await ref.read(userProductVariantRepositoryProvider).updateTransparentImageUrl(imageId, newTransparentUrl);
        }
      }
      
      state = state.copyWith(transparentProductBytes: newTransparentBytes);
    } catch (e) {
      debugPrint('[AiRoom] switchVariant error: $e');
      final errorMsg = e is ServerException ? e.message : 'Failed to load variant image';
      // Revert if failed
      state = state.copyWith(
        transparentProductBytes: previousBytes,
        errorMessage: errorMsg,
      );
      // Clear error message after a few seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (state.errorMessage == errorMsg) {
          state = state.copyWith(errorMessage: null);
        }
      });
    }
  }

  /// Step 2: Generate final AI preview using manual canvas coordinates.
  Future<void> generateFromCanvas({
    required double dx,
    required double dy,
    required double scale,
    required double rotation,
    double tiltX = 0.0,
    double tiltY = 0.0,
    double depthScale = 1.0,
    required Size screenSize,
  }) async {
    if (state.transparentProductBytes == null || state.roomImagePath == null) return;
    
    _cancelToken = CancelToken();

    try {
      state = state.copyWith(step: RoomDesignStep.compositing);
      debugPrint('[AiRoom] Step 2: Compositing images with canvas data...');

      final gemini = ref.read(imageCompositorServiceProvider);
      
      final Uint8List roomBytes;
      if (state.roomImagePath!.startsWith('http')) {
        final response = await Dio().get<List<int>>(
          state.roomImagePath!,
          options: Options(responseType: ResponseType.bytes),
        );
        roomBytes = Uint8List.fromList(response.data!);
      } else {
        roomBytes = await File(state.roomImagePath!).readAsBytes();
      }

      // We'll update ImageCompositorService to handle these exact parameters
      final compositeBytes = await gemini.compositeImagesWithTransform(
        roomImageBytes: roomBytes,
        productImageBytes: state.transparentProductBytes!,
        dx: dx,
        dy: dy,
        scale: scale,
        rotation: rotation,
        tiltX: tiltX,
        tiltY: tiltY,
        depthScale: depthScale,
        screenSize: screenSize,
      );

      state = state.copyWith(
        step: RoomDesignStep.completed,
        generatedImageBytes: compositeBytes,
      );
      debugPrint('[AiRoom] Canvas Pipeline completed successfully!');
    } catch (e) {
      state = state.copyWith(
        step: RoomDesignStep.error,
        errorMessage: _friendlyError(e.toString()),
      );
    }
  }

  /// Persist the generated result to Supabase storage + database.
  Future<void> saveToHistory() async {
    if (state.generatedImageBytes == null ||
        state.product == null ||
        state.step == RoomDesignStep.saving ||
        state.step == RoomDesignStep.saved) {
      return;
    }

    final previousStep = state.step;
    state = state.copyWith(step: RoomDesignStep.saving);

    try {
      final repo = ref.read(roomDesignRepositoryProvider);
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final product = state.product!;
      
      final Uint8List roomBytes;
      if (state.roomImagePath!.startsWith('http')) {
        final response = await Dio().get<List<int>>(
          state.roomImagePath!,
          options: Options(responseType: ResponseType.bytes),
        );
        roomBytes = Uint8List.fromList(response.data!);
      } else {
        roomBytes = await File(state.roomImagePath!).readAsBytes();
      }

      // Compress room image before upload to save bandwidth and time
      final Uint8List compressedRoomBytes;
      if (state.roomImagePath!.startsWith('http')) {
        compressedRoomBytes = roomBytes;
      } else {
        compressedRoomBytes = await Isolate.run(() {
          final image = img.decodeImage(roomBytes);
          if (image == null) return roomBytes;
          
          var resized = image;
          if (image.width > 1600 || image.height > 1600) {
            resized = img.copyResize(image, width: image.width > image.height ? 1600 : 0, height: image.height >= image.width ? 1600 : 0);
          }
          return Uint8List.fromList(img.encodeJpg(resized, quality: 75));
        });
      }

      // Upload room image (only if it's not already a network URL, otherwise we could just reuse it)
      final roomImageUrl = state.roomImagePath!.startsWith('http') 
          ? state.roomImagePath! 
          : await repo.uploadRoomImage(userId, compressedRoomBytes);

      // Upload transparent product image only if we haven't already uploaded it in this session
      String transparentImageUrl = state.transparentImageUrl ?? '';
      if (transparentImageUrl.isEmpty) {
        final removeBg = ref.read(removeBgServiceProvider);
        final transparentBytes = await removeBg.removeBackground(
          state.selectedProductImageUrl!,
        );
        transparentImageUrl = await repo.uploadTransparentImage(
          product.id,
          transparentBytes,
        );
        // Cache the URL so we don't upload again if they generate another variation
        state = state.copyWith(transparentImageUrl: transparentImageUrl);
      }

      // Upload generated composite
      final generatedImageUrl = await repo.uploadGeneratedImage(
        userId,
        product.id,
        state.generatedImageBytes!,
      );

      // Save record to database
      final generation = RoomDesignGeneration(
        id: '', // Auto-generated by Supabase
        userId: userId,
        productId: product.id,
        originalProductImage: state.selectedProductImageUrl!,
        transparentProductImage: transparentImageUrl,
        roomImage: roomImageUrl,
        generatedImage: generatedImageUrl,
        productDescription: product.description,
        createdAt: DateTime.now(),
      );

      await repo.saveGeneration(generation);

      // ALSO save record to ai_creations table
      // Note: We don't have the transformation state directly in RoomDesignState yet,
      // but it could be saved if we persist it to the state. For now, it will be null unless passed.
      final creation = DesignCreation(
        id: '',
        userId: userId,
        productId: product.id,
        generatedImageUrl: generatedImageUrl,
        roomImageUrl: roomImageUrl,
        transparentProductUrl: transparentImageUrl,
        selectedProductImageUrl: state.selectedProductImageUrl!,
        productName: product.name,
        productDescription: product.description,
        generationPrompt: 'A beautiful luxury room composited with the premium ${product.name}.',
        createdAt: DateTime.now(),
        generationVersion: 'v2_canvas',
      );

      await ref.read(designCreationRepositoryProvider).saveCreation(creation);

      state = state.copyWith(
        step: RoomDesignStep.saved,
        generatedImageUrl: generatedImageUrl,
      );

      // Invalidate history caches
      ref.invalidate(roomDesignHistoryProvider);
      ref.invalidate(designCreationsProvider);
      ref.invalidate(recentCreationsProvider);

      debugPrint('[AiRoom] Saved to history successfully');
    } catch (e) {
      final errorMsg = e is ServerException ? e.message : _friendlyError(e.toString());
      // Revert to previous step on failure
      state = state.copyWith(
        step: previousStep,
        errorMessage: 'Failed to save: $errorMsg',
      );
    }
  }

  /// Re-run the generation pipeline with the same inputs.
  Future<void> regenerate() async {
    if (state.product != null &&
        state.selectedProductImageUrl != null &&
        state.roomImagePath != null) {
      await prepareCanvas(
        product: state.product!,
        selectedImageUrl: state.selectedProductImageUrl!,
        roomImagePath: state.roomImagePath!,
      );
    }
  }

  /// Cancel in-progress generation and reset to idle.
  void cancelGeneration() {
    _cancelToken?.cancel('User cancelled');
    _cancelToken = null;
    state = const RoomDesignState();
  }

  /// Reset state back to idle.
  void reset() {
    _cancelToken?.cancel('Reset');
    _cancelToken = null;
    state = const RoomDesignState();
  }

  bool get _isCancelled =>
      _cancelToken?.isCancelled == true || state.step == RoomDesignStep.idle;

  String _friendlyError(String error) {
    if (error.contains('SocketException') ||
        error.contains('NetworkException') ||
        error.contains('connection')) {
      return 'Network connection lost. Please check your internet and try again.';
    }
    if (error.contains('402') || error.contains('credits')) {
      return 'API credits exhausted. Please try again later.';
    }
    if (error.contains('Remove.bg') || error.contains('remove.bg')) {
      return 'Background removal failed. Please try again.';
    }
    if (error.contains('Gemini') || error.contains('AI analysis')) {
      return 'Room analysis failed. Please try again.';
    }
    if (error.contains('coordinates')) {
      return 'Could not determine product placement. Please try a different room photo.';
    }
    return 'Something went wrong. Please try again.';
  }
}

// ──────────────────────────────────────────
// Providers
// ──────────────────────────────────────────

final roomDesignControllerProvider =
    NotifierProvider<RoomDesignController, RoomDesignState>(() {
  return RoomDesignController();
});

final roomDesignHistoryProvider =
    FutureProvider<List<RoomDesignGeneration>>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  return ref.watch(roomDesignRepositoryProvider).getGenerationHistory(userId);
});

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ayyy/core/services/remove_bg_service.dart';
import 'package:ayyy/core/services/gemini_image_service.dart';
import 'package:ayyy/features/user/marketplace/data/ai_room_repository.dart';
import 'package:ayyy/features/user/marketplace/domain/ai_room_generation.dart';
import 'package:ayyy/features/user/marketplace/domain/product.dart';
import 'package:ayyy/features/user/marketplace/data/ai_creation_repository.dart';
import 'package:ayyy/features/user/marketplace/domain/ai_creation.dart';
import 'package:ayyy/features/user/marketplace/application/ai_creations_provider.dart';

// ──────────────────────────────────────────
// State Model
// ──────────────────────────────────────────

enum AiRoomStep {
  idle,
  removingBackground,
  analyzingRoom,
  compositing,
  completed,
  saving,
  saved,
  error,
}

class AiRoomState {
  final AiRoomStep step;
  final String? errorMessage;
  final String? roomImagePath;
  final Uint8List? generatedImageBytes;
  final String? generatedImageUrl;
  final Product? product;
  final String? selectedProductImageUrl;

  const AiRoomState({
    this.step = AiRoomStep.idle,
    this.errorMessage,
    this.roomImagePath,
    this.generatedImageBytes,
    this.generatedImageUrl,
    this.product,
    this.selectedProductImageUrl,
  });

  AiRoomState copyWith({
    AiRoomStep? step,
    String? errorMessage,
    String? roomImagePath,
    Uint8List? generatedImageBytes,
    String? generatedImageUrl,
    Product? product,
    String? selectedProductImageUrl,
  }) {
    return AiRoomState(
      step: step ?? this.step,
      errorMessage: errorMessage ?? this.errorMessage,
      roomImagePath: roomImagePath ?? this.roomImagePath,
      generatedImageBytes: generatedImageBytes ?? this.generatedImageBytes,
      generatedImageUrl: generatedImageUrl ?? this.generatedImageUrl,
      product: product ?? this.product,
      selectedProductImageUrl:
          selectedProductImageUrl ?? this.selectedProductImageUrl,
    );
  }

  /// Human-readable step message for the loading UI.
  String get stepMessage => switch (step) {
        AiRoomStep.idle => '',
        AiRoomStep.removingBackground => 'Removing background...',
        AiRoomStep.analyzingRoom => 'AI is analyzing your room...',
        AiRoomStep.compositing => 'Placing product in your room...',
        AiRoomStep.completed => 'Design complete!',
        AiRoomStep.saving => 'Saving your design...',
        AiRoomStep.saved => 'Saved to your history!',
        AiRoomStep.error => errorMessage ?? 'Something went wrong',
      };

  /// Step index for progress indicator (0-based, 4 total steps).
  int get stepIndex => switch (step) {
        AiRoomStep.idle => 0,
        AiRoomStep.removingBackground => 0,
        AiRoomStep.analyzingRoom => 1,
        AiRoomStep.compositing => 2,
        AiRoomStep.completed => 3,
        AiRoomStep.saving => 3,
        AiRoomStep.saved => 3,
        AiRoomStep.error => -1,
      };

  bool get isProcessing =>
      step == AiRoomStep.removingBackground ||
      step == AiRoomStep.analyzingRoom ||
      step == AiRoomStep.compositing;

  bool get isDone =>
      step == AiRoomStep.completed ||
      step == AiRoomStep.saving ||
      step == AiRoomStep.saved;

  bool get isSaved => step == AiRoomStep.saved;
}

// ──────────────────────────────────────────
// Controller (Riverpod Notifier)
// ──────────────────────────────────────────

class AiRoomController extends Notifier<AiRoomState> {
  CancelToken? _cancelToken;

  @override
  AiRoomState build() => const AiRoomState();

  /// Main pipeline: remove background → analyze room → composite.
  /// The result is displayed immediately from local bytes.
  /// Call [saveToHistory] separately to persist to Supabase.
  Future<void> startGeneration({
    required Product product,
    required String selectedImageUrl,
    required String roomImagePath,
  }) async {
    // Prevent duplicate requests
    if (state.isProcessing) return;

    _cancelToken = CancelToken();

    state = AiRoomState(
      step: AiRoomStep.removingBackground,
      product: product,
      selectedProductImageUrl: selectedImageUrl,
      roomImagePath: roomImagePath,
    );

    try {
      // ── Step 1: Remove background via remove.bg ──
      debugPrint('[AiRoom] Step 1: Removing background...');
      final removeBg = ref.read(removeBgServiceProvider);
      final transparentBytes = await removeBg.removeBackground(
        selectedImageUrl,
        cancelToken: _cancelToken,
      );

      if (_isCancelled) return;

      // ── Step 2: Get placement coordinates from Gemini ──
      state = state.copyWith(step: AiRoomStep.analyzingRoom);
      debugPrint('[AiRoom] Step 2: Analyzing room with Gemini...');

      final gemini = ref.read(geminiImageServiceProvider);
      final roomBytes = await File(roomImagePath).readAsBytes();

      final coordinates = await gemini.getPlacementCoordinates(
        roomImageBytes: roomBytes,
        productImageBytes: transparentBytes,
        productName: product.name,
        productCategory: product.category,
        productDescription: product.description,
        cancelToken: _cancelToken,
      );

      if (_isCancelled) return;

      // ── Step 3: Composite images ──
      state = state.copyWith(step: AiRoomStep.compositing);
      debugPrint('[AiRoom] Step 3: Compositing images...');

      final compositeBytes = await gemini.compositeImages(
        roomImageBytes: roomBytes,
        productImageBytes: transparentBytes,
        coordinates: coordinates,
      );

      // ── Done — show result immediately ──
      state = state.copyWith(
        step: AiRoomStep.completed,
        generatedImageBytes: compositeBytes,
      );
      debugPrint('[AiRoom] Pipeline completed successfully!');
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        debugPrint('[AiRoom] Generation cancelled by user');
        return;
      }
      state = state.copyWith(
        step: AiRoomStep.error,
        errorMessage: _friendlyError(e.toString()),
      );
    } catch (e) {
      state = state.copyWith(
        step: AiRoomStep.error,
        errorMessage: _friendlyError(e.toString()),
      );
    }
  }

  /// Persist the generated result to Supabase storage + database.
  Future<void> saveToHistory() async {
    if (state.generatedImageBytes == null ||
        state.product == null ||
        state.step == AiRoomStep.saving ||
        state.step == AiRoomStep.saved) {
      return;
    }

    final previousStep = state.step;
    state = state.copyWith(step: AiRoomStep.saving);

    try {
      final repo = ref.read(aiRoomRepositoryProvider);
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final product = state.product!;
      final roomBytes = await File(state.roomImagePath!).readAsBytes();

      // Upload room image
      final roomImageUrl = await repo.uploadRoomImage(userId, roomBytes);

      // Upload transparent product image (re-fetch from cache)
      final removeBg = ref.read(removeBgServiceProvider);
      final transparentBytes = await removeBg.removeBackground(
        state.selectedProductImageUrl!,
      );
      final transparentImageUrl = await repo.uploadTransparentImage(
        product.id,
        transparentBytes,
      );

      // Upload generated composite
      final generatedImageUrl = await repo.uploadGeneratedImage(
        userId,
        product.id,
        state.generatedImageBytes!,
      );

      // Save record to database
      final generation = AiRoomGeneration(
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
      final creation = AiCreation(
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
        generationVersion: 'v1',
      );

      await ref.read(aiCreationRepositoryProvider).saveCreation(creation);

      state = state.copyWith(
        step: AiRoomStep.saved,
        generatedImageUrl: generatedImageUrl,
      );

      // Invalidate history caches
      ref.invalidate(aiRoomHistoryProvider);
      ref.invalidate(aiCreationsProvider);
      ref.invalidate(recentCreationsProvider);

      debugPrint('[AiRoom] Saved to history successfully');
    } catch (e) {
      // Revert to previous step on failure
      state = state.copyWith(
        step: previousStep,
        errorMessage: 'Failed to save: ${_friendlyError(e.toString())}',
      );
    }
  }

  /// Re-run the generation pipeline with the same inputs.
  Future<void> regenerate() async {
    if (state.product != null &&
        state.selectedProductImageUrl != null &&
        state.roomImagePath != null) {
      await startGeneration(
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
    state = const AiRoomState();
  }

  /// Reset state back to idle.
  void reset() {
    _cancelToken?.cancel('Reset');
    _cancelToken = null;
    state = const AiRoomState();
  }

  bool get _isCancelled =>
      _cancelToken?.isCancelled == true || state.step == AiRoomStep.idle;

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
      return 'AI room analysis failed. Please try again.';
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

final aiRoomControllerProvider =
    NotifierProvider<AiRoomController, AiRoomState>(() {
  return AiRoomController();
});

final aiRoomHistoryProvider =
    FutureProvider<List<AiRoomGeneration>>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  return ref.watch(aiRoomRepositoryProvider).getGenerationHistory(userId);
});

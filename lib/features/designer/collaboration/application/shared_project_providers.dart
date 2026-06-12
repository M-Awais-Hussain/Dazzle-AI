import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayyy/features/designer/collaboration/data/shared_canvas_repository.dart';
import 'package:ayyy/features/designer/collaboration/domain/shared_project.dart';

// --- Single Project Details Provider ---
final sharedProjectDetailsProvider = FutureProvider.family<SharedProject?, String>((ref, projectId) async {
  return ref.watch(sharedCanvasRepositoryProvider).getSharedProject(projectId);
});

final sharedProjectByRequestIdProvider = FutureProvider.family<SharedProject?, String>((ref, requestId) async {
  return ref.watch(sharedCanvasRepositoryProvider).getSharedProjectByRequestId(requestId);
});

// --- Projects List Providers ---
final designerSharedProjectsProvider = FutureProvider.family<List<SharedProject>, String>((ref, designerId) async {
  return ref.watch(sharedCanvasRepositoryProvider).getSharedProjectsForDesigner(designerId);
});

final userSharedProjectsProvider = FutureProvider.family<List<SharedProject>, String>((ref, userId) async {
  return ref.watch(sharedCanvasRepositoryProvider).getSharedProjectsForUser(userId);
});

// --- Real-time Sync Provider for Canvas Transformations ---
final projectSyncProvider = Provider.family<ProjectSyncNotifier, String>((ref, projectId) {
  final repository = ref.watch(sharedCanvasRepositoryProvider);
  final notifier = ProjectSyncNotifier(projectId, repository);
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

class ProjectSyncNotifier extends ChangeNotifier {
  final String projectId;
  final SharedCanvasRepository repository;
  
  StreamSubscription? _dbSubscription;
  Timer? _debounceTimer;
  Timer? _throttleTimer;
  bool _hasPendingBroadcast = false;

  ProjectTransformation? _transformation;
  ProjectTransformation? get transformation => _transformation;

  ProjectSyncNotifier(this.projectId, this.repository) {
    _init();
  }

  void _init() {
    _dbSubscription = repository.streamTransformation(projectId).listen((newTrans) {
      if (newTrans != null) {
        _transformation = newTrans;
        notifyListeners();
      }
    });

    repository.setupBroadcastChannel(
      projectId,
      onTransformationReceived: (newTrans) {
        _transformation = newTrans;
        notifyListeners();
      },
    );
  }

  void updateTransformation({
    required double dx,
    required double dy,
    required double scale,
    required double rotation,
    double? tiltX,
    double? tiltY,
    double? depthScale,
    double? shadowOpacity,
    double? shadowBlur,
    String? variant,
  }) {
    if (_transformation == null) return;

    final updated = _transformation!.copyWith(
      positionX: dx,
      positionY: dy,
      scale: scale,
      rotation: rotation,
      tiltX: tiltX ?? _transformation!.tiltX,
      tiltY: tiltY ?? _transformation!.tiltY,
      depthScale: depthScale ?? _transformation!.depthScale,
      shadowOpacity: shadowOpacity ?? _transformation!.shadowOpacity,
      shadowBlur: shadowBlur ?? _transformation!.shadowBlur,
      selectedVariant: variant ?? _transformation!.selectedVariant,
    );

    _transformation = updated;
    notifyListeners();

    // Throttle WebSocket broadcast to ~15fps (every 66ms) instead of 60fps
    if (_throttleTimer == null || !_throttleTimer!.isActive) {
      repository.broadcastTransformation(updated);
      _throttleTimer = Timer(const Duration(milliseconds: 66), () {
        if (_hasPendingBroadcast) {
          repository.broadcastTransformation(_transformation!);
          _hasPendingBroadcast = false;
        }
      });
    } else {
      _hasPendingBroadcast = true;
    }

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      repository.saveTransformation(updated);
    });
  }

  @override
  void dispose() {
    _dbSubscription?.cancel();
    _debounceTimer?.cancel();
    _throttleTimer?.cancel();
    repository.dispose();
    super.dispose();
  }
}

// --- Creation & Status Controllers ---
class SharedProjectController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<SharedProject?> createProject({
    String? requestId,
    required String designerId,
    required String productId,
    required String roomImage,
    required Map<String, dynamic> currentCanvasState,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(sharedCanvasRepositoryProvider);
      final project = await repository.createSharedProject(
        requestId: requestId,
        designerId: designerId,
        productId: productId,
        roomImage: roomImage,
        currentCanvasState: currentCanvasState,
      );
      state = const AsyncData(null);
      return project;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  Future<void> updateStatus(String projectId, String status, {String? finalDesignImage}) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(sharedCanvasRepositoryProvider);
      await repository.updateProjectStatus(projectId, status, finalDesignImage: finalDesignImage);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final sharedProjectControllerProvider = AsyncNotifierProvider<SharedProjectController, void>(SharedProjectController.new);

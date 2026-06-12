import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayyy/features/designer/collaboration/data/collaborative_editor_repository.dart';
import 'package:ayyy/features/designer/collaboration/domain/designer_project.dart';

final collaborativeEditorProvider = Provider.family<CollaborativeEditorNotifier, String>((ref, projectId) {
  final repository = ref.watch(collaborativeEditorRepositoryProvider);
  final notifier = CollaborativeEditorNotifier(projectId, repository);
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

class CollaborativeEditorNotifier extends ChangeNotifier {
  final String projectId;
  final CollaborativeEditorRepository repository;
  StreamSubscription? _dbSubscription;
  Timer? _debounceTimer;

  List<DesignerProjectItem> _items = [];
  List<DesignerProjectItem> get items => _items;

  CollaborativeEditorNotifier(this.projectId, this.repository) {
    _init();
  }

  void _init() {
    _dbSubscription = repository.streamProjectItems(projectId).listen((newItems) {
      _items = newItems;
      notifyListeners();
    });

    repository.setupBroadcastChannel(
      projectId,
      onTransformationReceived: (item) {
        _items = [
          for (final i in _items)
            if (i.id == item.id) item else i,
        ];
        notifyListeners();
      },
    );
  }

  void updateItemTransformation({
    required String itemId,
    required double dx,
    required double dy,
    required double scale,
    required double rotation,
    double? tiltX,
    double? tiltY,
    double? depthScale,
  }) {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final updatedItem = _items[index].copyWith(
      positionX: dx,
      positionY: dy,
      scale: scale,
      rotation: rotation,
      tiltX: tiltX ?? _items[index].tiltX,
      tiltY: tiltY ?? _items[index].tiltY,
      depthScale: depthScale ?? _items[index].depthScale,
    );

    _items = [
      for (final i in _items)
        if (i.id == itemId) updatedItem else i,
    ];
    notifyListeners();

    repository.broadcastTransformation(updatedItem);

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      repository.saveItemTransformation(updatedItem);
    });
  }

  Future<void> addItem(String productId) async {
    try {
      await repository.addItemToProject(projectId, productId);
    } catch (e) {
      debugPrint('Error adding item: $e');
    }
  }

  Future<void> removeItem(String itemId) async {
    try {
      await repository.removeItem(itemId);
    } catch (e) {
      debugPrint('Error removing item: $e');
    }
  }

  @override
  void dispose() {
    _dbSubscription?.cancel();
    _debounceTimer?.cancel();
    repository.dispose();
    super.dispose();
  }
}

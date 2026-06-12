import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayyy/features/designer/collaboration/data/collaborative_editor_repository.dart';
import 'package:ayyy/features/designer/collaboration/domain/designer_project.dart';

final designerProjectProvider = Provider.family<DesignerProjectNotifier, String>((ref, requestId) {
  final repository = ref.watch(collaborativeEditorRepositoryProvider);
  final notifier = DesignerProjectNotifier(requestId, repository);
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

class DesignerProjectNotifier extends ChangeNotifier {
  final String requestId;
  final CollaborativeEditorRepository repository;
  
  DesignerProject? _project;
  DesignerProject? get project => _project;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  DesignerProjectNotifier(this.requestId, this.repository) {
    _loadProject();
  }

  Future<void> _loadProject() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _project = await repository.getProjectByRequestId(requestId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createProject({
    required String designerId,
    required String userId,
    required String roomImageUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _project = await repository.createProject(
        requestId: requestId,
        designerId: designerId,
        userId: userId,
        roomImageUrl: roomImageUrl,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeProject(String finalImageUrl) async {
    if (_project == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _project = await repository.updateProjectStatus(
        _project!.id,
        'completed',
        finalImageUrl: finalImageUrl,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateAiPreview() async {
    if (_project == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.delayed(const Duration(seconds: 3));
      final updatedImageUrl = "${_project!.roomImageUrl}?ai_enhanced=true";
      _project = await repository.updateProjectStatus(
        _project!.id,
        _project!.status,
        finalImageUrl: updatedImageUrl,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayyy/features/designer/collaboration/application/collaborative_editor_provider.dart';
import 'package:ayyy/features/designer/collaboration/application/designer_project_provider.dart';
import 'package:ayyy/features/designer/collaboration/domain/designer_project.dart';
import 'package:ayyy/features/common/canvas/presentation/widgets/canvas_shadow_painter.dart';

class CollaborativeRoomEditorWidget extends ConsumerStatefulWidget {
  final String requestId;
  final String designerId;
  final String userId;
  final String roomImageUrl;

  const CollaborativeRoomEditorWidget({
    super.key,
    required this.requestId,
    required this.designerId,
    required this.userId,
    required this.roomImageUrl,
  });

  @override
  ConsumerState<CollaborativeRoomEditorWidget> createState() => _CollaborativeRoomEditorWidgetState();
}

class _CollaborativeRoomEditorWidgetState extends ConsumerState<CollaborativeRoomEditorWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(designerProjectProvider(widget.requestId)).createProject(
            designerId: widget.designerId,
            userId: widget.userId,
            roomImageUrl: widget.roomImageUrl,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(designerProjectProvider(widget.requestId));

    return ListenableBuilder(
      listenable: projectState,
      builder: (context, _) {
        if (projectState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (projectState.error != null) {
          return Center(child: Text('Error: ${projectState.error}'));
        }

        final project = projectState.project;
        if (project == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final editorState = ref.watch(collaborativeEditorProvider(project.id));

        return ListenableBuilder(
          listenable: editorState,
          builder: (context, _) {
            final items = editorState.items;

            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Room Image
                  Image.network(
                    project.roomImageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                    ),
                  ),

                  // Interactive Items
                  for (final item in items)
                    _DraggableItemWidget(
                      item: item,
                      projectId: project.id,
                    ),

                  // Add Dummy Item Button for Demo Purposes
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FloatingActionButton(
                          mini: true,
                          onPressed: () {
                            ref.read(collaborativeEditorProvider(project.id)).addItem('dummy_product_id');
                          },
                          child: const Icon(Icons.add),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurpleAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onPressed: () async {
                            await ref.read(designerProjectProvider(widget.requestId)).generateAiPreview();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Enhanced Preview Generated!')),
                              );
                            }
                          },
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Generate Preview', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DraggableItemWidget extends ConsumerStatefulWidget {
  final DesignerProjectItem item;
  final String projectId;

  const _DraggableItemWidget({required this.item, required this.projectId});

  @override
  ConsumerState<_DraggableItemWidget> createState() => _DraggableItemWidgetState();
}

class _DraggableItemWidgetState extends ConsumerState<_DraggableItemWidget> {
  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  Offset _basePosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001)
      ..multiply(Matrix4.translationValues(widget.item.positionX, widget.item.positionY, 0.0))
      ..multiply(Matrix4.diagonal3Values(widget.item.scale * widget.item.depthScale, widget.item.scale * widget.item.depthScale, 1.0))
      ..rotateZ(widget.item.rotation)
      ..rotateX(widget.item.tiltX)
      ..rotateY(widget.item.tiltY);

    return Positioned.fill(
      child: GestureDetector(
        onScaleStart: (details) {
          _baseScale = widget.item.scale;
          _baseRotation = widget.item.rotation;
          _basePosition = Offset(widget.item.positionX, widget.item.positionY);
        },
        onScaleUpdate: (details) {
          _basePosition += details.focalPointDelta;
          
          final screenHeight = MediaQuery.of(context).size.height;
          final normalizedY = (_basePosition.dy / (screenHeight / 2)).clamp(-1.0, 1.0);
          final newDepth = 1.0 + (normalizedY * 0.4);

          ref.read(collaborativeEditorProvider(widget.projectId)).updateItemTransformation(
                itemId: widget.item.id,
                dx: _basePosition.dx,
                dy: _basePosition.dy,
                scale: (_baseScale * details.scale).clamp(0.2, 5.0),
                rotation: _baseRotation + details.rotation,
                depthScale: newDepth,
              );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.item.shadowOpacity > 0)
              CustomPaint(
                painter: CanvasShadowPainter(
                  dx: widget.item.positionX,
                  dy: widget.item.positionY,
                  scale: widget.item.scale,
                  rotation: widget.item.rotation,
                  tiltX: widget.item.tiltX,
                  tiltY: widget.item.tiltY,
                  depthScale: widget.item.depthScale,
                  shadowsEnabled: true,
                  shadowOpacity: widget.item.shadowOpacity,
                  shadowBlur: widget.item.shadowBlur,
                ),
                child: Container(),
              ),
            Transform(
              transform: matrix,
              alignment: Alignment.center,
              child: Center(
                child: Stack(
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.5),
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.chair, size: 50, color: Colors.white),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          ref.read(collaborativeEditorProvider(widget.projectId)).removeItem(widget.item.id);
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

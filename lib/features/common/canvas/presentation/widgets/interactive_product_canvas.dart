import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

@Deprecated('Use PerspectiveProductCanvas instead for 2.5D perspective support')
class InteractiveProductCanvas extends StatefulWidget {
  final dynamic roomImage; // String (URL/Path) or Uint8List
  final Uint8List productBytes;
  final double currentDx;
  final double currentDy;
  final double currentScale;
  final double currentRotation;
  final void Function({
    required double dx,
    required double dy,
    required double scale,
    required double rotation,
  }) onTransformUpdated;

  const InteractiveProductCanvas({
    super.key,
    required this.roomImage,
    required this.productBytes,
    required this.currentDx,
    required this.currentDy,
    required this.currentScale,
    required this.currentRotation,
    required this.onTransformUpdated,
  });

  @override
  State<InteractiveProductCanvas> createState() => _InteractiveProductCanvasState();
}

class _InteractiveProductCanvasState extends State<InteractiveProductCanvas> {
  double _localDx = 0;
  double _localDy = 0;
  double _localScale = 1.0;
  double _localRotation = 0.0;

  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  Offset _basePosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _localDx = widget.currentDx;
    _localDy = widget.currentDy;
    _localScale = widget.currentScale;
    _localRotation = widget.currentRotation;
  }

  @override
  void didUpdateWidget(InteractiveProductCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the parent passes entirely new values (e.g. Center button clicked)
    if (widget.currentDx != oldWidget.currentDx ||
        widget.currentDy != oldWidget.currentDy ||
        widget.currentScale != oldWidget.currentScale ||
        widget.currentRotation != oldWidget.currentRotation) {
      _localDx = widget.currentDx;
      _localDy = widget.currentDy;
      _localScale = widget.currentScale;
      _localRotation = widget.currentRotation;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: (details) {
        _baseScale = _localScale;
        _baseRotation = _localRotation;
        _basePosition = Offset(_localDx, _localDy);
      },
      onScaleUpdate: (details) {
        setState(() {
          _basePosition += details.focalPointDelta;
          _localDx = _basePosition.dx;
          _localDy = _basePosition.dy;
          _localScale = (_baseScale * details.scale).clamp(0.2, 5.0);
          _localRotation = _baseRotation + details.rotation;
        });
        widget.onTransformUpdated(
          dx: _localDx,
          dy: _localDy,
          scale: _localScale,
          rotation: _localRotation,
        );
      },
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            _buildRoomImage(),

            // Product Image
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(_localDx, _localDy),
                child: Transform.scale(
                  scale: _localScale,
                  child: Transform.rotate(
                    angle: _localRotation,
                    child: Center(
                      child: Image.memory(
                        widget.productBytes,
                        fit: BoxFit.contain,
                        width: MediaQuery.of(context).size.width * 0.6,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomImage() {
    if (widget.roomImage == null) return const SizedBox.shrink();
    
    if (widget.roomImage is Uint8List) {
      return Image.memory(
        widget.roomImage as Uint8List,
        fit: BoxFit.contain,
      );
    } else if (widget.roomImage is String) {
      final path = widget.roomImage as String;
      if (path.startsWith('http')) {
        return Image.network(
          path,
          fit: BoxFit.contain,
        );
      } else {
        return Image.file(
          File(path),
          fit: BoxFit.contain,
        );
      }
    }
    return const SizedBox.shrink();
  }
}

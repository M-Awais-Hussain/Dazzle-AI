import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'canvas_shadow_painter.dart';

class PerspectiveProductCanvas extends StatefulWidget {
  final dynamic roomImage; // String (URL/Path) or Uint8List
  final Uint8List productBytes;
  
  final double currentDx;
  final double currentDy;
  final double currentScale;
  final double currentRotation;
  final double currentTiltX;
  final double currentTiltY;
  final double currentDepthScale;
  
  final bool shadowsEnabled;
  final double shadowOpacity;
  final double shadowBlur;

  final void Function({
    required double dx,
    required double dy,
    required double scale,
    required double rotation,
    double? tiltX,
    double? tiltY,
    double? depthScale,
  }) onTransformUpdated;

  const PerspectiveProductCanvas({
    super.key,
    required this.roomImage,
    required this.productBytes,
    required this.currentDx,
    required this.currentDy,
    required this.currentScale,
    required this.currentRotation,
    this.currentTiltX = 0.0,
    this.currentTiltY = 0.0,
    this.currentDepthScale = 1.0,
    this.shadowsEnabled = true,
    this.shadowOpacity = 0.3,
    this.shadowBlur = 8.0,
    required this.onTransformUpdated,
  });

  @override
  State<PerspectiveProductCanvas> createState() => _PerspectiveProductCanvasState();
}

class _PerspectiveProductCanvasState extends State<PerspectiveProductCanvas> {
  double _localDx = 0;
  double _localDy = 0;
  double _localScale = 1.0;
  double _localRotation = 0.0;
  double _localTiltX = 0.0;
  double _localTiltY = 0.0;
  double _localDepthScale = 1.0;

  double _baseScale = 1.0;
  double _baseRotation = 0.0;
  Offset _basePosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _syncStateFromWidget();
  }

  @override
  void didUpdateWidget(PerspectiveProductCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync state if it changed externally (e.g. from editor controls)
    if (widget.currentDx != oldWidget.currentDx ||
        widget.currentDy != oldWidget.currentDy ||
        widget.currentScale != oldWidget.currentScale ||
        widget.currentRotation != oldWidget.currentRotation ||
        widget.currentTiltX != oldWidget.currentTiltX ||
        widget.currentTiltY != oldWidget.currentTiltY ||
        widget.currentDepthScale != oldWidget.currentDepthScale) {
      _syncStateFromWidget();
    }
  }

  void _syncStateFromWidget() {
    _localDx = widget.currentDx;
    _localDy = widget.currentDy;
    _localScale = widget.currentScale;
    _localRotation = widget.currentRotation;
    _localTiltX = widget.currentTiltX;
    _localTiltY = widget.currentTiltY;
    _localDepthScale = widget.currentDepthScale;
  }

  void _computeDepthScale() {
    // Simple heuristic: Objects higher up (negative dy) are further away, thus smaller.
    // Assuming screen height roughly 800px.
    final screenHeight = MediaQuery.of(context).size.height;
    // Map dy from [-screenHeight/2, screenHeight/2] to [0.5, 1.5]
    final normalizedY = (_localDy / (screenHeight / 2)).clamp(-1.0, 1.0);
    // If normalizedY is -1 (top), depthScale is 0.6. If +1 (bottom), depthScale is 1.4.
    _localDepthScale = 1.0 + (normalizedY * 0.4);
  }

  @override
  Widget build(BuildContext context) {
    // Matrix4 transform: Translate -> DepthScale -> UserScale -> RotateZ -> TiltX -> TiltY -> Perspective
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // Add perspective distortion
      ..multiply(Matrix4.translationValues(_localDx, _localDy, 0.0))
      ..multiply(Matrix4.diagonal3Values(_localScale * _localDepthScale, _localScale * _localDepthScale, 1.0))
      ..rotateZ(_localRotation)
      ..rotateX(_localTiltX)
      ..rotateY(_localTiltY);

    return RepaintBoundary(
      child: GestureDetector(
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
            
            _computeDepthScale();
          });
          
          widget.onTransformUpdated(
            dx: _localDx,
            dy: _localDy,
            scale: _localScale,
            rotation: _localRotation,
            tiltX: _localTiltX,
            tiltY: _localTiltY,
            depthScale: _localDepthScale,
          );
        },
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background Room Image
              _buildRoomImage(),

              // Shadows
              if (widget.shadowsEnabled)
                CustomPaint(
                  painter: CanvasShadowPainter(
                    dx: _localDx,
                    dy: _localDy,
                    scale: _localScale,
                    rotation: _localRotation,
                    tiltX: _localTiltX,
                    tiltY: _localTiltY,
                    depthScale: _localDepthScale,
                    shadowsEnabled: widget.shadowsEnabled,
                    shadowOpacity: widget.shadowOpacity,
                    shadowBlur: widget.shadowBlur,
                  ),
                  child: Container(),
                ),

              // Product Image with Matrix4
              Positioned.fill(
                child: Transform(
                  transform: matrix,
                  alignment: Alignment.center,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      child: Image.memory(
                        widget.productBytes,
                        key: ValueKey(widget.productBytes.hashCode),
                        fit: BoxFit.contain,
                        width: MediaQuery.of(context).size.width * 0.6,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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

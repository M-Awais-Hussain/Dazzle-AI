import 'package:flutter_riverpod/flutter_riverpod.dart';

class CanvasTransformation {
  final double dx;
  final double dy;
  final double scale;
  final double rotation;
  final double tiltX;
  final double tiltY;
  final double depthScale;
  final bool shadowsEnabled;
  final double shadowOpacity;
  final double shadowBlur;

  const CanvasTransformation({
    this.dx = 0,
    this.dy = 0,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.tiltX = 0.0,
    this.tiltY = 0.0,
    this.depthScale = 1.0,
    this.shadowsEnabled = true,
    this.shadowOpacity = 0.3,
    this.shadowBlur = 8.0,
  });

  CanvasTransformation copyWith({
    double? dx,
    double? dy,
    double? scale,
    double? rotation,
    double? tiltX,
    double? tiltY,
    double? depthScale,
    bool? shadowsEnabled,
    double? shadowOpacity,
    double? shadowBlur,
  }) {
    return CanvasTransformation(
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      tiltX: tiltX ?? this.tiltX,
      tiltY: tiltY ?? this.tiltY,
      depthScale: depthScale ?? this.depthScale,
      shadowsEnabled: shadowsEnabled ?? this.shadowsEnabled,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      shadowBlur: shadowBlur ?? this.shadowBlur,
    );
  }
}

class CanvasEditorNotifier extends Notifier<CanvasTransformation> {
  @override
  CanvasTransformation build() {
    return const CanvasTransformation();
  }

  void updateTransformation({
    double? dx,
    double? dy,
    double? scale,
    double? rotation,
    double? tiltX,
    double? tiltY,
    double? depthScale,
  }) {
    state = state.copyWith(
      dx: dx,
      dy: dy,
      scale: scale,
      rotation: rotation,
      tiltX: tiltX,
      tiltY: tiltY,
      depthScale: depthScale,
    );
  }

  void updateTilt({double? tiltX, double? tiltY}) {
    state = state.copyWith(tiltX: tiltX, tiltY: tiltY);
  }

  void resetPosition() {
    state = state.copyWith(dx: 0, dy: 0);
  }

  void resetRotation() {
    state = state.copyWith(rotation: 0);
  }

  void resetPerspective() {
    state = state.copyWith(tiltX: 0, tiltY: 0, depthScale: 1.0);
  }

  void resetScale() {
    state = state.copyWith(scale: 1.0);
  }

  void resetAll() {
    state = const CanvasTransformation();
  }

  void toggleShadows() {
    state = state.copyWith(shadowsEnabled: !state.shadowsEnabled);
  }
}

final canvasEditorProvider = NotifierProvider<CanvasEditorNotifier, CanvasTransformation>(() {
  return CanvasEditorNotifier();
});

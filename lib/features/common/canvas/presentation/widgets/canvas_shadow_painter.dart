import 'package:flutter/material.dart';

class CanvasShadowPainter extends CustomPainter {
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

  CanvasShadowPainter({
    required this.dx,
    required this.dy,
    required this.scale,
    required this.rotation,
    required this.tiltX,
    required this.tiltY,
    required this.depthScale,
    required this.shadowsEnabled,
    required this.shadowOpacity,
    required this.shadowBlur,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!shadowsEnabled || shadowOpacity <= 0) return;

    final centerX = size.width / 2 + dx;
    final centerY = size.height / 2 + dy;
    
    // Dynamic shadow positioning based on tilt and scale
    // 1. Tilt affects shadow offset (tilting object pushes shadow away)
    final shadowDx = tiltY * 100 * scale; 
    // 2. Base shadow sits slightly below the object center, affected by tiltX
    final shadowDy = tiltX * 100 * scale + (80 * scale * depthScale); 

    // Compute dimensions
    final shadowWidth = 250 * scale * depthScale * (1 - tiltX.abs() * 0.5);
    final shadowHeight = 60 * scale * depthScale;

    final shadowRect = Rect.fromCenter(
      center: Offset(centerX + shadowDx, centerY + shadowDy),
      width: shadowWidth,
      height: shadowHeight,
    );

    // Apply blur based on depth
    final currentBlur = (shadowBlur * scale * depthScale).clamp(2.0, 24.0);

    final paint = Paint()
      ..color = Colors.black.withValues(alpha: shadowOpacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, currentBlur);

    canvas.save();
    
    // Rotate shadow to match object rotation
    canvas.translate(centerX + shadowDx, centerY + shadowDy);
    canvas.rotate(rotation);
    canvas.translate(-(centerX + shadowDx), -(centerY + shadowDy));
    
    canvas.drawOval(shadowRect, paint);
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CanvasShadowPainter oldDelegate) {
    return dx != oldDelegate.dx ||
        dy != oldDelegate.dy ||
        scale != oldDelegate.scale ||
        rotation != oldDelegate.rotation ||
        tiltX != oldDelegate.tiltX ||
        tiltY != oldDelegate.tiltY ||
        depthScale != oldDelegate.depthScale ||
        shadowsEnabled != oldDelegate.shadowsEnabled ||
        shadowOpacity != oldDelegate.shadowOpacity ||
        shadowBlur != oldDelegate.shadowBlur;
  }
}

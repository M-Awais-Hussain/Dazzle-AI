import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final imageCompositorServiceProvider = Provider<ImageCompositorService>((ref) {
  return ImageCompositorService();
});

class ImageCompositorService {
  /// Composites the product image onto the room image using explicit manual
  /// transform values (dx, dy, scale, rotation) from the Canvas Editor.
  Future<Uint8List> compositeImagesWithTransform({
    required Uint8List roomImageBytes,
    required Uint8List productImageBytes,
    required double dx,
    required double dy,
    required double scale,
    required double rotation,
    double tiltX = 0.0,
    double tiltY = 0.0,
    double depthScale = 1.0,
    required ui.Size screenSize,
  }) async {
    final roomCodec = await ui.instantiateImageCodec(roomImageBytes);
    final roomFrame = await roomCodec.getNextFrame();
    final roomImage = roomFrame.image;

    final productCodec = await ui.instantiateImageCodec(productImageBytes);
    final productFrame = await productCodec.getNextFrame();
    final productImage = productFrame.image;

    final double wS = screenSize.width;
    final double hS = screenSize.height;

    final double wR = roomImage.width.toDouble();
    final double hR = roomImage.height.toDouble();

    final double wP = productImage.width.toDouble();
    final double hP = productImage.height.toDouble();

    // 1. Room image scale on screen (matches BoxFit.contain in PerspectiveProductCanvas)
    final double sR = (wS / wR < hS / hR) ? (wS / wR) : (hS / hR);

    // Room image top-left offset on screen
    final double offsetX = (wS - wR * sR) / 2.0;
    final double offsetY = (hS - hR * sR) / 2.0;

    // 2. Product image scale on screen (based on MediaQuery width * 0.6)
    final double sP = (wS * 0.6) / wP;

    // Product image center on screen
    final double cxScreen = (wS / 2.0) + dx;
    final double cyScreen = (hS / 2.0) + dy;

    // Product image center in room image coordinates
    final double cxImage = (cxScreen - offsetX) / sR;
    final double cyImage = (cyScreen - offsetY) / sR;

    // Product image drawing scale relative to room image
    final double drawScale = (sP * scale) / sR;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Draw room background
    canvas.drawImage(roomImage, Offset.zero, Paint());

    // Apply transformations and draw product
    canvas.save();
    
    // Move to the position where the user dragged it in image coordinates
    canvas.translate(cxImage, cyImage);

    // Apply the full perspective matrix similar to the canvas widget
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // perspective
      ..multiply(Matrix4.diagonal3Values(drawScale * depthScale, drawScale * depthScale, 1.0))
      ..rotateZ(rotation)
      ..rotateX(tiltX)
      ..rotateY(tiltY);
      
    canvas.transform(matrix.storage);

    // Translate by half of product image dimensions to center it
    canvas.translate(-wP / 2.0, -hP / 2.0);

    canvas.drawImage(productImage, Offset.zero, Paint());
    
    canvas.restore();

    final picture = recorder.endRecording();
    final compositeImage = await picture.toImage(roomImage.width, roomImage.height);
    final byteData = await compositeImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    roomImage.dispose();
    productImage.dispose();
    compositeImage.dispose();

    return byteData!.buffer.asUint8List();
  }
}

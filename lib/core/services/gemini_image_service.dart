import 'dart:convert';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ayyy/core/config/env_config.dart';
import 'package:ayyy/core/errors/exceptions.dart';

final geminiImageServiceProvider = Provider<GeminiImageService>((ref) {
  return GeminiImageService();
});

/// Normalized bounding-box coordinates (0–1000 scale), matching
/// the Python prototype's [ymin, xmin, ymax, xmax] format.
class PlacementCoordinates {
  final int ymin;
  final int xmin;
  final int ymax;
  final int xmax;

  const PlacementCoordinates({
    required this.ymin,
    required this.xmin,
    required this.ymax,
    required this.xmax,
  });

  @override
  String toString() =>
      'PlacementCoordinates(ymin: $ymin, xmin: $xmin, ymax: $ymax, xmax: $xmax)';
}

class GeminiImageService {
  static const _maxRetries = 3;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 120),
    ),
  );

  /// Asks Gemini 2.5 Flash to analyze the room and product images,
  /// returning bounding-box coordinates for intelligent product placement.
  Future<PlacementCoordinates> getPlacementCoordinates({
    required Uint8List roomImageBytes,
    required Uint8List productImageBytes,
    required String productName,
    required String productCategory,
    required String productDescription,
    CancelToken? cancelToken,
  }) async {
    final apiKey = EnvConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      throw ServerException('Gemini API key not configured');
    }

    final roomBase64 = base64Encode(roomImageBytes);
    final productBase64 = base64Encode(productImageBytes);

    final prompt = _buildPrompt(
      productName: productName,
      productCategory: productCategory,
      productDescription: productDescription,
    );

    int attempt = 0;

    while (attempt < _maxRetries) {
      try {
        debugPrint('[Gemini] Attempt ${attempt + 1}/$_maxRetries — requesting placement coordinates');

        final response = await _dio.post(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent',
          queryParameters: {'key': apiKey},
          data: {
            'contents': [
              {
                'parts': [
                  {
                    'inline_data': {
                      'mime_type': 'image/jpeg',
                      'data': roomBase64,
                    }
                  },
                  {
                    'inline_data': {
                      'mime_type': 'image/png',
                      'data': productBase64,
                    }
                  },
                  {'text': prompt},
                ]
              }
            ],
            'generationConfig': {
              'responseMimeType': 'application/json',
            },
          },
          cancelToken: cancelToken,
        );

        if (response.statusCode == 200) {
          final candidates = response.data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]['content']['parts'] as List;
            final text = (parts[0]['text'] as String).trim();

            debugPrint('[Gemini] Raw response: $text');

            // Parse coordinates using regex — same approach as Python prototype
            final numbers = RegExp(r'\d+')
                .allMatches(text)
                .map((m) => int.parse(m.group(0)!))
                .toList();

            if (numbers.length >= 4) {
              final coords = PlacementCoordinates(
                ymin: numbers[0],
                xmin: numbers[1],
                ymax: numbers[2],
                xmax: numbers[3],
              );
              debugPrint('[Gemini] Parsed coordinates: $coords');
              return coords;
            }
          }
          throw ServerException(
            'Invalid response from Gemini: could not extract coordinates',
          );
        }

        throw ServerException('Gemini returned status ${response.statusCode}');
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) rethrow;

        attempt++;
        if (attempt >= _maxRetries) {
          throw ServerException(
            'AI analysis failed: ${e.message}',
            code: e.response?.statusCode?.toString(),
          );
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      } on ServerException {
        rethrow;
      } catch (e) {
        throw ServerException('AI analysis failed: $e');
      }
    }

    throw ServerException('AI analysis failed after $_maxRetries attempts');
  }

  /// Composites the product image onto the room image at the
  /// bounding box specified by [coordinates], using dart:ui Canvas.
  /// Respects the product image's alpha channel for transparency.
  Future<Uint8List> compositeImages({
    required Uint8List roomImageBytes,
    required Uint8List productImageBytes,
    required PlacementCoordinates coordinates,
  }) async {
    // Decode both images
    final roomCodec = await ui.instantiateImageCodec(roomImageBytes);
    final roomFrame = await roomCodec.getNextFrame();
    final roomImage = roomFrame.image;

    final productCodec = await ui.instantiateImageCodec(productImageBytes);
    final productFrame = await productCodec.getNextFrame();
    final productImage = productFrame.image;

    final w = roomImage.width;
    final h = roomImage.height;

    // Map normalized coordinates (0–1000) to pixel coordinates
    final pixelXmin = (coordinates.xmin / 1000.0 * w).round();
    final pixelXmax = (coordinates.xmax / 1000.0 * w).round();
    final pixelYmin = (coordinates.ymin / 1000.0 * h).round();
    final pixelYmax = (coordinates.ymax / 1000.0 * h).round();

    debugPrint('[Composite] Canvas: ${w}x$h');
    debugPrint('[Composite] Placement: ($pixelXmin,$pixelYmin) → ($pixelXmax,$pixelYmax)');

    // Create canvas and draw composite
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Draw room as base layer
    canvas.drawImage(roomImage, Offset.zero, Paint());

    // Draw product at computed location — Paint() with default BlendMode.srcOver
    // automatically respects the product PNG's alpha channel
    final srcRect = Rect.fromLTWH(
      0,
      0,
      productImage.width.toDouble(),
      productImage.height.toDouble(),
    );
    final dstRect = Rect.fromLTRB(
      pixelXmin.toDouble(),
      pixelYmin.toDouble(),
      pixelXmax.toDouble(),
      pixelYmax.toDouble(),
    );
    canvas.drawImageRect(productImage, srcRect, dstRect, Paint());

    // Render to PNG bytes
    final picture = recorder.endRecording();
    final compositeImage = await picture.toImage(w, h);
    final byteData = await compositeImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    // Dispose native resources
    roomImage.dispose();
    productImage.dispose();
    compositeImage.dispose();

    return byteData!.buffer.asUint8List();
  }

  String _buildPrompt({
    required String productName,
    required String productCategory,
    required String productDescription,
  }) {
    return '''
Analyze Image 1 (a room photograph/space) and Image 2 (a piece of furniture or home decor with transparent background).

Product: $productName
Category: $productCategory
Description: $productDescription

I want to place the product from Image 2 naturally into the room from Image 1.

Consider:
- The type of product (e.g., sofa goes on floor, wall art goes on wall, lamp goes on table/floor, rug goes on floor)
- Realistic proportions relative to the room and existing furniture
- Proper perspective and visual harmony
- Natural placement that an interior designer would choose
- The product should not overlap with existing furniture or obstruct walkways

Provide your output ONLY as a JSON array containing the normalized 0-1000 coordinates in this format:
[ymin, xmin, ymax, xmax]

Where coordinates are normalized from 0-1000 relative to the room image dimensions.
Do not write markdown block fences, explanation text, or conversational lines. Just the array.
''';
  }
}

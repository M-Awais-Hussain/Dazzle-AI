
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ayyy/core/config/env_config.dart';
import 'package:ayyy/core/errors/exceptions.dart';

final removeBgServiceProvider = Provider<RemoveBgService>((ref) {
  return RemoveBgService();
});

class RemoveBgService {
  static const _endpoint = 'https://api.remove.bg/v1.0/removebg';
  static const _maxRetries = 3;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  /// In-memory cache: product image URL → transparent PNG bytes.
  /// Prevents burning remove.bg credits for repeated views of the same product.
  final Map<String, Uint8List> _cache = {};

  /// Remove background from an image at the given [imageUrl].
  /// Returns transparent PNG as [Uint8List].
  Future<Uint8List> removeBackground(
    String imageUrl, {
    CancelToken? cancelToken,
  }) async {
    // Return cached result if available
    if (_cache.containsKey(imageUrl)) {
      debugPrint('[RemoveBg] Cache hit for: $imageUrl');
      return _cache[imageUrl]!;
    }

    final apiKey = EnvConfig.removeBgApiKey;
    if (apiKey.isEmpty) {
      throw ServerException('Remove.bg API key not configured');
    }

    int attempt = 0;

    while (attempt < _maxRetries) {
      try {
        debugPrint('[RemoveBg] Attempt ${attempt + 1}/$_maxRetries');

        final response = await _dio.post(
          _endpoint,
          data: FormData.fromMap({
            'image_url': imageUrl,
            'size': 'auto',
            'format': 'png',
          }),
          options: Options(
            headers: {'X-Api-Key': apiKey},
            responseType: ResponseType.bytes,
          ),
          cancelToken: cancelToken,
        );

        if (response.statusCode == 200 && response.data != null) {
          final bytes = Uint8List.fromList(response.data as List<int>);
          _cache[imageUrl] = bytes; // Cache for future use
          debugPrint('[RemoveBg] Success — ${bytes.length} bytes');
          return bytes;
        }

        throw ServerException(
          'Remove.bg returned status ${response.statusCode}',
        );
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) rethrow;

        attempt++;
        if (attempt >= _maxRetries) {
          final statusCode = e.response?.statusCode;
          String message = 'Background removal failed';
          if (statusCode == 402) {
            message = 'Remove.bg API credits exhausted';
          } else if (statusCode == 429) {
            message = 'Too many requests — please wait and try again';
          }
          throw ServerException(message, code: statusCode?.toString());
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }

    throw ServerException(
      'Background removal failed after $_maxRetries attempts',
    );
  }

  void clearCache() => _cache.clear();
}

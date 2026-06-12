
import 'dart:convert';

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
        debugPrint('[RemoveBg] DioException on attempt ${attempt + 1}: ${e.message}');
        if (e.response != null) {
          debugPrint('[RemoveBg] Response status: ${e.response?.statusCode}');
          try {
            if (e.response!.data is List<int>) {
              final errorMsg = utf8.decode(e.response!.data as List<int>);
              debugPrint('[RemoveBg] Response body: $errorMsg');
            } else {
              debugPrint('[RemoveBg] Response body: ${e.response!.data}');
            }
          } catch (decodeError) {
            debugPrint('[RemoveBg] Could not decode response body: $decodeError');
          }
        }

        if (CancelToken.isCancel(e)) rethrow;

        // If it's a non-retryable error, fail immediately without wasting retries/credits
        if (!_isRetryable(e)) {
          final statusCode = e.response?.statusCode;
          String message = 'Background removal failed';
          if (statusCode == 402) {
            message = 'Remove.bg API credits exhausted';
          } else if (statusCode == 403) {
            message = 'Invalid Remove.bg API key or unauthorized access';
          } else {
            message = _parseErrorMessage(e, message);
          }
          final errCode = _parseErrorCode(e) ?? statusCode?.toString();
          throw ServerException(message, code: errCode);
        }

        attempt++;
        if (attempt >= _maxRetries) {
          final statusCode = e.response?.statusCode;
          String message = 'Background removal failed after $_maxRetries attempts';
          message = _parseErrorMessage(e, message);
          final errCode = _parseErrorCode(e) ?? statusCode?.toString();
          throw ServerException(message, code: errCode);
        }
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }

    throw ServerException(
      'Background removal failed after $_maxRetries attempts',
    );
  }

  /// Fast path: Download an already-processed transparent image from a URL (e.g. Supabase Storage)
  /// and cache it under the [originalImageUrl] key so it behaves like the API.
  Future<Uint8List> getOrDownloadTransparent(
    String originalImageUrl,
    String transparentUrl, {
    CancelToken? cancelToken,
  }) async {
    if (_cache.containsKey(originalImageUrl)) {
      return _cache[originalImageUrl]!;
    }
    
    try {
      debugPrint('[RemoveBg] Fast path download for: $originalImageUrl');
      final response = await _dio.get(
        transparentUrl,
        options: Options(responseType: ResponseType.bytes),
        cancelToken: cancelToken,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final bytes = Uint8List.fromList(response.data as List<int>);
        _cache[originalImageUrl] = bytes;
        return bytes;
      }
      throw ServerException('Failed to download transparent image');
    } catch (e) {
      debugPrint('[RemoveBg] Failed fast path download: $e');
      rethrow;
    }
  }

  /// Pre-fetches a list of transparent images in the background to ensure instantaneous switching.
  Future<void> preFetchTransparentImages(Map<String, String> variantsMap) async {
    final futures = <Future>[];
    for (final entry in variantsMap.entries) {
      final originalUrl = entry.key;
      final transparentUrl = entry.value;
      
      if (!_cache.containsKey(originalUrl) && transparentUrl.isNotEmpty) {
        futures.add(getOrDownloadTransparent(originalUrl, transparentUrl).catchError((_) => Uint8List(0)));
      }
    }
    
    if (futures.isNotEmpty) {
      debugPrint('[RemoveBg] Pre-fetching ${futures.length} transparent images...');
      await Future.wait(futures);
    }
  }

  bool _isRetryable(DioException e) {
    final response = e.response;
    if (response == null) return true;
    final statusCode = response.statusCode;
    if (statusCode == null) return true;
    return statusCode == 408 || statusCode == 429 || statusCode >= 500;
  }

  String _parseErrorMessage(DioException e, String defaultMessage) {
    if (e.response != null && e.response!.data != null) {
      try {
        final data = e.response!.data;
        final String jsonStr;
        if (data is List<int>) {
          jsonStr = utf8.decode(data);
        } else if (data is String) {
          jsonStr = data;
        } else {
          jsonStr = jsonEncode(data);
        }
        
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map && decoded['errors'] is List && (decoded['errors'] as List).isNotEmpty) {
          final errorObj = decoded['errors'][0];
          if (errorObj is Map) {
            return errorObj['detail'] ?? errorObj['title'] ?? defaultMessage;
          }
        }
      } catch (decodeError) {
        debugPrint('[RemoveBg] Error parsing error response: $decodeError');
      }
    }
    return defaultMessage;
  }

  String? _parseErrorCode(DioException e) {
    if (e.response != null && e.response!.data != null) {
      try {
        final data = e.response!.data;
        final String jsonStr;
        if (data is List<int>) {
          jsonStr = utf8.decode(data);
        } else if (data is String) {
          jsonStr = data;
        } else {
          jsonStr = jsonEncode(data);
        }
        
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map && decoded['errors'] is List && (decoded['errors'] as List).isNotEmpty) {
          final errorObj = decoded['errors'][0];
          if (errorObj is Map) {
            return errorObj['code']?.toString();
          }
        }
      } catch (_) {}
    }
    return null;
  }

  void clearCache() => _cache.clear();
}

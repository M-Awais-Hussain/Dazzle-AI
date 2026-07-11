import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/core/errors/exceptions.dart';
import 'package:ayyy/features/user/marketplace/domain/design_creation.dart';

final designCreationRepositoryProvider = Provider<DesignCreationRepository>((ref) {
  return DesignCreationRepository(Supabase.instance.client);
});

class DesignCreationRepository {
  final SupabaseClient _supabase;
  static const _table = 'ai_creations';
  static const _bucket = 'ai-room-generations';

  DesignCreationRepository(this._supabase);

  Future<void> saveCreation(DesignCreation creation) async {
    try {
      await _supabase.from(_table).insert(creation.toInsertJson());
    } catch (e) {
      throw ServerException('Failed to save design creation: $e');
    }
  }

  Future<List<DesignCreation>> getCreations({
    required String userId,
    int limit = 20,
    int offset = 0,
    String? searchQuery,
    String? sortBy, // 'newest' | 'oldest' | 'product'
  }) async {
    try {
      dynamic query = _supabase.from(_table).select().eq('user_id', userId);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('product_name', '%$searchQuery%');
      }

      if (sortBy == 'oldest') {
        query = query.order('created_at', ascending: true);
      } else if (sortBy == 'product') {
        query = query.order('product_name', ascending: true);
      } else {
        // default newest
        query = query.order('created_at', ascending: false);
      }

      final response = await query.range(offset, offset + limit - 1);
      return (response as List)
          .map((json) => DesignCreation.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch design creations: $e');
    }
  }

  Future<DesignCreation> getCreationById(String id) async {
    try {
      final response = await _supabase.from(_table).select().eq('id', id).single();
      return DesignCreation.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      throw ServerException('Failed to fetch design creation details: $e');
    }
  }

  Future<void> deleteCreation(String id, {List<String>? imageUrlsToDelete}) async {
    try {
      // 1. Delete DB record
      await _supabase.from(_table).delete().eq('id', id);

      // 2. Safely parse and delete images from Storage bucket
      if (imageUrlsToDelete != null && imageUrlsToDelete.isNotEmpty) {
        final paths = imageUrlsToDelete.map((url) {
          try {
            final uri = Uri.parse(url);
            final segments = uri.pathSegments;
            final bucketIndex = segments.indexOf(_bucket);
            if (bucketIndex != -1 && bucketIndex < segments.length - 1) {
              return segments.sublist(bucketIndex + 1).join('/');
            }
          } catch (_) {
            // Ignore parsing errors for mock or external URLs
          }
          return '';
        }).where((path) => path.isNotEmpty).toList();

        if (paths.isNotEmpty) {
          await _supabase.storage.from(_bucket).remove(paths);
        }
      }
    } catch (e) {
      throw ServerException('Failed to delete design creation: $e');
    }
  }
}

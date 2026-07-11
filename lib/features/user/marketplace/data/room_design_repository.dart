
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:ayyy/core/errors/exceptions.dart';
import 'package:ayyy/features/user/marketplace/domain/room_design_generation.dart';

final roomDesignRepositoryProvider = Provider<AiRoomRepository>((ref) {
  return AiRoomRepository(Supabase.instance.client);
});

class AiRoomRepository {
  final SupabaseClient _supabase;

  /// Storage bucket name — must be created manually in Supabase Dashboard.
  static const _bucket = 'ai-room-generations';
  static const _table = 'ai_room_generations';

  AiRoomRepository(this._supabase);

  // ──────────────────────────────────────────
  // Storage Uploads
  // ──────────────────────────────────────────

  Future<String> uploadRoomImage(String userId, Uint8List bytes) async {
    try {
      final fileName = '$userId/rooms/${const Uuid().v4()}.jpg';
      await _supabase.storage.from(_bucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      return _supabase.storage.from(_bucket).getPublicUrl(fileName);
    } catch (e) {
      throw ServerException('Failed to upload room image: $e');
    }
  }

  Future<String> uploadTransparentImage(
    String productId,
    Uint8List bytes,
  ) async {
    try {
      final fileName = 'products/${productId}_transparent_${const Uuid().v4()}.png';
      await _supabase.storage.from(_bucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/png'),
          );
      return _supabase.storage.from(_bucket).getPublicUrl(fileName);
    } catch (e) {
      throw ServerException('Failed to upload transparent image: $e');
    }
  }

  Future<String> uploadGeneratedImage(
    String userId,
    String productId,
    Uint8List bytes,
  ) async {
    try {
      final fileName = '$userId/generated/${productId}_${const Uuid().v4()}.png';
      await _supabase.storage.from(_bucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/png'),
          );
      return _supabase.storage.from(_bucket).getPublicUrl(fileName);
    } catch (e) {
      throw ServerException('Failed to upload generated image: $e');
    }
  }

  // ──────────────────────────────────────────
  // Database Operations
  // ──────────────────────────────────────────

  Future<void> saveGeneration(RoomDesignGeneration generation) async {
    try {
      await _supabase.from(_table).insert(generation.toInsertJson());
      debugPrint('[AiRoomRepo] Generation saved to database');
    } catch (e) {
      throw ServerException('Failed to save generation record: $e');
    }
  }

  Future<List<RoomDesignGeneration>> getGenerationHistory(String userId) async {
    try {
      final response = await _supabase
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) =>
              RoomDesignGeneration.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      throw ServerException('Failed to fetch generation history: $e');
    }
  }

  Future<void> deleteGeneration(String id) async {
    try {
      await _supabase.from(_table).delete().eq('id', id);
    } catch (e) {
      throw ServerException('Failed to delete generation: $e');
    }
  }
}

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService(Supabase.instance.client);
});

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  // Expose auth state
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  // Realtime Chat Methods
  Stream<List<Map<String, dynamic>>> getChatMessages(String chatId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at');
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
  }) async {
    await _client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': senderId,
      'content': content,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // File Upload Methods
  Future<String> uploadImage(String bucket, String path, List<int> bytes) async {
    await _client.storage.from(bucket).uploadBinary(path, Uint8List.fromList(bytes));
    return _client.storage.from(bucket).getPublicUrl(path);
  }
}

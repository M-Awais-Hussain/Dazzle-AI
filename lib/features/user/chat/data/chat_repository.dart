import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ayyy/features/user/chat/domain/chat_message.dart';
import 'package:ayyy/core/errors/exceptions.dart';

abstract class ChatRepository {
  Stream<List<ChatMessage>> watchMessages(String chatRoomId);
  Future<void> sendMessage(String chatRoomId, String content, String senderId);
  Future<String> createOrGetChatRoom({
    required String userId,
    String? designerId,
    String? marketplaceOwnerId,
    String? requestId,
  });
  Stream<List<Map<String, dynamic>>> watchChatRooms(String userId);
}

class SupabaseChatRepository implements ChatRepository {
  final SupabaseClient _supabase;

  SupabaseChatRepository(this._supabase);

  @override
  Stream<List<ChatMessage>> watchMessages(String chatRoomId) async* {
    try {
      final initialData = await _supabase
          .from('messages')
          .select()
          .eq('chat_room_id', chatRoomId)
          .order('created_at', ascending: true);
      yield (initialData as List)
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {}

    yield* Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
      final data = await _supabase
          .from('messages')
          .select()
          .eq('chat_room_id', chatRoomId)
          .order('created_at', ascending: true);
      return (data as List)
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Future<void> sendMessage(String chatRoomId, String content, String senderId) async {
    try {
      await _supabase.from('messages').insert({
        'chat_room_id': chatRoomId,
        'sender_id': senderId,
        'content': content,
      });
    } catch (e) {
      throw ServerException('Failed to send message: $e');
    }
  }

  @override
  Future<String> createOrGetChatRoom({
    required String userId,
    String? designerId,
    String? marketplaceOwnerId,
    String? requestId,
  }) async {
    try {
      if (designerId == null && marketplaceOwnerId == null) {
        throw ArgumentError('Either designerId or marketplaceOwnerId must be provided');
      }

      // Check if a chat room already exists between the same two people
      var query = _supabase.from('chat_rooms').select('id, request_id').eq('user_id', userId);
      if (designerId != null) {
        query = query.eq('designer_id', designerId);
      } else {
        query = query.eq('marketplace_owner_id', marketplaceOwnerId!);
      }

      final List<dynamic> existingList = await query;

      if (existingList.isNotEmpty) {
        final Map<String, dynamic> existing = existingList.first as Map<String, dynamic>;
        final roomId = existing['id'] as String;
        final currentRequestId = existing['request_id'] as String?;

        // If we have a new requestId and the existing room doesn't have it, update it!
        if (requestId != null && currentRequestId != requestId) {
          await _supabase
              .from('chat_rooms')
              .update({'request_id': requestId})
              .eq('id', roomId);
        }

        return roomId;
      }

      // If no room exists, create a new one!
      final insertData = <String, dynamic>{
        'user_id': userId,
      };
      if (designerId != null) insertData['designer_id'] = designerId;
      if (marketplaceOwnerId != null) insertData['marketplace_owner_id'] = marketplaceOwnerId;
      if (requestId != null) insertData['request_id'] = requestId;

      final response = await _supabase
          .from('chat_rooms')
          .insert(insertData)
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      throw ServerException('Failed to create chat room: $e');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchChatRooms(String userId) async* {
    try {
      final initialData = await _fetchChatRoomsData(userId);
      yield initialData;
    } catch (_) {}

    yield* Stream.periodic(const Duration(seconds: 3)).asyncMap((_) async {
      return await _fetchChatRoomsData(userId);
    });
  }

  Future<List<Map<String, dynamic>>> _fetchChatRoomsData(String userId) async {
    try {
      final response = await _supabase
          .from('chat_rooms')
          .select('''
            id,
            user_id,
            designer_id,
            marketplace_owner_id,
            request_id,
            messages(content, created_at, sender_id)
          ''');

      final filteredRooms = (response as List).where((room) {
        return room['user_id'] == userId ||
               room['designer_id'] == userId ||
               room['marketplace_owner_id'] == userId;
      }).toList();

      final List<Map<String, dynamic>> roomsList = [];

      for (final room in filteredRooms) {
        final String roomId = room['id'] as String;
        final String roomUserId = room['user_id'] as String;
        final String? roomDesignerId = room['designer_id'] as String?;
        final String? roomOwnerId = room['marketplace_owner_id'] as String?;
        final String? requestId = room['request_id'] as String?;

        String? otherParticipantId;
        String roleLabel = 'Client';

        if (userId == roomUserId) {
          if (roomDesignerId != null) {
            otherParticipantId = roomDesignerId;
            roleLabel = 'Designer';
          } else if (roomOwnerId != null) {
            otherParticipantId = roomOwnerId;
            roleLabel = 'Shop Owner';
          }
        } else {
          otherParticipantId = roomUserId;
          roleLabel = 'Client';
        }

        String name = 'Anonymous';
        String avatarUrl = '';
        if (otherParticipantId != null) {
          final profile = await _supabase
              .from('profiles')
              .select('full_name, avatar_url')
              .eq('id', otherParticipantId)
              .maybeSingle();
          if (profile != null) {
            name = profile['full_name'] as String? ?? 'Anonymous';
            avatarUrl = profile['avatar_url'] as String? ?? '';
          }
        }

        final messages = room['messages'] as List? ?? [];
        String lastMessage = 'No messages yet';
        DateTime lastMessageTime = DateTime.fromMillisecondsSinceEpoch(0);

        if (messages.isNotEmpty) {
          messages.sort((a, b) {
            final aTime = DateTime.parse(a['created_at'] as String);
            final bTime = DateTime.parse(b['created_at'] as String);
            return aTime.compareTo(bTime);
          });
          final latest = messages.last;
          lastMessage = latest['content'] as String? ?? '';
          lastMessageTime = DateTime.parse(latest['created_at'] as String);
        }

        roomsList.add({
          'id': roomId,
          'user_id': roomUserId,
          'designer_id': roomDesignerId,
          'marketplace_owner_id': roomOwnerId,
          'request_id': requestId,
          'other_participant_id': otherParticipantId,
          'name': name,
          'avatar_url': avatarUrl,
          'role_label': roleLabel,
          'last_message': lastMessage,
          'last_message_time': lastMessageTime,
          'unread_count': 0,
          'is_online': false,
        });
      }

      roomsList.sort((a, b) {
        final aTime = a['last_message_time'] as DateTime;
        final bTime = b['last_message_time'] as DateTime;
        return bTime.compareTo(aTime);
      });

      return roomsList;
    } catch (e) {
      debugPrint('Error fetching chat rooms: $e');
      return [];
    }
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return SupabaseChatRepository(Supabase.instance.client);
});


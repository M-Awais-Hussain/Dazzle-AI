import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ayyy/features/user/chat/data/chat_repository.dart';
import 'package:ayyy/features/user/chat/domain/chat_message.dart';

final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, chatRoomId) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.watchMessages(chatRoomId);
});

class ChatController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> sendMessage(String chatRoomId, String content, String senderId) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(chatRepositoryProvider);
      await repository.sendMessage(chatRoomId, content, senderId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<String?> createOrGetChatRoom({
    required String userId,
    String? designerId,
    String? marketplaceOwnerId,
    String? requestId,
  }) async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(chatRepositoryProvider);
      final roomId = await repository.createOrGetChatRoom(
        userId: userId,
        designerId: designerId,
        marketplaceOwnerId: marketplaceOwnerId,
        requestId: requestId,
      );
      state = const AsyncData(null);
      return roomId;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

final chatControllerProvider = NotifierProvider<ChatController, AsyncValue<void>>(() {
  return ChatController();
});

import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    @JsonKey(name: 'sender_id') required String senderId,
    @JsonKey(name: 'content') required String text,
    @JsonKey(name: 'created_at') required DateTime timestamp,
    @Default(false) bool isAttachment,
    String? attachmentUrl,
    String? attachmentName,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
}

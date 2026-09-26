import 'package:konush/src/features/chat/domain/chat_models.dart';

abstract interface class ChatRepository {
  Future<List<Conversation>> conversations();
  Future<Conversation> startConversation(String listingId);
  Future<List<ChatMessage>> messages(
    String id, {
    DateTime? before,
    int limit = 30,
  });
  Future<ChatMessage> send(String id, String content);
  Future<void> markRead(String id);
  Future<void> markDelivered();
}

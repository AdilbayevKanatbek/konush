import 'package:konush/src/core/network/api_client.dart';
import 'package:konush/src/features/chat/domain/chat_models.dart';
import 'package:konush/src/features/chat/domain/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  const ChatRepositoryImpl(this._client);
  final ApiClient _client;
  @override
  Future<List<Conversation>> conversations() async => (await _client.get(
    '/conversations',
    decode: (value) => (value as List<dynamic>)
        .map((item) => Conversation.fromJson(item as Map<String, dynamic>))
        .toList(),
  )).data;
  @override
  Future<Conversation> startConversation(String listingId) async =>
      (await _client.post(
        '/conversations',
        data: {'listing_id': listingId},
        decode: (value) => Conversation.fromJson(value as Map<String, dynamic>),
      )).data;
  @override
  Future<List<ChatMessage>> messages(
    String id, {
    DateTime? before,
    int limit = 30,
  }) async => (await _client.get(
    '/conversations/$id/messages',
    queryParameters: {
      'limit': limit,
      if (before != null) 'before': before.toUtc().toIso8601String(),
    },
    decode: (value) => (value as List<dynamic>)
        .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        .toList(),
  )).data;
  @override
  Future<ChatMessage> send(String id, String content) async =>
      (await _client.post(
        '/conversations/$id/messages',
        data: {'content': content},
        decode: (value) => ChatMessage.fromJson(value as Map<String, dynamic>),
      )).data;
  @override
  Future<void> markRead(String id) async {
    await _client.post('/conversations/$id/read', decode: (_) => null);
  }

  @override
  Future<void> markDelivered() async {
    await _client.post('/conversations/delivered', decode: (_) => null);
  }
}

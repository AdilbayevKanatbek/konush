import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:konush/src/features/chat/domain/chat_models.dart';
import 'package:konush/src/features/chat/domain/chat_repository.dart';

const fixtureConversation = Conversation(
  id: 'chat-1',
  listingId: 'fixture-sale',
  buyerId: 'fixture-user',
  sellerId: 'seller-1',
  otherUserName: 'Нурбек',
  listingTitle: 'Квартира у парка',
);
ChatMessage fixtureMessage(
  String id, {
  String sender = 'seller-1',
  String content = 'Здравствуйте!',
  bool read = false,
  bool delivered = false,
  int minute = 1,
}) => ChatMessage(
  id: id,
  conversationId: 'chat-1',
  senderId: sender,
  content: content,
  createdAt: DateTime.utc(2026, 9, 15, 12, minute),
  isRead: read,
  isDelivered: delivered,
);

class TestChatRepository extends Fake implements ChatRepository {
  List<Conversation> inbox = [];
  List<ChatMessage> history = [];
  final sends = <String>[], reads = <String>[], starts = <String>[];
  final before = <DateTime?>[];
  int delivered = 0, loads = 0;
  bool fail = false, failSend = false;
  Completer<ChatMessage>? pendingSend;
  Completer<List<ChatMessage>>? pendingHistory;
  @override
  Future<List<Conversation>> conversations() async {
    loads++;
    if (fail) throw Exception('offline');
    return inbox;
  }

  @override
  Future<Conversation> startConversation(String listingId) async {
    starts.add(listingId);
    return fixtureConversation;
  }

  @override
  Future<List<ChatMessage>> messages(
    String id, {
    DateTime? before,
    int limit = 30,
  }) async {
    this.before.add(before);
    if (pendingHistory != null) return pendingHistory!.future;
    if (fail) throw Exception('offline');
    return history
        .where((m) => before == null || m.createdAt.isBefore(before))
        .take(limit)
        .toList();
  }

  @override
  Future<ChatMessage> send(String id, String content) async {
    sends.add(content);
    if (pendingSend != null) return pendingSend!.future;
    if (failSend) throw Exception('timeout');
    final message = fixtureMessage(
      'sent-${sends.length}',
      sender: 'fixture-user',
      content: content,
      minute: 50,
    );
    history = [message, ...history];
    return message;
  }

  @override
  Future<void> markRead(String id) async {
    reads.add(id);
    if (fail) throw Exception('offline');
    history = history
        .map((m) => m.senderId == 'fixture-user' ? m : m.read())
        .toList();
    inbox = inbox.map((c) => c.id == id ? c.read() : c).toList();
  }

  @override
  Future<void> markDelivered() async {
    delivered++;
  }
}

class TestChatRealtime implements ChatRealtime {
  final eventController = StreamController<ChatEvent>.broadcast();
  final connectionController = StreamController<ChatConnection>.broadcast();
  int starts = 0, stops = 0;
  @override
  Stream<ChatEvent> get events => eventController.stream;
  @override
  Stream<ChatConnection> get connections => connectionController.stream;
  @override
  Future<void> start() async {
    starts++;
    connectionController.add(ChatConnection.connected);
  }

  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() async {
    await eventController.close();
    await connectionController.close();
  }
}

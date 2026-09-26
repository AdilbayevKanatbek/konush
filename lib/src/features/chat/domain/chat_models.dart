import 'package:equatable/equatable.dart';

class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.sellerId,
    this.otherUserName = '',
    this.listingTitle = '',
    this.listingPhoto = '',
    this.lastMessage,
    this.lastMessageAt,
    this.unread = 0,
  });
  final String id,
      listingId,
      buyerId,
      sellerId,
      otherUserName,
      listingTitle,
      listingPhoto;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unread;
  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String,
    listingId: json['listing_id'] as String,
    buyerId: json['buyer_id'] as String,
    sellerId: json['seller_id'] as String,
    otherUserName: json['other_user_name'] as String? ?? '',
    listingTitle: json['listing_title'] as String? ?? '',
    listingPhoto: json['listing_photo'] as String? ?? '',
    lastMessage: json['last_message'] as String?,
    lastMessageAt: DateTime.tryParse(json['last_message_at'] as String? ?? ''),
    unread: json['unread'] as int? ?? 0,
  );
  Conversation read() => Conversation(
    id: id,
    listingId: listingId,
    buyerId: buyerId,
    sellerId: sellerId,
    otherUserName: otherUserName,
    listingTitle: listingTitle,
    listingPhoto: listingPhoto,
    lastMessage: lastMessage,
    lastMessageAt: lastMessageAt,
  );
  @override
  List<Object?> get props => [
    id,
    listingId,
    buyerId,
    sellerId,
    otherUserName,
    listingTitle,
    listingPhoto,
    lastMessage,
    lastMessageAt,
    unread,
  ];
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.type = 'text',
    this.isDelivered = false,
    this.isRead = false,
  });
  final String id, conversationId, senderId, content, type;
  final DateTime createdAt;
  final bool isDelivered, isRead;
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    conversationId: json['conversation_id'] as String,
    senderId: json['sender_id'] as String,
    content: json['content'] as String? ?? '',
    type: json['type'] as String? ?? 'text',
    createdAt: DateTime.parse(json['created_at'] as String),
    isDelivered: json['is_delivered'] as bool? ?? false,
    isRead: json['is_read'] as bool? ?? false,
  );
  ChatMessage read() => ChatMessage(
    id: id,
    conversationId: conversationId,
    senderId: senderId,
    content: content,
    createdAt: createdAt,
    type: type,
    isDelivered: true,
    isRead: true,
  );
  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderId,
    content,
    type,
    createdAt,
    isDelivered,
    isRead,
  ];
}

class ChatEvent {
  const ChatEvent(this.type, this.conversationId, [this.message]);
  final String type, conversationId;
  final ChatMessage? message;
  factory ChatEvent.fromJson(Map<String, dynamic> json) => ChatEvent(
    json['type'] as String,
    json['conversation_id'] as String,
    json['message'] is Map<String, dynamic>
        ? ChatMessage.fromJson(json['message'] as Map<String, dynamic>)
        : null,
  );
}

enum ChatConnection {
  disconnected,
  connecting,
  connected,
  retrying,
  unauthorized,
}

abstract interface class ChatRealtime {
  Stream<ChatEvent> get events;
  Stream<ChatConnection> get connections;
  Future<void> start();
  Future<void> stop();
  Future<void> dispose();
}

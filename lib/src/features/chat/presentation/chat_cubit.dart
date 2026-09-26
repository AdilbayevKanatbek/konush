import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konush/src/core/error/app_exception.dart';
import 'package:konush/src/features/chat/domain/chat_models.dart';
import 'package:konush/src/features/chat/domain/chat_repository.dart';

class ChatThread extends Equatable {
  const ChatThread({
    this.messages = const [],
    this.loading = false,
    this.sending = false,
    this.hasMore = true,
    this.loaded = false,
    this.error,
    this.sendError,
    this.draft = '',
  });
  final List<ChatMessage> messages;
  final bool loading, sending, hasMore, loaded;
  final String? error, sendError;
  final String draft;
  ChatThread copyWith({
    List<ChatMessage>? messages,
    bool? loading,
    bool? sending,
    bool? hasMore,
    bool? loaded,
    String? error,
    String? sendError,
    String? draft,
    bool clearError = false,
    bool clearSendError = false,
  }) => ChatThread(
    messages: messages ?? this.messages,
    loading: loading ?? this.loading,
    sending: sending ?? this.sending,
    hasMore: hasMore ?? this.hasMore,
    loaded: loaded ?? this.loaded,
    error: clearError ? null : error ?? this.error,
    sendError: clearSendError ? null : sendError ?? this.sendError,
    draft: draft ?? this.draft,
  );
  @override
  List<Object?> get props => [
    messages,
    loading,
    sending,
    hasMore,
    loaded,
    error,
    sendError,
    draft,
  ];
}

class ChatState extends Equatable {
  const ChatState({
    this.userId,
    this.conversations = const [],
    this.threads = const {},
    this.loading = false,
    this.loaded = false,
    this.error,
    this.connection = ChatConnection.disconnected,
  });
  final String? userId, error;
  final List<Conversation> conversations;
  final Map<String, ChatThread> threads;
  final bool loading, loaded;
  final ChatConnection connection;
  int get unread => conversations.fold(0, (sum, item) => sum + item.unread);
  ChatThread thread(String id) => threads[id] ?? const ChatThread();
  ChatState copyWith({
    List<Conversation>? conversations,
    Map<String, ChatThread>? threads,
    bool? loading,
    bool? loaded,
    String? error,
    bool clearError = false,
    ChatConnection? connection,
  }) => ChatState(
    userId: userId,
    conversations: conversations ?? this.conversations,
    threads: threads ?? this.threads,
    loading: loading ?? this.loading,
    loaded: loaded ?? this.loaded,
    error: clearError ? null : error ?? this.error,
    connection: connection ?? this.connection,
  );
  @override
  List<Object?> get props => [
    userId,
    conversations,
    threads,
    loading,
    loaded,
    error,
    connection,
  ];
}

class ChatCubit extends Cubit<ChatState> {
  ChatCubit(this._repository, this._realtime) : super(const ChatState()) {
    _events = _realtime.events.listen(_event);
    _connections = _realtime.connections.listen((connection) {
      if (isClosed || state.userId == null) return;
      emit(state.copyWith(connection: connection));
      if (connection == ChatConnection.connected && _foreground) {
        unawaited(refresh());
        unawaited(_delivered());
      }
    });
  }
  final ChatRepository _repository;
  final ChatRealtime _realtime;
  late final StreamSubscription<ChatEvent> _events;
  late final StreamSubscription<ChatConnection> _connections;
  Timer? _poll;
  bool _foreground = true;
  int _session = 0;
  String? _active;
  final _reading = <String>{};
  final _queuedRefresh = <String>{};
  final _starting = <String, Future<Conversation>>{};
  static const pageSize = 30;

  Future<void> setUser(String? id) async {
    if (id == state.userId) return;
    final session = ++_session;
    _poll?.cancel();
    _active = null;
    _reading.clear();
    _queuedRefresh.clear();
    _starting.clear();
    emit(ChatState(userId: id));
    await _realtime.stop();
    if (isClosed || session != _session || id == null || !_foreground) return;
    _start();
  }

  void _start() {
    unawaited(refresh());
    unawaited(_realtime.start());
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  Future<void> setForeground(bool value) async {
    if (_foreground == value || isClosed) return;
    _foreground = value;
    if (!value) {
      _poll?.cancel();
      _poll = null;
      await _realtime.stop();
    } else if (state.userId != null) {
      _start();
    }
  }

  Future<void> reconnect() async {
    if (state.userId == null || !_foreground) return;
    await _realtime.stop();
    if (!isClosed && _foreground && state.userId != null) {
      await _realtime.start();
      await refresh();
    }
  }

  Future<void> refresh() async {
    if (isClosed || state.userId == null || !_foreground) return;
    await loadConversations();
    final active = _active;
    if (active != null && _foreground && !isClosed) await loadMessages(active);
  }

  Future<void> loadConversations() async {
    if (isClosed || state.userId == null || state.loading) return;
    final session = _session;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final conversations = await _repository.conversations();
      if (isClosed || session != _session) return;
      emit(
        state.copyWith(
          conversations: conversations,
          loading: false,
          loaded: true,
        ),
      );
    } catch (error) {
      if (!isClosed && session == _session) {
        emit(state.copyWith(loading: false, error: _error(error)));
      }
    }
  }

  Future<Conversation> startConversation(String listingId) {
    if (state.userId == null) {
      throw const AppException(
        'Необходимо войти в аккаунт',
        code: 'UNAUTHORIZED',
      );
    }
    return _starting.putIfAbsent(listingId, () {
      final session = _session;
      return _repository
          .startConversation(listingId)
          .then((conversation) {
            if (!isClosed && session == _session) {
              if (!state.conversations.any(
                (item) => item.id == conversation.id,
              )) {
                emit(
                  state.copyWith(
                    conversations: [conversation, ...state.conversations],
                  ),
                );
              }
              unawaited(loadConversations());
            }
            return conversation;
          })
          .whenComplete(() {
            if (session == _session) _starting.remove(listingId);
          });
    });
  }

  void activate(String? id) {
    if (_active == id || isClosed) return;
    _active = id;
    if (id != null && state.userId != null) unawaited(loadMessages(id));
  }

  void deactivate(String id) {
    if (_active == id) _active = null;
  }

  void draft(String id, String value) => _thread(
    id,
    state.thread(id).copyWith(draft: value, clearSendError: true),
  );
  void _thread(String id, ChatThread thread) {
    if (!isClosed) {
      emit(state.copyWith(threads: {...state.threads, id: thread}));
    }
  }

  List<ChatMessage> _merge(List<ChatMessage> old, List<ChatMessage> incoming) {
    final byId = {for (final message in old) message.id: message};
    for (final message in incoming) {
      byId[message.id] = message;
    }
    return byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> loadMessages(String id, {bool older = false}) async {
    if (isClosed || state.userId == null) return;
    final current = state.thread(id);
    if (current.loading) {
      if (!older) _queuedRefresh.add(id);
      return;
    }
    if (older && !current.hasMore) return;
    final session = _session;
    _thread(id, current.copyWith(loading: true, clearError: true));
    try {
      final messages = await _repository.messages(
        id,
        before: older && current.messages.isNotEmpty
            ? current.messages.last.createdAt
            : null,
        limit: pageSize,
      );
      if (isClosed || session != _session) return;
      final latest = state.thread(id);
      _thread(
        id,
        latest.copyWith(
          messages: _merge(latest.messages, messages),
          loading: false,
          loaded: true,
          hasMore: older || !current.loaded
              ? messages.length == pageSize
              : current.hasMore,
        ),
      );
      if (_foreground && _active == id) await _markRead(id);
    } catch (error) {
      if (!isClosed && session == _session) {
        _thread(
          id,
          state.thread(id).copyWith(loading: false, error: _error(error)),
        );
      }
    } finally {
      if (!isClosed &&
          session == _session &&
          _queuedRefresh.remove(id) &&
          _foreground) {
        unawaited(loadMessages(id));
      }
    }
  }

  Future<void> send(String id) async {
    final current = state.thread(id);
    if (isClosed || state.userId == null || current.sending) return;
    final content = current.draft.trim();
    if (content.isEmpty) return;
    if (content.runes.length > 4000) {
      _thread(
        id,
        current.copyWith(
          sendError: 'Сообщение должно быть не длиннее 4000 символов',
        ),
      );
      return;
    }
    final session = _session;
    _thread(id, current.copyWith(sending: true, clearSendError: true));
    try {
      final message = await _repository.send(id, content);
      if (isClosed || session != _session) return;
      final latest = state.thread(id);
      _thread(
        id,
        latest.copyWith(
          messages: _merge(latest.messages, [message]),
          sending: false,
          draft: latest.draft == current.draft ? '' : latest.draft,
          loaded: true,
        ),
      );
      unawaited(loadConversations());
    } catch (error) {
      if (!isClosed && session == _session) {
        _thread(
          id,
          state
              .thread(id)
              .copyWith(
                sending: false,
                sendError: error is AppException && error.statusCode != null
                    ? _error(error)
                    : 'Не удалось подтвердить отправку. Обновите переписку перед повтором.',
              ),
        );
      }
    }
  }

  Future<void> _markRead(String id) async {
    final hasUnread =
        state
            .thread(id)
            .messages
            .any((m) => m.senderId != state.userId && !m.isRead) ||
        state.conversations.any((c) => c.id == id && c.unread > 0);
    if (!hasUnread || !_foreground || _active != id || !_reading.add(id)) {
      return;
    }
    final session = _session;
    final seenIds = state.thread(id).messages.map((m) => m.id).toSet();
    try {
      await _repository.markRead(id);
      if (!isClosed && session == _session) {
        _thread(
          id,
          state
              .thread(id)
              .copyWith(
                messages: state
                    .thread(id)
                    .messages
                    .map(
                      (m) =>
                          m.senderId == state.userId || !seenIds.contains(m.id)
                          ? m
                          : m.read(),
                    )
                    .toList(),
              ),
        );
        emit(
          state.copyWith(
            conversations: state.conversations
                .map((item) => item.id == id ? item.read() : item)
                .toList(),
          ),
        );
      }
    } catch (_) {
      // Keep unread state. A later visible refresh retries the server receipt.
    } finally {
      if (session == _session) _reading.remove(id);
    }
  }

  Future<void> _delivered() async {
    if (!_foreground || state.userId == null) return;
    try {
      await _repository.markDelivered();
    } catch (_) {}
  }

  void _event(ChatEvent event) {
    if (isClosed || !_foreground || state.userId == null) return;
    if (event.type == 'message' && event.message != null) {
      final id = event.conversationId;
      if (state.threads.containsKey(id) || _active == id) {
        final thread = state.thread(id);
        _thread(
          id,
          thread.copyWith(messages: _merge(thread.messages, [event.message!])),
        );
      }
      unawaited(_delivered());
      if (_active == id) unawaited(_markRead(id));
    } else if (state.threads.containsKey(event.conversationId)) {
      // Re-read actual per-message flags. Receipt events have no timestamp or
      // message IDs, so marking every outgoing message locally can overstate read status.
      unawaited(loadMessages(event.conversationId));
    }
    unawaited(loadConversations());
  }

  String _error(Object error) {
    if (error is AppException) {
      return switch (error.code) {
        'UNAUTHORIZED' => 'Необходимо войти в аккаунт',
        'SELF_CHAT' => 'Нельзя написать самому себе',
        'NOT_FOUND' => 'Диалог или объявление не найдено',
        'FORBIDDEN' => 'Нет доступа к диалогу',
        _ => error.userMessage,
      };
    }
    return 'Не удалось загрузить сообщения. Проверьте подключение и повторите.';
  }

  @override
  Future<void> close() async {
    _session++;
    _poll?.cancel();
    await _events.cancel();
    await _connections.cancel();
    await _realtime.dispose();
    return super.close();
  }
}

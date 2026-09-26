import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:konush/src/features/chat/domain/chat_models.dart';

typedef ChatTokenProvider = Future<String?> Function(bool refresh);
typedef ChatChannelFactory = WebSocketChannel Function(Uri uri);

/// REST sends messages; the socket receives only server events.
/// The first frame authenticates. The server does not send an auth ACK.
class ChatSocket implements ChatRealtime {
  ChatSocket({
    required this.url,
    required this.tokenProvider,
    ChatChannelFactory? channelFactory,
    this.retryBase = const Duration(seconds: 1),
  }) : channelFactory = channelFactory ?? WebSocketChannel.connect;
  final Uri url;
  final ChatTokenProvider tokenProvider;
  final ChatChannelFactory channelFactory;
  final Duration retryBase;
  final _events = StreamController<ChatEvent>.broadcast();
  final _connections = StreamController<ChatConnection>.broadcast();
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _retry;
  bool _running = false, _authRetried = false, _disposed = false;
  int _generation = 0, _attempt = 0;
  @override
  Stream<ChatEvent> get events => _events.stream;
  @override
  Stream<ChatConnection> get connections => _connections.stream;
  void _state(ChatConnection value) {
    if (!_disposed) _connections.add(value);
  }

  @override
  Future<void> start() async {
    if (_disposed || _running) return;
    _running = true;
    _authRetried = false;
    _attempt = 0;
    await _connect(++_generation);
  }

  Future<void> _connect(int generation, {bool refresh = false}) async {
    if (!_running || generation != _generation) return;
    _state(ChatConnection.connecting);
    try {
      final token = await tokenProvider(refresh);
      if (!_running || generation != _generation) return;
      if (token == null || token.isEmpty) {
        _running = false;
        _state(ChatConnection.unauthorized);
        return;
      }
      final channel = channelFactory(url);
      _channel = channel;
      final openedAt = DateTime.now();
      var ended = false;
      void finish() {
        if (ended || !_running || generation != _generation) return;
        ended = true;
        _channel = null;
        if (DateTime.now().difference(openedAt) >=
            const Duration(seconds: 10)) {
          _attempt = 0;
          _authRetried = false;
        }
        if (channel.closeCode == 1008) {
          if (_authRetried) {
            _running = false;
            _state(ChatConnection.unauthorized);
            return;
          }
          _authRetried = true;
          _schedule(generation, refresh: true);
        } else {
          _schedule(generation);
        }
      }

      _subscription = channel.stream.listen(
        (raw) {
          if (!_running || generation != _generation) return;
          try {
            final value = jsonDecode(raw as String);
            if (value is! Map<String, dynamic>) return;
            final event = ChatEvent.fromJson(value);
            if (const ['message', 'read', 'delivered'].contains(event.type)) {
              _events.add(event);
            }
          } catch (_) {
            /* Unknown or malformed events cannot break the connection. */
          }
        },
        onError: (Object error) {
          finish();
        },
        onDone: finish,
      );
      await channel.ready.timeout(const Duration(seconds: 10));
      if (!_running || generation != _generation || ended) {
        await channel.sink.close();
        return;
      }
      channel.sink.add(jsonEncode({'type': 'auth', 'token': token}));
      _state(ChatConnection.connected);
    } catch (_) {
      if (_running && generation == _generation) {
        await _subscription?.cancel();
        _subscription = null;
        unawaited(_channel?.sink.close());
        _channel = null;
        _schedule(generation);
      }
    }
  }

  void _schedule(int generation, {bool refresh = false}) {
    if (!_running || generation != _generation) return;
    _retry?.cancel();
    _state(ChatConnection.retrying);
    final multiplier = 1 << _attempt.clamp(0, 5);
    _attempt++;
    final millis = (retryBase.inMilliseconds * multiplier).clamp(1, 30000);
    _retry = Timer(
      Duration(milliseconds: millis),
      () => _connect(generation, refresh: refresh),
    );
  }

  @override
  Future<void> stop() async {
    _running = false;
    _generation++;
    _retry?.cancel();
    _retry = null;
    await _subscription?.cancel();
    _subscription = null;
    final channel = _channel;
    _channel = null;
    unawaited(channel?.sink.close());
    _state(ChatConnection.disconnected);
  }

  @override
  Future<void> dispose() async {
    await stop();
    _disposed = true;
    await _events.close();
    await _connections.close();
  }
}

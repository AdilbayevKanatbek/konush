import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:konush/src/core/network/api_client.dart';
import 'package:konush/src/features/chat/data/chat_repository_impl.dart';
import 'package:konush/src/features/chat/data/chat_socket.dart';
import 'package:konush/src/features/chat/domain/chat_models.dart';
import 'package:konush/src/features/chat/presentation/chat_cubit.dart';
import '../../support/chat_fakes.dart';

Future<void> flush() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class Channel extends Fake implements WebSocketChannel {
  final input = StreamController<dynamic>();
  final output = Sink();
  int? code;
  @override
  Stream<dynamic> get stream => input.stream;
  @override
  WebSocketSink get sink => output;
  @override
  Future<void> get ready => Future.value();
  @override
  int? get closeCode => code;
  Future<void> end([int? value]) async {
    code = value;
    await input.close();
  }
}

class Sink extends Fake implements WebSocketSink {
  final frames = <dynamic>[];
  bool closed = false;
  @override
  void add(dynamic value) => frames.add(value);
  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    closed = true;
  }
}

void main() {
  group('chat session and messages', () {
    late TestChatRepository repo;
    late TestChatRealtime wire;
    late ChatCubit cubit;
    setUp(() async {
      repo = TestChatRepository()..inbox = [fixtureConversation];
      wire = TestChatRealtime();
      cubit = ChatCubit(repo, wire);
      await cubit.setUser('fixture-user');
      await flush();
    });
    tearDown(() async {
      await cubit.close();
    });
    test('loads conversations and acknowledges delivery on connection', () {
      expect(cubit.state.conversations, [fixtureConversation]);
      expect(repo.delivered, 1);
    });
    test('failure keeps cached conversation and retry recovers', () async {
      repo.fail = true;
      await cubit.loadConversations();
      expect(cubit.state.error, isNotNull);
      expect(cubit.state.conversations, isNotEmpty);
      repo.fail = false;
      await cubit.loadConversations();
      expect(cubit.state.error, isNull);
    });
    test(
      'send uses server response, guards double tap and preserves edits made while sending',
      () async {
        repo.pendingSend = Completer<ChatMessage>();
        cubit.draft('chat-1', '  Первый  ');
        final sending = cubit.send('chat-1');
        await cubit.send('chat-1');
        expect(repo.sends, ['Первый']);
        expect(cubit.state.thread('chat-1').messages, isEmpty);
        cubit.draft('chat-1', 'Следующий');
        repo.pendingSend!.complete(
          fixtureMessage('sent', sender: 'fixture-user', content: 'Первый'),
        );
        await sending;
        expect(cubit.state.thread('chat-1').draft, 'Следующий');
        expect(
          cubit.state.thread('chat-1').messages.single.isDelivered,
          isFalse,
        );
      },
    );
    test('failed sends keep draft and never auto-retry on reconnect', () async {
      repo.failSend = true;
      cubit.draft('chat-1', 'Вопрос');
      await cubit.send('chat-1');
      expect(cubit.state.thread('chat-1').sendError, isNotNull);
      expect(cubit.state.thread('chat-1').draft, 'Вопрос');
      await cubit.reconnect();
      await flush();
      expect(repo.sends, ['Вопрос']);
    });
    test('empty and over 4000 Unicode characters are not sent', () async {
      cubit.draft('chat-1', '   ');
      await cubit.send('chat-1');
      cubit.draft('chat-1', '😀' * 4001);
      await cubit.send('chat-1');
      expect(repo.sends, isEmpty);
      expect(cubit.state.thread('chat-1').sendError, isNotNull);
    });
    test(
      'visible incoming messages read once; receipt event cannot cause feedback loop',
      () async {
        repo.history = [fixtureMessage('incoming')];
        cubit.activate('chat-1');
        await flush();
        expect(repo.reads, ['chat-1']);
        for (var i = 0; i < 3; i++) {
          wire.eventController.add(const ChatEvent('read', 'chat-1'));
          await flush();
        }
        expect(repo.reads, ['chat-1']);
        expect(cubit.state.thread('chat-1').messages.single.isRead, isTrue);
      },
    );
    test(
      'inactive conversation and background do not send read receipts',
      () async {
        repo.history = [fixtureMessage('a')];
        await cubit.loadMessages('chat-1');
        expect(repo.reads, isEmpty);
        await cubit.setForeground(false);
        wire.eventController.add(
          ChatEvent('message', 'chat-1', fixtureMessage('b')),
        );
        await flush();
        expect(repo.reads, isEmpty);
        expect(wire.stops, greaterThanOrEqualTo(2));
        cubit.activate('chat-1');
        await flush();
        expect(repo.reads, isEmpty);
        await cubit.setForeground(true);
        await flush();
        expect(repo.reads, ['chat-1']);
        expect(wire.starts, 2);
      },
    );
    test(
      'delivery event refreshes actual flags rather than marking all outgoing read',
      () async {
        repo.history = [
          fixtureMessage('a', sender: 'fixture-user', delivered: true),
          fixtureMessage('b', sender: 'fixture-user'),
        ];
        await cubit.loadMessages('chat-1');
        wire.eventController.add(const ChatEvent('delivered', 'chat-1'));
        await flush();
        expect(cubit.state.thread('chat-1').messages.first.isDelivered, isTrue);
        expect(cubit.state.thread('chat-1').messages.last.isDelivered, isFalse);
        expect(
          cubit.state.thread('chat-1').messages.every((m) => !m.isRead),
          isTrue,
        );
      },
    );
    test(
      'pagination uses oldest timestamp, merges duplicate WS event once',
      () async {
        repo.history = List.generate(
          35,
          (i) => fixtureMessage('m$i', minute: 50 - i),
        );
        await cubit.loadMessages('chat-1');
        expect(cubit.state.thread('chat-1').hasMore, isTrue);
        await cubit.loadMessages('chat-1', older: true);
        expect(repo.before.last, repo.history[29].createdAt);
        expect(cubit.state.thread('chat-1').messages.length, 35);
        expect(cubit.state.thread('chat-1').hasMore, isFalse);
        wire.eventController.add(
          ChatEvent('message', 'chat-1', repo.history.first),
        );
        await flush();
        expect(cubit.state.thread('chat-1').messages.length, 35);
      },
    );
    test(
      'late history and send results cannot leak into another account',
      () async {
        repo.pendingHistory = Completer<List<ChatMessage>>();
        final history = cubit.loadMessages('chat-1');
        repo.pendingSend = Completer<ChatMessage>();
        cubit.draft('chat-1', 'secret');
        final send = cubit.send('chat-1');
        await cubit.setUser('other-account');
        repo.pendingHistory!.complete([fixtureMessage('old')]);
        repo.pendingSend!.complete(fixtureMessage('old-send'));
        await Future.wait([history, send]);
        expect(cubit.state.userId, 'other-account');
        expect(cubit.state.threads, isEmpty);
        await cubit.setUser(null);
        expect(cubit.state.conversations, isEmpty);
      },
    );
    test('quick start calls share one request', () async {
      final one = cubit.startConversation('fixture-sale');
      final two = cubit.startConversation('fixture-sale');
      await Future.wait([one, two]);
      expect(repo.starts, ['fixture-sale']);
    });
  });

  group('socket protocol and lifecycle', () {
    test(
      'first frame authenticates and only valid events are emitted',
      () async {
        final channel = Channel();
        final events = <ChatEvent>[];
        final socket = ChatSocket(
          url: Uri.parse('ws://fixture/ws'),
          tokenProvider: (_) async => 'fixture-token',
          channelFactory: (_) => channel,
        );
        final sub = socket.events.listen(events.add);
        await socket.start();
        expect(jsonDecode(channel.output.frames.single as String), {
          'type': 'auth',
          'token': 'fixture-token',
        });
        channel.input.add('bad json');
        channel.input.add('[]');
        channel.input.add('{"type":"read","conversation_id":"c"}');
        await flush();
        expect(events.single.conversationId, 'c');
        await socket.stop();
        expect(channel.output.closed, isTrue);
        await sub.cancel();
        await socket.dispose();
        await channel.end();
      },
    );
    test(
      '1008 refreshes credentials once then stops; explicit retry works',
      () async {
        final channels = <Channel>[];
        final refreshes = <bool>[];
        final states = <ChatConnection>[];
        final socket = ChatSocket(
          url: Uri.parse('ws://fixture/ws'),
          retryBase: const Duration(milliseconds: 1),
          tokenProvider: (refresh) async {
            refreshes.add(refresh);
            return 'token';
          },
          channelFactory: (_) {
            final ch = Channel();
            channels.add(ch);
            return ch;
          },
        );
        final sub = socket.connections.listen(states.add);
        await socket.start();
        await channels.first.end(1008);
        await Future<void>.delayed(const Duration(milliseconds: 15));
        await flush();
        expect(refreshes, [false, true]);
        await channels.last.end(1008);
        await flush();
        expect(states.last, ChatConnection.unauthorized);
        await Future<void>.delayed(const Duration(milliseconds: 15));
        expect(channels.length, 2);
        await socket.start();
        expect(channels.length, 3);
        await socket.dispose();
        await sub.cancel();
        await channels.last.end();
      },
    );
    test(
      'stop cancels scheduled reconnect and discards a late token lookup',
      () async {
        final token = Completer<String?>();
        var calls = 0;
        final socket = ChatSocket(
          url: Uri.parse('ws://fixture/ws'),
          tokenProvider: (_) => token.future,
          channelFactory: (_) {
            calls++;
            return Channel();
          },
        );
        final pending = socket.start();
        await socket.stop();
        token.complete('old');
        await pending;
        expect(calls, 0);
        await socket.dispose();
        final channel = Channel();
        var connects = 0;
        final retry = ChatSocket(
          url: Uri.parse('ws://fixture/ws'),
          retryBase: const Duration(milliseconds: 10),
          tokenProvider: (_) async => 'x',
          channelFactory: (_) {
            connects++;
            return channel;
          },
        );
        await retry.start();
        await channel.end();
        await retry.stop();
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(connects, 1);
        await retry.dispose();
      },
    );
  });
  test(
    'REST contract: endpoints, payloads, envelope decoding and keyset pagination',
    () async {
      final calls = <RequestOptions>[];
      final message = {
        'id': 'm',
        'conversation_id': 'c',
        'sender_id': 'u',
        'content': 'Привет',
        'created_at': '2026-09-15T12:01:00Z',
        'is_delivered': true,
        'is_read': false,
      };
      final conversation = {
        'id': 'c',
        'listing_id': 'l',
        'buyer_id': 'u',
        'seller_id': 's',
      };
      final dio = Dio(BaseOptions(baseUrl: 'http://fixture/api/v1'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            calls.add(request);
            dynamic data = {'message': 'OK'};
            if (request.path.endsWith('/messages')) {
              data = request.method == 'GET' ? [message] : message;
            } else if (request.path == '/conversations') {
              data = request.method == 'GET' ? [conversation] : conversation;
            }
            handler.resolve(
              Response(
                requestOptions: request,
                statusCode: 200,
                data: {'success': true, 'data': data},
              ),
            );
          },
        ),
      );
      final repo = ChatRepositoryImpl(ApiClient(dio));
      expect((await repo.conversations()).single.id, 'c');
      expect((await repo.startConversation('l')).id, 'c');
      expect(
        (await repo.messages(
          'c',
          before: DateTime.utc(2026, 9, 14),
          limit: 30,
        )).single.isDelivered,
        isTrue,
      );
      expect((await repo.send('c', 'Привет')).isRead, isFalse);
      await repo.markRead('c');
      await repo.markDelivered();
      expect(calls.map((r) => r.path).toList(), [
        '/conversations',
        '/conversations',
        '/conversations/c/messages',
        '/conversations/c/messages',
        '/conversations/c/read',
        '/conversations/delivered',
      ]);
      expect(calls[1].data, {'listing_id': 'l'});
      expect(calls[2].queryParameters, {
        'limit': 30,
        'before': '2026-09-14T00:00:00.000Z',
      });
      expect(calls[3].data, {'content': 'Привет'});
    },
  );
}

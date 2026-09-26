import 'package:konush/l10n/source_messages.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:konush/src/core/ui/konush_ui.dart';
import 'package:konush/src/core/di/injection.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:konush/src/features/chat/domain/chat_models.dart';
import 'package:konush/src/features/chat/presentation/chat_cubit.dart';
import 'package:konush/src/features/listings/domain/listing.dart';
import 'package:konush/src/features/listings/domain/listings_repository.dart';
import 'package:konush/src/features/listings/presentation/pages/listings_page.dart'
    show ListingImage;

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: KonushAppBar(
      title: context.tr("Сообщения"),
      actions: [
        IconButton(
          tooltip: context.tr("Помощь Konush"),
          onPressed: () => openPage(context, '/support'),
          icon: const Icon(Icons.help_outline_rounded),
        ),
      ],
    ),
    body: ContentWidth(
      child: BlocBuilder<ChatCubit, ChatState>(
        builder: (context, state) {
          if (state.userId == null) return const ChatSignIn();
          if (state.loading && !state.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: context.read<ChatCubit>().refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const ChatConnectionNotice(),
                if (state.error != null)
                  ChatError(
                    state.error!,
                    onRetry: context.read<ChatCubit>().loadConversations,
                  ),
                if (state.conversations.isEmpty)
                  AppEmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: context.tr("Пока нет сообщений"),
                    message: context.tr(
                      "Откройте объявление и нажмите «Написать», чтобы связаться с продавцом.",
                    ),
                  ),
                for (final item in state.conversations)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => openPage(
                          context,
                          '/messages/${item.id}',
                          extra: item,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: ListingImage(
                                    url: item.listingPhoto.isEmpty
                                        ? null
                                        : item.listingPhoto,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.otherUserName.isEmpty
                                          ? context.tr("Собеседник")
                                          : item.otherUserName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (item.listingTitle.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Text(
                                          item.listingTitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: teal,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.lastMessage ??
                                          context.tr("Начните переписку"),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: item.unread > 0 ? ink : muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (item.unread > 0)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Badge(
                                    label: Text(item.unread.toString()),
                                    backgroundColor: teal,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class ChatSignIn extends StatelessWidget {
  const ChatSignIn({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    if (auth.status == AuthStatus.unknown ||
        auth.status == AuthStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      child: AppEmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: context.tr("Войдите, чтобы переписываться"),
        message: context.tr("Все ваши диалоги будут доступны в аккаунте."),
        action: FilledButton(
          onPressed: () => openPage(context, '/login'),
          child: Text(context.tr("Войти в аккаунт")),
        ),
      ),
    );
  }
}

class ChatConnectionNotice extends StatelessWidget {
  const ChatConnectionNotice({super.key});
  @override
  Widget build(BuildContext context) => BlocBuilder<ChatCubit, ChatState>(
    buildWhen: (a, b) => a.connection != b.connection,
    builder: (context, state) {
      if (state.connection != ChatConnection.retrying &&
          state.connection != ChatConnection.unauthorized) {
        return const SizedBox.shrink();
      }
      final unauthorized = state.connection == ChatConnection.unauthorized;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ChatError(
          unauthorized
              ? context.tr("Войдите заново, чтобы получать сообщения")
              : context.tr("Соединение прервано. Переподключаемся…"),
          onRetry: unauthorized
              ? () => openPage(context, '/login')
              : context.read<ChatCubit>().reconnect,
        ),
      );
    },
  );
}

class ChatError extends StatelessWidget {
  const ChatError(this.message, {super.key, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      children: [
        Notice(context.errorText(message)),
        TextButton(onPressed: onRetry, child: Text(context.tr("Повторить"))),
      ],
    ),
  );
}

class ConversationPage extends StatefulWidget {
  const ConversationPage({super.key, required this.id, this.initial});
  final String id;
  final Conversation? initial;
  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final _text = TextEditingController();
  bool _initialized = false;
  ChatCubit? _chat;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chat = context.read<ChatCubit>();
    if (!_initialized) {
      _text.text = _chat!.state.thread(widget.id).draft;
      _initialized = true;
    }
    ModalRoute.isCurrentOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ModalRoute.isCurrentOf(context) ?? false) {
        _chat!.activate(widget.id);
      } else {
        _chat!.deactivate(widget.id);
      }
    });
  }

  @override
  void dispose() {
    _chat?.deactivate(widget.id);
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<ChatCubit, ChatState>(
    listener: (context, state) {
      final draft = state.thread(widget.id).draft;
      if (draft != _text.text) {
        _text.value = TextEditingValue(
          text: draft,
          selection: TextSelection.collapsed(offset: draft.length),
        );
      }
      if (state.userId != null && (ModalRoute.isCurrentOf(context) ?? false)) {
        _chat!.activate(widget.id);
      }
    },
    builder: (context, state) {
      final thread = state.thread(widget.id);
      final conversation =
          state.conversations
              .where((item) => item.id == widget.id)
              .firstOrNull ??
          widget.initial;
      return Scaffold(
        backgroundColor: canvas,
        appBar: KonushAppBar(
          title: conversation?.otherUserName.isNotEmpty == true
              ? conversation!.otherUserName
              : context.tr("Переписка"),
          back: true,
          fallback: '/messages',
          actions: [
            IconButton(
              tooltip: context.tr("Обновить"),
              onPressed: () => _chat!.loadMessages(widget.id),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: state.userId == null
            ? const ChatSignIn()
            : ContentWidth(
                child: Column(
                  children: [
                    if (conversation?.listingTitle.isNotEmpty == true)
                      Material(
                        color: Colors.white,
                        child: InkWell(
                          onTap: () => openPage(
                            context,
                            '/listings/${conversation.listingId}',
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.home_outlined,
                                  color: teal,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    conversation!.listingTitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: _ChatHistory(
                        id: widget.id,
                        thread: thread,
                        userId: state.userId,
                      ),
                    ),
                    ColoredBox(
                      color: Colors.white,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _text,
                                  minLines: 1,
                                  maxLines: 4,
                                  keyboardType: TextInputType.multiline,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  onChanged: (value) =>
                                      _chat!.draft(widget.id, value),
                                  decoration: InputDecoration(
                                    hintText: context.tr("Сообщение"),
                                    contentPadding: EdgeInsets.all(13),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              TextFieldTapRegion(
                                child: IconButton.filled(
                                  tooltip: context.tr("Отправить"),
                                  onPressed:
                                      thread.sending ||
                                          thread.draft.trim().isEmpty
                                      ? null
                                      : () => _chat!.send(widget.id),
                                  icon: thread.sending
                                      ? const SizedBox.square(
                                          dimension: 19,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.send_rounded),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      );
    },
  );
}

class _ChatHistory extends StatelessWidget {
  const _ChatHistory({
    required this.id,
    required this.thread,
    required this.userId,
  });
  final String id;
  final ChatThread thread;
  final String? userId;
  @override
  Widget build(BuildContext context) => ListView.builder(
    key: PageStorageKey('messages-$id'),
    reverse: thread.messages.isNotEmpty,
    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
    itemCount: thread.messages.length + 2,
    itemBuilder: (context, index) {
      if (index == 0) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ChatConnectionNotice(),
            if (thread.sendError != null || thread.error != null)
              ChatError(
                thread.sendError ?? thread.error!,
                onRetry: () => context.read<ChatCubit>().loadMessages(id),
              ),
          ],
        );
      }
      if (index <= thread.messages.length) {
        final message = thread.messages[index - 1];
        return _MessageBubble(
          message: message,
          own: message.senderId == userId,
        );
      }
      if (thread.loading) {
        return const Padding(
          padding: EdgeInsets.all(30),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (thread.messages.isEmpty) {
        return AppEmptyState(
          icon: Icons.waving_hand_outlined,
          title: context.tr('Начните разговор'),
          message: context.tr('Уточните детали объявления у продавца.'),
        );
      }
      if (!thread.hasMore) return const SizedBox.shrink();
      return TextButton(
        onPressed: () =>
            context.read<ChatCubit>().loadMessages(id, older: true),
        child: Text(context.tr('Ранее')),
      );
    },
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.own});
  final ChatMessage message;
  final bool own;
  @override
  Widget build(BuildContext context) {
    final receipt = message.isRead
        ? context.tr("Прочитано")
        : message.isDelivered
        ? context.tr("Доставлено")
        : context.tr("Отправлено");
    return Align(
      alignment: own ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .82,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: own ? tint : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(
              message.type == 'image'
                  ? context.tr("Сообщение с изображением")
                  : message.content,
              style: const TextStyle(color: ink, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 5,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  DateFormat(
                    'dd.MM · HH:mm',
                  ).format(message.createdAt.toLocal()),
                  style: const TextStyle(color: muted, fontSize: 10),
                ),
                if (own)
                  Semantics(
                    label: receipt,
                    child: Tooltip(
                      message: receipt,
                      child: Icon(
                        message.isDelivered || message.isRead
                            ? Icons.done_all_rounded
                            : Icons.done_rounded,
                        size: 16,
                        color: message.isRead ? teal : muted,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ListingChatButton extends StatefulWidget {
  const ListingChatButton({super.key, required this.listing});
  final Listing listing;
  @override
  State<ListingChatButton> createState() => _ListingChatButtonState();
}

class _ListingChatButtonState extends State<ListingChatButton> {
  bool _opening = false;
  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      if (context.read<AuthCubit>().state.user == null) {
        await openPage<bool>(context, '/login');
        if (!mounted || context.read<AuthCubit>().state.user == null) return;
      }
      final chat = context.read<ChatCubit>();
      final user = context.read<AuthCubit>().state.user!;
      await chat.setUser(user.id);
      final conversation = await chat.startConversation(widget.listing.id);
      if (!mounted || context.read<AuthCubit>().state.user?.id != user.id) {
        return;
      }
      unawaited(
        sl<ListingsRepository>()
            .recordContact(widget.listing.id, type: 'message')
            .catchError((_) {}),
      );
      await openPage(
        context,
        '/messages/${conversation.id}',
        extra: conversation,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr("Не удалось открыть диалог. Повторите попытку."),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final own =
        context.watch<AuthCubit>().state.user?.id == widget.listing.userId;
    return OutlinedButton.icon(
      onPressed: _opening || own || widget.listing.id.startsWith('new-build-')
          ? null
          : _open,
      icon: _opening
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chat_bubble_outline_rounded, size: 18),
      label: Text(own ? context.tr("Ваше объявление") : context.tr("Написать")),
    );
  }
}

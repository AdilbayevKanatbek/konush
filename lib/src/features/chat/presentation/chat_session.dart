import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:konush/src/features/chat/presentation/chat_cubit.dart';

class ChatSession extends StatefulWidget {
  const ChatSession({super.key, required this.child});
  final Widget child;
  @override
  State<ChatSession> createState() => _ChatSessionState();
}

class _ChatSessionState extends State<ChatSession> with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _subscription;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final auth = context.read<AuthCubit>(), chat = context.read<ChatCubit>();
    unawaited(chat.setUser(auth.state.user?.id));
    _subscription = auth.stream.listen((state) => chat.setUser(state.user?.id));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(
      context.read<ChatCubit>().setForeground(
        state == AppLifecycleState.resumed,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

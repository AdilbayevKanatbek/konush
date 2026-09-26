import 'package:konush/l10n/source_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:konush/src/core/di/injection.dart';
import 'package:flutter/services.dart';
import 'package:konush/src/core/ui/kyrgyz_phone_formatter.dart';
import 'package:konush/src/features/auth/domain/auth_params.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_flow_cubit.dart';
import 'package:konush/src/features/listings/presentation/pages/listings_page.dart';

bool _validPhone(String value) =>
    RegExp(r'^\+996\d{9}$').hasMatch(value.replaceAll(RegExp(r'\s'), ''));

String? _phoneError(BuildContext context, String? value) =>
    _validPhone(value ?? '')
    ? null
    : context.tr('Введите номер в формате +996 XXX XXX XXX');

enum CodePurpose { verifyPhone, resetPassword }

class CodePage extends StatefulWidget {
  const CodePage({super.key, required this.phone, required this.purpose});
  final String phone;
  final CodePurpose purpose;
  @override
  State<CodePage> createState() => _CodePageState();
}

class _CodePageState extends State<CodePage> {
  final _code = TextEditingController();
  bool _sent = false;
  bool _initialSendScheduled = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _send(BuildContext context) async {
    if (_sent) return;
    setState(() => _sent = true);
    final cubit = context.read<AuthFlowCubit>();
    final ok = widget.purpose == CodePurpose.verifyPhone
        ? await cubit.sendVerificationCode(widget.phone)
        : await cubit.requestPasswordReset(widget.phone);
    if (mounted && !ok) setState(() => _sent = false);
  }

  Future<void> _verify(BuildContext context) async {
    final value = _code.text.trim();
    if (value.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr("Введите шестизначный код"))),
      );
      return;
    }
    final cubit = context.read<AuthFlowCubit>();
    if (widget.purpose == CodePurpose.verifyPhone) {
      final ok = await cubit.verifyPhone(widget.phone, value);
      if (!context.mounted || !ok) return;
      await context.read<AuthCubit>().restoreSession();
      if (context.mounted) context.go('/profile');
    } else {
      final ok = await cubit.verifyResetCode(widget.phone, value);
      if (!context.mounted || !ok) return;
      final token = cubit.state.resetToken!;
      openPage(
        context,
        '/new-password?phone=${Uri.encodeQueryComponent(widget.phone)}&token=${Uri.encodeQueryComponent(token)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) => _FlowProvider(
    child: Builder(
      builder: (context) {
        if (!_initialSendScheduled) {
          _initialSendScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _send(context);
          });
        }
        return _AuthShell(
          title: widget.purpose == CodePurpose.verifyPhone
              ? context.tr("Подтвердите телефон")
              : context.tr("Код восстановления"),
          subtitle: context.tr("Введите шестизначный код для номера\n{arg0}", {
            'arg0': displayPhone(widget.phone),
          }),
          icon: Icons.sms_outlined,
          child: Column(
            children: [
              _CodeInput(controller: _code, onSubmit: () => _verify(context)),
              const SizedBox(height: 12),
              BlocBuilder<AuthFlowCubit, AuthFlowState>(
                builder: (_, state) => state.devCode?.isNotEmpty == true
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: TextButton.icon(
                          onPressed: () {
                            _code.text = state.devCode!;
                            _code.selection = TextSelection.collapsed(
                              offset: _code.text.length,
                            );
                          },
                          icon: const Icon(Icons.developer_mode, size: 18),
                          label: Text(
                            context.tr("Код staging: {arg0}", {
                              'arg0': state.devCode,
                            }),
                          ),
                        ),
                      )
                    : const SizedBox(height: 12),
              ),
              const SizedBox(height: 8),
              _SubmitButton(
                label: context.tr("Подтвердить"),
                onPressed: () => _verify(context),
              ),
              BlocBuilder<AuthFlowCubit, AuthFlowState>(
                builder: (_, state) => TextButton(
                  onPressed: state.status == AuthFlowStatus.loading
                      ? null
                      : () {
                          setState(() => _sent = false);
                          _send(context);
                        },
                  child: Text(context.tr("Отправить код повторно")),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _key = GlobalKey<FormState>();
  final _phone = TextEditingController(text: '+996');
  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _AuthShell(
    title: context.tr("Восстановить пароль"),
    subtitle: context.tr("Введите телефон, привязанный к аккаунту."),
    child: Form(
      key: _key,
      child: Column(
        children: [
          TextFormField(
            controller: _phone,
            inputFormatters: const [KyrgyzPhoneFormatter()],
            autofocus: true,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            validator: (value) => _phoneError(context, value),
            onFieldSubmitted: (_) => _next(),
            decoration: InputDecoration(labelText: context.tr("Телефон")),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _next,
              child: Text(context.tr("Получить код")),
            ),
          ),
        ],
      ),
    ),
  );

  void _next() {
    if (!(_key.currentState?.validate() ?? false)) return;
    final phone = _phone.text.replaceAll(RegExp(r'\s'), '');
    openPage(context, '/reset-code?phone=${Uri.encodeQueryComponent(phone)}');
  }
}

class NewPasswordPage extends StatefulWidget {
  const NewPasswordPage({super.key, required this.phone, required this.token});
  final String phone;
  final String token;
  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final _key = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    if (!(_key.currentState?.validate() ?? false)) return;
    final ok = await context.read<AuthFlowCubit>().resetPassword(
      ResetPasswordParams(
        phone: widget.phone,
        resetToken: widget.token,
        newPassword: _password.text,
      ),
    );
    if (!context.mounted || !ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr("Пароль изменён. Войдите с новым паролем.")),
      ),
    );
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) => _FlowProvider(
    child: Builder(
      builder: (context) => _AuthShell(
        title: context.tr("Новый пароль"),
        subtitle: context.tr(
          "Придумайте надёжный пароль минимум из 8 символов.",
        ),
        child: Form(
          key: _key,
          child: Column(
            children: [
              TextFormField(
                controller: _password,
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: (v) => (v?.length ?? 0) < 8
                    ? context.tr("Минимум 8 символов")
                    : null,
                decoration: InputDecoration(
                  labelText: context.tr("Новый пароль"),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(context),
                validator: (v) => v != _password.text
                    ? context.tr("Пароли не совпадают")
                    : null,
                decoration: InputDecoration(
                  labelText: context.tr("Повторите пароль"),
                ),
              ),
              const SizedBox(height: 20),
              _SubmitButton(
                label: context.tr("Сохранить пароль"),
                onPressed: () => _submit(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FlowProvider extends StatelessWidget {
  const _FlowProvider({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<AuthFlowCubit>(),
    child: BlocListener<AuthFlowCubit, AuthFlowState>(
      listener: (context, state) {
        if (state.status == AuthFlowStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.errorText(state.message))),
          );
        }
      },
      child: child,
    ),
  );
}

class _AuthShell extends StatelessWidget {
  const _AuthShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.icon = Icons.lock_outline_rounded,
  });
  final String title, subtitle;
  final Widget child;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: KonushAppBar(
      title: context.tr("Аккаунт"),
      back: true,
      fallback: '/login',
    ),
    body: ContentWidth(
      maxWidth: 480,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        children: [
          Center(
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(icon, color: teal, size: 34),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, fontSize: 14, height: 1.6),
          ),
          const SizedBox(height: 36),
          child,
        ],
      ),
    ),
  );
}

class _CodeInput extends StatelessWidget {
  const _CodeInput({required this.controller, required this.onSubmit});
  final TextEditingController controller;
  final VoidCallback onSubmit;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 64,
    child: Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (_, value, _) => Row(
                  children: [
                    for (var i = 0; i < 6; i++)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: value.text.length == i ? tint : canvas,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: value.text.length == i ? teal : border,
                            ),
                          ),
                          child: Text(
                            value.text.length > i ? value.text[i] : '',
                            style: const TextStyle(
                              color: ink,
                              fontSize: 25,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.transparent, fontSize: 25),
            cursorColor: Colors.transparent,
            enableInteractiveSelection: false,
            onSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              labelText: context.tr("Шестизначный код"),
              floatingLabelBehavior: FloatingLabelBehavior.never,
              labelStyle: TextStyle(color: Colors.transparent),
              filled: false,
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AuthFlowCubit, AuthFlowState>(
        builder: (_, state) => SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: state.status == AuthFlowStatus.loading
                ? null
                : onPressed,
            child: state.status == AuthFlowStatus.loading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(label),
          ),
        ),
      );
}

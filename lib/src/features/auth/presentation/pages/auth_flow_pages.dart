import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:konush/src/core/di/injection.dart';
import 'package:konush/src/core/ui/adaptive_dialog.dart';
import 'package:konush/src/core/ui/kyrgyz_phone_formatter.dart';
import 'package:konush/src/features/auth/domain/auth_params.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_flow_cubit.dart';
import 'package:konush/src/features/listings/presentation/pages/listings_page.dart';

bool _validPhone(String value) =>
    RegExp(r'^\+996\d{9}$').hasMatch(value.replaceAll(RegExp(r'\s'), ''));

String? _phoneError(String? value) => _validPhone(value ?? '')
    ? null
    : 'Введите номер в формате +996 XXX XXX XXX';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController(text: '+996');
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    if (!(_key.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final phone = _phone.text.replaceAll(RegExp(r'\s'), '');
    final ok = await context.read<AuthFlowCubit>().register(
      RegisterParams(
        phone: phone,
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      ),
    );
    if (!context.mounted || !ok) return;
    context.go('/verify-phone?phone=${Uri.encodeQueryComponent(phone)}');
  }

  @override
  Widget build(BuildContext context) => _FlowProvider(
    child: Builder(
      builder: (context) => _AuthShell(
        title: 'Создать аккаунт',
        subtitle: 'Размещайте объявления и сохраняйте понравившиеся объекты.',
        child: Form(
          key: _key,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (value) =>
                    (value?.trim().length ?? 0) < 2 ? 'Укажите имя' : null,
                decoration: const InputDecoration(labelText: 'Имя'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                inputFormatters: const [KyrgyzPhoneFormatter()],
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: _phoneError,
                decoration: const InputDecoration(labelText: 'Телефон'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isNotEmpty && !email.contains('@')) {
                    return 'Проверьте email';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Email (необязательно)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _submit(context),
                validator: (value) =>
                    (value?.length ?? 0) < 8 ? 'Минимум 8 символов' : null,
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SubmitButton(
                label: 'Зарегистрироваться',
                onPressed: () => _submit(context),
              ),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Уже есть аккаунт? Войти'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Введите шестизначный код')));
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
      context.go(
        '/new-password?phone=${Uri.encodeQueryComponent(widget.phone)}&token=${Uri.encodeQueryComponent(token)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) => _FlowProvider(
    child: Builder(
      builder: (context) {
        if (!_sent) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_sent) _send(context);
          });
        }
        return _AuthShell(
          title: widget.purpose == CodePurpose.verifyPhone
              ? 'Подтвердите телефон'
              : 'Код восстановления',
          subtitle: 'Код отправлен на ${widget.phone}',
          child: Column(
            children: [
              TextField(
                controller: _code,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                maxLength: 6,
                onSubmitted: (_) => _verify(context),
                decoration: const InputDecoration(
                  labelText: 'Код из SMS',
                  counterText: '',
                ),
              ),
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
                          label: Text('Код staging: ${state.devCode}'),
                        ),
                      )
                    : const SizedBox(height: 12),
              ),
              const SizedBox(height: 8),
              _SubmitButton(
                label: 'Подтвердить',
                onPressed: () => _verify(context),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _sent = false);
                  _send(context);
                },
                child: const Text('Отправить код повторно'),
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
    title: 'Восстановить пароль',
    subtitle: 'Введите телефон, привязанный к аккаунту.',
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
            validator: _phoneError,
            onFieldSubmitted: (_) => _next(),
            decoration: const InputDecoration(labelText: 'Телефон'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _next,
              child: const Text('Получить код'),
            ),
          ),
        ],
      ),
    ),
  );

  void _next() {
    if (!(_key.currentState?.validate() ?? false)) return;
    final phone = _phone.text.replaceAll(RegExp(r'\s'), '');
    context.go('/reset-code?phone=${Uri.encodeQueryComponent(phone)}');
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
      const SnackBar(content: Text('Пароль изменён. Войдите с новым паролем.')),
    );
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) => _FlowProvider(
    child: Builder(
      builder: (context) => _AuthShell(
        title: 'Новый пароль',
        subtitle: 'Придумайте надёжный пароль минимум из 8 символов.',
        child: Form(
          key: _key,
          child: Column(
            children: [
              TextFormField(
                controller: _password,
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v?.length ?? 0) < 8 ? 'Минимум 8 символов' : null,
                decoration: const InputDecoration(labelText: 'Новый пароль'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(context),
                validator: (v) =>
                    v != _password.text ? 'Пароли не совпадают' : null,
                decoration: const InputDecoration(
                  labelText: 'Повторите пароль',
                ),
              ),
              const SizedBox(height: 20),
              _SubmitButton(
                label: 'Сохранить пароль',
                onPressed: () => _submit(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const CatalogHeader(),
    body: SafeArea(
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = state.user;
          if (state.status == AuthStatus.unknown ||
              state.status == AuthStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (user == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go('/login');
            });
            return const Center(child: CircularProgressIndicator());
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: tint,
                    foregroundColor: teal,
                    child: Text(
                      user.name.isEmpty ? 'K' : user.name.characters.first,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.phone,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: muted),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: Icon(
                      user.isVerified
                          ? Icons.verified
                          : Icons.warning_amber_rounded,
                      color: user.isVerified ? teal : Colors.orange,
                    ),
                    title: Text(
                      user.isVerified
                          ? 'Телефон подтверждён'
                          : 'Телефон не подтверждён',
                    ),
                    trailing: user.isVerified
                        ? null
                        : TextButton(
                            onPressed: () => context.go(
                              '/verify-phone?phone=${Uri.encodeQueryComponent(user.phone)}',
                            ),
                            child: const Text('Подтвердить'),
                          ),
                  ),
                  if (user.email != null)
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: Text(user.email!),
                    ),
                  ListTile(
                    leading: const Icon(Icons.home_work_outlined),
                    title: const Text('Мои объявления'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/my-listings'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showAdaptiveConfirmationDialog(
                        context: context,
                        title: 'Выйти из аккаунта?',
                        message:
                            'Вам понадобится снова войти, чтобы размещать объявления и управлять избранным.',
                        confirmLabel: 'Выйти',
                        destructive: true,
                      );
                      if (!confirmed || !context.mounted) return;
                      await context.read<AuthCubit>().logout();
                      if (context.mounted) context.go('/');
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Выйти'),
                  ),
                ],
              ),
            ),
          );
        },
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
            SnackBar(
              content: Text(state.message ?? 'Не удалось выполнить запрос'),
            ),
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
  });
  final String title;
  final String subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: true,
    appBar: AppBar(leading: const BackButton(), title: const Logo()),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ListView(
            primary: false,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF5A6967), height: 1.45),
              ),
              const SizedBox(height: 28),
              child,
            ],
          ),
        ),
      ),
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

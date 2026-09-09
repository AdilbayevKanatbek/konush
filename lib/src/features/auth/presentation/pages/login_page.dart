import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:konush/src/core/di/injection.dart';
import 'package:konush/src/core/ui/kyrgyz_phone_formatter.dart';
import 'package:konush/src/features/auth/domain/auth_params.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_flow_cubit.dart';
import 'package:konush/src/features/home/presentation/home_page.dart';
import 'package:konush/src/features/listings/presentation/pages/listings_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.register = false});
  final bool register;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController(text: '+996');
  final _password = TextEditingController();
  late bool _register;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _register = widget.register;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  String get _phoneValue => _phone.text.replaceAll(RegExp(r'\s'), '');

  void _switch(bool value) {
    FocusManager.instance.primaryFocus?.unfocus();
    _formKey.currentState?.reset();
    setState(() => _register = value);
  }

  Future<void> _submit(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (_register) {
      final ok = await context.read<AuthFlowCubit>().register(
        RegisterParams(
          phone: _phoneValue,
          name: _name.text.trim(),
          password: _password.text,
        ),
      );
      if (!context.mounted || !ok) return;
      context.go(
        '/verify-phone?phone=${Uri.encodeQueryComponent(_phoneValue)}',
      );
    } else {
      await context.read<AuthCubit>().login(_phoneValue, _password.text);
    }
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<AuthFlowCubit>(),
    child: BlocListener<AuthFlowCubit, AuthFlowState>(
      listener: (context, state) {
        if (state.status == AuthFlowStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message ?? 'Ошибка регистрации')),
          );
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: const CatalogHeader(),
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.authenticated) context.go('/');
            if (state.status == AuthStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message ?? 'Ошибка входа')),
              );
            }
          },
          builder: (context, auth) => ListView(
            primary: false,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 432),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 40),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: border),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _Tabs(register: _register, onChanged: _switch),
                            const SizedBox(height: 18),
                            if (_register) ...[
                              TextFormField(
                                controller: _name,
                                textInputAction: TextInputAction.next,
                                validator: (v) => (v?.trim().length ?? 0) < 2
                                    ? 'Укажите имя'
                                    : null,
                                decoration: const InputDecoration(
                                  hintText: 'Ваше имя',
                                ),
                              ),
                              const SizedBox(height: 11),
                            ],
                            TextFormField(
                              controller: _phone,
                              inputFormatters: const [KyrgyzPhoneFormatter()],
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              validator: (v) =>
                                  RegExp(r'^\+996\d{9}$').hasMatch(
                                    (v ?? '').replaceAll(RegExp(r'\s'), ''),
                                  )
                                  ? null
                                  : 'Введите номер в формате +996 XXX XXX XXX',
                              decoration: const InputDecoration(
                                hintText: '+996 ___ ___ ___',
                              ),
                            ),
                            const SizedBox(height: 11),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(context),
                              validator: (v) {
                                if (v?.isEmpty ?? true) {
                                  return 'Введите пароль';
                                }
                                if (_register && (v?.length ?? 0) < 8) {
                                  return 'Минимум 8 символов';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: _register
                                    ? 'Пароль (минимум 8 символов)'
                                    : 'Пароль',
                                suffixIcon: IconButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _Submit(
                              register: _register,
                              authLoading: auth.status == AuthStatus.loading,
                              onPressed: () => _submit(context),
                            ),
                            const SizedBox(height: 10),
                            if (_register)
                              const Text(
                                'После регистрации мы отправим SMS-код для\nподтверждения номера',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                  height: 1.45,
                                ),
                              )
                            else
                              TextButton(
                                onPressed: () =>
                                    context.push('/forgot-password'),
                                child: const Text(
                                  'Забыли пароль?',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const KonushFooter(),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.register, required this.onChanged});
  final bool register;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F3F0),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(children: [_tab('Вход', false), _tab('Регистрация', true)]),
  );
  Widget _tab(String text, bool value) => Expanded(
    child: InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(99),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: register == value ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          boxShadow: register == value
              ? const [BoxShadow(color: Color(0x10000000), blurRadius: 5)]
              : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );
}

class _Submit extends StatelessWidget {
  const _Submit({
    required this.register,
    required this.authLoading,
    required this.onPressed,
  });
  final bool register;
  final bool authLoading;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AuthFlowCubit, AuthFlowState>(
        builder: (_, flow) {
          final loading = authLoading || flow.status == AuthFlowStatus.loading;
          return SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              onPressed: loading ? null : onPressed,
              child: loading
                  ? const SizedBox.square(
                      dimension: 19,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(register ? 'Создать аккаунт' : 'Войти'),
            ),
          );
        },
      );
}

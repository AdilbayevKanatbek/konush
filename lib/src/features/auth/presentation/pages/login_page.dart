import 'package:konush/l10n/source_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:konush/src/core/di/injection.dart';
import 'package:konush/src/core/ui/kyrgyz_phone_formatter.dart';
import 'package:konush/src/features/auth/domain/auth_params.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_flow_cubit.dart';
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
      openPage(
        context,
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
            SnackBar(content: Text(context.errorText(state.message))),
          );
        }
      },
      child: Scaffold(
        appBar: KonushAppBar(
          title: context.tr("Аккаунт"),
          back: true,
          fallback: '/profile',
          actions: [
            IconButton(
              tooltip: context.tr("Закрыть"),
              onPressed: () => closePage(context, fallback: '/profile'),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state.status == AuthStatus.authenticated) {
              if (context.canPop()) {
                context.pop(true);
              } else {
                context.go('/');
              }
            }
            if (state.status == AuthStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(context.errorText(state.message))),
              );
            }
          },
          builder: (context, auth) => ContentWidth(
            maxWidth: 480,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
              children: [
                const Center(child: KonushWordmark()),
                const SizedBox(height: 28),
                Text(
                  _register
                      ? context.tr("Найдём ваш новый дом")
                      : context.tr("Рады видеть вас снова"),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: -.6,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _register
                      ? context.tr(
                          "Создайте аккаунт и сохраняйте любимые места",
                        )
                      : context.tr(
                          "Войдите, чтобы всё избранное было под рукой",
                        ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: canvas,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      for (final registration in [false, true])
                        Expanded(
                          child: InkWell(
                            onTap: () => _switch(registration),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _register == registration
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                registration
                                    ? context.tr("Регистрация")
                                    : context.tr("Вход"),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _register == registration
                                      ? teal
                                      : muted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_register) ...[
                        TextFormField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          validator: (v) => (v?.trim().length ?? 0) < 2
                              ? context.tr("Укажите имя")
                              : null,
                          decoration: InputDecoration(
                            labelText: context.tr("Ваше имя"),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _phone,
                        inputFormatters: const [KyrgyzPhoneFormatter()],
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        validator: (v) =>
                            RegExp(
                              r'^\+996\d{9}$',
                            ).hasMatch((v ?? '').replaceAll(RegExp(r'\s'), ''))
                            ? null
                            : context.tr(
                                "Введите номер в формате +996 XXX XXX XXX",
                              ),
                        decoration: InputDecoration(
                          labelText: context.tr("Номер телефона"),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(context),
                        validator: (v) {
                          if (v?.isEmpty ?? true) {
                            return context.tr("Введите пароль");
                          }
                          if (_register && (v?.length ?? 0) < 8) {
                            return context.tr("Минимум 8 символов");
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: context.tr("Пароль"),
                          helperText: _register
                              ? context.tr("Не менее 8 символов")
                              : null,
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? context.tr("Показать пароль")
                                : context.tr("Скрыть пароль"),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      if (!_register)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                openPage(context, '/forgot-password'),
                            child: Text(
                              context.tr("Забыли пароль?"),
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      BlocBuilder<AuthFlowCubit, AuthFlowState>(
                        builder: (_, flow) {
                          final loading =
                              auth.status == AuthStatus.loading ||
                              flow.status == AuthFlowStatus.loading;
                          return SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: loading
                                  ? null
                                  : () => _submit(context),
                              child: loading
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _register
                                          ? context.tr("Создать аккаунт")
                                          : context.tr("Войти"),
                                    ),
                            ),
                          );
                        },
                      ),
                      if (_register)
                        Padding(
                          padding: EdgeInsets.only(top: 18),
                          child: Text(
                            context.tr(
                              "После регистрации подтвердите номер телефона кодом.",
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: muted,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

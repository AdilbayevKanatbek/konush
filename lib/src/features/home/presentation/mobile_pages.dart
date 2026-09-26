import 'package:konush/l10n/locale_cubit.dart';
import 'package:konush/l10n/source_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:konush/src/core/ui/konush_ui.dart';
import 'package:konush/src/core/ui/adaptive_dialog.dart';
import 'package:konush/src/features/auth/domain/user.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_cubit.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: KonushAppBar(
      title: context.tr("Личный кабинет"),
      actions: [
        IconButton(
          tooltip: context.tr("Помощь"),
          onPressed: () => openPage(context, '/support'),
          icon: const Icon(Icons.headset_mic_outlined),
        ),
        IconButton(
          tooltip: context.tr("Настройки"),
          onPressed: () => openPage(context, '/settings'),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    ),
    body: ContentWidth(
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state.status == AuthStatus.unknown ||
              state.status == AuthStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == AuthStatus.failure && state.user == null) {
            return SingleChildScrollView(
              child: AppEmptyState(
                icon: Icons.cloud_off_outlined,
                title: context.tr('Не удалось загрузить'),
                message: context.errorText(state.message),
                action: FilledButton(
                  onPressed: context.read<AuthCubit>().restoreSession,
                  child: Text(context.tr('Повторить')),
                ),
              ),
            );
          }
          final user = state.user;
          return ListView(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: tint,
                          foregroundColor: teal,
                          child: user == null || user.name.isEmpty
                              ? const Icon(
                                  Icons.person_outline_rounded,
                                  size: 29,
                                )
                              : Text(
                                  user.name.characters.first.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name.isNotEmpty == true
                                    ? user!.name
                                    : context.tr("Добро пожаловать"),
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user == null
                                    ? context.tr("Ваше пространство в Konush")
                                    : switch (user.role) {
                                        UserRole.user => context.tr(
                                          "Пользователь",
                                        ),
                                        UserRole.agent => context.tr("Агент"),
                                        UserRole.admin => context.tr(
                                          "Администратор",
                                        ),
                                      },
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    if (user == null) ...[
                      Text(
                        context.tr(
                          "Войдите, чтобы синхронизировать избранное и управлять своими объявлениями.",
                        ),
                        style: TextStyle(
                          color: muted,
                          height: 1.5,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => openPage(context, '/login'),
                          child: Text(
                            context.tr("Войти или зарегистрироваться"),
                          ),
                        ),
                      ),
                    ] else
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: tint,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              user.isVerified
                                  ? Icons.verified_outlined
                                  : Icons.phone_outlined,
                              color: teal,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayPhone(user.phone),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    user.isVerified
                                        ? context.tr("Номер подтверждён")
                                        : context.tr(
                                            "Подтвердите номер телефона",
                                          ),
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!user.isVerified)
                              TextButton(
                                onPressed: () => openPage(
                                  context,
                                  '/verify-phone?phone=${Uri.encodeQueryComponent(user.phone)}',
                                ),
                                child: Text(
                                  context.tr("Подтвердить"),
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (user != null)
                ListTile(
                  leading: const Icon(Icons.phone_callback_outlined),
                  title: Text(context.tr('Мои заявки')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => openPage(context, '/my-requests'),
                ),
              Container(
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(context.tr("Мои объявления")),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        context.tr(
                          "Все ваши объекты и их статусы — в одном месте.",
                        ),
                        style: TextStyle(
                          color: muted,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                    if (user != null)
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        leading: const Icon(
                          Icons.home_work_outlined,
                          color: teal,
                        ),
                        title: Text(
                          context.tr("Открыть мои объявления"),
                          style: TextStyle(fontSize: 14),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: muted,
                        ),
                        onTap: () => openPage(context, '/my-listings'),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => openPage(context, '/submit'),
                          icon: const Icon(Icons.add, size: 20),
                          label: Text(context.tr("Подать объявление")),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ColoredBox(
                color: Colors.white,
                child: Column(
                  children: [
                    _SettingRow(
                      context.tr("Избранное"),
                      icon: Icons.favorite_border_rounded,
                      onTap: () => context.go('/favorites'),
                    ),
                    const Divider(height: 1, indent: 20),
                    _SettingRow(
                      context.tr("Помощь Konush"),
                      icon: Icons.help_outline_rounded,
                      onTap: () => openPage(context, '/support'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    return Scaffold(
      appBar: KonushAppBar(
        title: context.tr("Настройки"),
        back: true,
        fallback: '/profile',
        actions: [
          if (user != null)
            TextButton(
              onPressed: () => _logout(context),
              child: Text(
                context.tr("Выйти"),
                style: TextStyle(color: Color(0xFFC44949), fontSize: 13),
              ),
            ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          children: [
            if (user != null) ...[
              _SettingsLabel(context.tr("Личные данные")),
              _SettingRow(context.tr("Имя"), value: user.name),
              const Divider(height: 1, indent: 20),
              _SettingRow(
                context.tr("Телефон"),
                value: displayPhone(user.phone),
                onTap: user.isVerified
                    ? null
                    : () => openPage(
                        context,
                        '/verify-phone?phone=${Uri.encodeQueryComponent(user.phone)}',
                      ),
              ),
              const Divider(height: 1, indent: 20),
              if (user.email != null) ...[
                _SettingRow('Email', value: user.email),
                const Divider(height: 1, indent: 20),
              ],
              _SettingRow(
                context.tr("Восстановить пароль"),
                onTap: () => openPage(context, '/forgot-password'),
              ),
            ],
            _SettingsLabel(context.tr("Настройки приложения")),
            _SettingRow(
              context.tr('Язык'),
              value: context.watch<LocaleCubit>().state.languageCode == 'ky'
                  ? 'Кыргызча'
                  : 'Русский',
              onTap: () => showLanguagePicker(context),
            ),
            const Divider(height: 1, indent: 20),
            _SettingRow(
              context.tr("Помощь Konush"),
              onTap: () => openPage(context, '/support'),
            ),
            const Divider(height: 1, indent: 20),
            _SettingRow(
              context.tr("О приложении"),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Konush',
                applicationVersion: '1.0.0',
                applicationIcon: const KonushMark(size: 40),
                children: [
                  Text(
                    context.tr(
                      "Недвижимость в Кыргызстане. Находите объекты для покупки и аренды.",
                    ),
                  ),
                ],
              ),
            ),
            if (user == null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: FilledButton(
                  onPressed: () => openPage(context, '/login'),
                  child: Text(context.tr("Войти в аккаунт")),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showAdaptiveConfirmationDialog(
      context: context,
      title: context.tr("Выйти из аккаунта?"),
      message: context.tr(
        "Для доступа к своим объявлениям понадобится снова войти.",
      ),
      confirmLabel: context.tr("Выйти"),
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await context.read<AuthCubit>().logout();
      if (context.mounted) context.go('/');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr("Не удалось завершить выход. Повторите попытку."),
            ),
          ),
        );
      }
    }
  }
}

class _SettingsLabel extends StatelessWidget {
  const _SettingsLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 26, 20, 8),
    child: Text(text, style: const TextStyle(color: muted, fontSize: 12)),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow(this.title, {this.value, this.icon, this.onTap});
  final String title;
  final String? value;
  final IconData? icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: icon == null ? null : Icon(icon, color: teal, size: 22),
    title: Text(title, style: const TextStyle(fontSize: 14)),
    onTap: onTap,
    subtitle: value == null
        ? null
        : Text(value!, style: const TextStyle(color: muted, fontSize: 12)),
    trailing: onTap == null
        ? null
        : const Icon(Icons.chevron_right_rounded, color: muted, size: 21),
  );
}

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});
  static const questions = [
    (
      'Как сохранить объявление?',
      'Нажмите на сердце в карточке объекта. Сохранённые объявления доступны во вкладке «Избранное».',
    ),
    (
      'Как связаться с продавцом?',
      'Откройте объявление и нажмите «Написать» для переписки или «Связаться с продавцом» для звонка.',
    ),
    (
      'Где мои объявления?',
      'Войдите в аккаунт, откройте «Кабинет», затем «Мои объявления». Там доступны статусы и удаление.',
    ),
    (
      'Как восстановить пароль?',
      'На экране входа нажмите «Забыли пароль?». Укажите номер +996 и следуйте шагам подтверждения.',
    ),
    (
      'Как подать объявление?',
      'Публикация через мобильное приложение пока недоступна. Этот раздел появится в следующем обновлении.',
    ),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: KonushAppBar(
      title: context.tr("Помощь Konush"),
      back: true,
      fallback: '/messages',
    ),
    body: ContentWidth(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Notice(
            context.tr(
              "Здесь собраны ответы на частые вопросы. Чат с поддержкой пока недоступен.",
            ),
            icon: Icons.headset_mic_outlined,
          ),
          const SizedBox(height: 26),
          Text(
            context.tr("Чем можем помочь?"),
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr("Выберите вопрос ниже"),
            style: TextStyle(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          for (final question in questions)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  iconColor: teal,
                  title: Text(
                    context.tr(question.$1),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                  children: [
                    Text(
                      context.tr(question.$2),
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.55,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'source_messages.dart';

class LocaleCubit extends Cubit<Locale> {
  LocaleCubit(this.storage) : super(const Locale('ru'));
  final FlutterSecureStorage storage;
  int _revision = 0;
  Future<void> _writes = Future.value();
  Future<void> restore() async {
    final revision = _revision;
    try {
      final code = await storage.read(key: 'preferred_locale');
      if (!isClosed &&
          revision == _revision &&
          (code == 'ru' || code == 'ky')) {
        emit(Locale(code!));
      }
    } catch (_) {}
  }

  Future<void> select(String code) async {
    if (code != 'ru' && code != 'ky') return;
    final revision = ++_revision;
    final write = _writes
        .catchError((_) {})
        .then((_) => storage.write(key: 'preferred_locale', value: code));
    _writes = write;
    await write;
    if (!isClosed && revision == _revision) emit(Locale(code));
  }
}

final _pickerOpen = Expando<bool>();
Future<void> showLanguagePicker(BuildContext context) async {
  final navigator = Navigator.of(context);
  if (_pickerOpen[navigator] == true) return;
  _pickerOpen[navigator] = true;
  try {
    final cubit = context.read<LocaleCubit>();
    final code = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr('Язык'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              for (final option in const {
                'ru': 'Русский',
                'ky': 'Кыргызча',
              }.entries)
                ListTile(
                  title: Text(option.value),
                  trailing: cubit.state.languageCode == option.key
                      ? const Icon(Icons.check_rounded)
                      : null,
                  onTap: () => Navigator.pop(context, option.key),
                ),
            ],
          ),
        ),
      ),
    );
    if (code != null) {
      try {
        await cubit.select(code);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr('Не удалось сохранить язык. Повторите попытку.'),
              ),
            ),
          );
        }
      }
    }
  } finally {
    _pickerOpen[navigator] = false;
  }
}

class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () => showLanguagePicker(context),
    child: Text(
      context.watch<LocaleCubit>().state.languageCode == 'ky' ? 'КЫР' : 'РУС',
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konush/src/core/error/app_exception.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'construction_widgets.dart';
import 'construction_pager.dart';

class ContactButton extends StatefulWidget {
  const ContactButton({
    super.key,
    required this.companyId,
    required this.targetType,
    required this.targetId,
  });
  final String companyId, targetType, targetId;
  @override
  State<ContactButton> createState() => _ContactButtonState();
}

class _ContactButtonState extends State<ContactButton> {
  bool _open = false;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    icon: const Icon(Icons.phone_outlined),
    label: Text(context.tr('Связаться с застройщиком')),
    onPressed: widget.companyId.isEmpty || _open
        ? null
        : () async {
            if (_open) return;
            setState(() => _open = true);
            try {
              await showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useRootNavigator: true,
                useSafeArea: true,
                builder: (_) => FractionallySizedBox(
                  heightFactor: .9,
                  child: ContactSheet(
                    companyId: widget.companyId,
                    targetType: widget.targetType,
                    targetId: widget.targetId,
                  ),
                ),
              );
            } finally {
              if (mounted) setState(() => _open = false);
            }
          },
  );
}

class ContactSheet extends StatefulWidget {
  const ContactSheet({
    super.key,
    required this.companyId,
    required this.targetType,
    required this.targetId,
  });
  final String companyId, targetType, targetId;
  @override
  State<ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends State<ContactSheet> {
  final _repo = constructionRepository();
  bool _phoneShown = false, _busy = false, _formShown = false;
  String? _contactError;
  Future<void> _record(String kind) async {
    try {
      await _repo.contact(widget.targetType, widget.targetId, kind);
    } catch (_) {
      if (mounted) {
        setState(() => _contactError = 'Не удалось выполнить запрос');
      }
    }
  }

  Future<void> _callback(ConstructionCompany company) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final auth = context.read<AuthCubit>();
      if (auth.state.user == null) {
        await openPage(context, '/login');
        if (!mounted || auth.state.user == null) return;
      }
      if (auth.state.user!.id == company.ownerId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr('Нельзя отправить заявку на свой объект'),
              ),
            ),
          );
        }
        return;
      }
      if (mounted) setState(() => _formShown = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(context.tr('Контакты')),
      leading: IconButton(
        tooltip: context.tr('Закрыть'),
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: ConstructionLoad<ConstructionCompany>(
      load: () => _repo.company(widget.companyId),
      builder: (company) => ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        children: [
          Text(company.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (company.phone.isNotEmpty) ...[
            if (!_phoneShown)
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () async {
                        if (_busy || _phoneShown) return;
                        setState(() {
                          _phoneShown = true;
                          _busy = true;
                          _contactError = null;
                        });
                        await _record('phone_view');
                        if (mounted) setState(() => _busy = false);
                      },
                child: Text(context.tr('Показать телефон')),
              )
            else
              OutlinedButton.icon(
                icon: const Icon(Icons.call),
                label: Text(phoneDisplay(company.phone)),
                onPressed: () => openConstructionLink(
                  context,
                  'tel:${company.phone}',
                  phone: true,
                ),
              ),
          ],
          if (company.whatsapp.isNotEmpty)
            OutlinedButton.icon(
              icon: const Icon(Icons.chat_outlined),
              label: Text('WhatsApp'),
              onPressed: _busy
                  ? null
                  : () async {
                      if (_busy) return;
                      setState(() {
                        _busy = true;
                        _contactError = null;
                      });
                      await _record('whatsapp_click');
                      if (context.mounted) {
                        await openConstructionLink(
                          context,
                          'https://wa.me/${company.whatsapp.replaceAll(RegExp(r'\D'), '')}',
                        );
                      }
                      if (mounted) setState(() => _busy = false);
                    },
            ),
          if (_contactError != null)
            Text(
              context.tr(_contactError!),
              style: const TextStyle(color: muted),
            ),
          FilledButton(
            onPressed: _busy ? null : () => _callback(company),
            child: Text(context.tr('Заказать звонок')),
          ),
          if (_formShown)
            CallbackForm(
              targetType: widget.targetType,
              targetId: widget.targetId,
            ),
        ],
      ),
    ),
  );
}

class CallbackForm extends StatefulWidget {
  const CallbackForm({
    super.key,
    required this.targetType,
    required this.targetId,
  });
  final String targetType, targetId;
  @override
  State<CallbackForm> createState() => _CallbackFormState();
}

class _CallbackFormState extends State<CallbackForm> {
  final _form = GlobalKey<FormState>();
  final _comment = TextEditingController();
  String _time = 'any';
  bool _busy = false, _sent = false, _uncertain = false;
  String? _error;
  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || _sent || _uncertain || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await constructionRepository().callback(
        widget.targetType,
        widget.targetId,
        _time,
        _comment.text.trim(),
      );
      if (mounted) setState(() => _sent = true);
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _uncertain = error.statusCode == null || error.statusCode! >= 500;
        _error = _uncertain
            ? 'Ответ не получен. Проверьте список заявок перед повторной отправкой.'
            : error.statusCode == 404
            ? 'Объект недоступен'
            : error.statusCode == 401
            ? 'Необходимо войти в аккаунт'
            : error.statusCode == 429
            ? 'Слишком много запросов. Попробуйте позже.'
            : error.code == 'OWN_TARGET'
            ? 'Нельзя отправить заявку на свой объект'
            : error.code == 'PHONE_NOT_VERIFIED'
            ? 'Подтвердите телефон перед отправкой заявки'
            : error.code == 'CALLBACK_EXISTS'
            ? 'Заявка на этот объект уже отправлена. Проверьте мои заявки.'
            : 'Не удалось отправить заявку. Проверьте данные.';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _uncertain = true;
          _error =
              'Ответ не получен. Проверьте список заявок перед повторной отправкой.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionTitle('Заявка на звонок'),
        if (_sent)
          Notice(context.tr('Заявка отправлена'))
        else ...[
          DropdownButtonFormField<String>(
            initialValue: _time,
            isExpanded: true,
            decoration: InputDecoration(labelText: context.tr('Удобное время')),
            items: [
              for (final entry in const {
                'any': 'В любое время',
                'morning': 'Утром',
                'day': 'Днём',
                'evening': 'Вечером',
              }.entries)
                DropdownMenuItem(
                  value: entry.key,
                  child: Text(context.tr(entry.value)),
                ),
            ],
            onChanged: _busy || _uncertain
                ? null
                : (value) => setState(() => _time = value!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _comment,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            enabled: !_busy && !_uncertain,
            decoration: InputDecoration(labelText: context.tr('Комментарий')),
            validator: (v) => (v?.trim().length ?? 0) > 500
                ? context.tr('Не более 500 символов')
                : null,
          ),
          if (_error != null) Notice(context.tr(_error!)),
          FilledButton(
            onPressed: _busy || _uncertain ? null : _send,
            child: Text(context.tr(_busy ? 'Отправка…' : 'Отправить заявку')),
          ),
        ],
        TextButton(
          onPressed: () => openPage(context, '/my-requests'),
          child: Text(context.tr('Мои заявки')),
        ),
      ],
    ),
  );
}

class MyRequestsPage extends StatelessWidget {
  const MyRequestsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: KonushAppBar(
      title: context.tr('Мои заявки'),
      back: true,
      fallback: '/profile',
    ),
    body: ContentWidth(
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, auth) {
          if (auth.user == null) {
            return Center(
              child: FilledButton(
                onPressed: () => openPage(context, '/login'),
                child: Text(context.tr('Войти')),
              ),
            );
          }
          return ConstructionPager<Json>(
            key: ValueKey(auth.user!.id),
            load: (page) => constructionRepository().requests(page: page),
            emptyTitle: 'Заявок пока нет',
            row: (request) => Card(
              child: ListTile(
                title: Text(
                  request['target_title'] as String? ??
                      context.tr('Заявка на звонок'),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        const {
                              'new': 'Новая',
                              'in_progress': 'В работе',
                              'done': 'Завершена',
                              'spam': 'Отклонена',
                            }[request['status']] ??
                            'Новая',
                      ),
                    ),
                    if (date(request['status_changed_at']) != null)
                      Text(displayDate(date(request['status_changed_at'])!)),
                    if ((request['comment'] as String? ?? '').isNotEmpty)
                      Text(request['comment'] as String),
                  ],
                ),
                onTap: () {
                  final path = switch (request['target_type']) {
                    'unit' => '/units/${request['unit_id']}',
                    'complex' => '/complexes/${request['complex_id']}',
                    'company' => '/companies/${request['company_id']}',
                    'listing' => '/listings/${request['listing_id']}',
                    _ => null,
                  };
                  if (path != null) openPage(context, path);
                },
              ),
            ),
          );
        },
      ),
    ),
  );
}

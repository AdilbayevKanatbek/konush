import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:konush/l10n/source_messages.dart';
import 'package:konush/src/core/di/injection.dart';
import 'package:konush/src/core/network/api_client.dart';
import 'package:konush/src/core/ui/adaptive_dialog.dart';
import 'package:konush/src/core/ui/konush_ui.dart';
import 'package:konush/src/core/ui/open_street_map.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:konush/src/features/listings/data/listing_submission.dart';
import 'package:konush/src/features/listings/domain/listing.dart';

const _cities = [
  'Бишкек',
  'Ош',
  'Джалал-Абад',
  'Каракол',
  'Нарын',
  'Талас',
  'Баткен',
];
const _centers = [
  LatLng(42.8746, 74.5698),
  LatLng(40.5283, 72.7985),
  LatLng(40.9332, 73.0019),
  LatLng(42.4907, 78.3936),
  LatLng(41.4287, 75.9911),
  LatLng(42.5228, 72.2427),
  LatLng(40.0626, 70.8194),
];

class SubmitListingPage extends StatefulWidget {
  const SubmitListingPage({
    super.key,
    this.repository,
    this.pickPhotos,
    this.pickLocation,
    this.initialListing,
  });
  final ListingSubmissionRepository? repository;
  final Future<List<XFile>> Function()? pickPhotos;
  final Future<LatLng?> Function()? pickLocation;
  final Listing? initialListing;
  @override
  State<SubmitListingPage> createState() => _SubmitListingPageState();
}

class _SubmitListingPageState extends State<SubmitListingPage> {
  final _form = GlobalKey<FormState>();
  final _location = GlobalKey();
  final _title = TextEditingController(),
      _description = TextEditingController();
  final _address = TextEditingController(), _price = TextEditingController();
  final _area = TextEditingController(), _rooms = TextEditingController();
  final _floor = TextEditingController(), _floors = TextEditingController();
  final _photos = <ListingUpload>[];
  final _removedPhotos = <String>{};
  late final Map<String, dynamic> _initialDraft;
  late final ListingSubmission _submission;
  DealType _deal = DealType.sale;
  PropertyType _property = PropertyType.apartment;
  int _step = 0, _city = 0;
  LatLng? _point;
  String? _photoError, _owner;
  bool _picking = false, _negotiable = false, _allowClose = false;
  bool _closing = false;
  bool get _editing => widget.initialListing != null;
  List<ListingPhoto> get _existingPhotos =>
      widget.initialListing?.photos ?? const [];
  int get _photoCount =>
      _existingPhotos.length - _removedPhotos.length + _photos.length;
  String get _cityId => '00000000-0000-0000-0000-00000000000${_city + 1}';
  bool get _dirty => _editing
      ? !mapEquals(_initialDraft, _draft()) ||
            _photos.isNotEmpty ||
            _removedPhotos.isNotEmpty
      : _title.text.isNotEmpty ||
            _description.text.isNotEmpty ||
            _address.text.isNotEmpty ||
            _price.text.isNotEmpty ||
            _area.text.isNotEmpty ||
            _point != null ||
            _photos.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialListing;
    if (initial != null) {
      _step = 1;
      _owner = initial.userId;
      _title.text = initial.title;
      _description.text = initial.description;
      _address.text = initial.address;
      _price.text = initial.price.toString();
      _area.text = initial.area.toString();
      _rooms.text = initial.rooms?.toString() ?? '';
      _floor.text = initial.floor?.toString() ?? '';
      _floors.text = initial.totalFloors?.toString() ?? '';
      _negotiable = initial.isNegotiable;
      _deal = initial.dealType;
      _property = initial.propertyType;
      final cityIndex = List.generate(
        7,
        (i) => '00000000-0000-0000-0000-00000000000${i + 1}',
      ).indexOf(initial.cityId);
      _city = cityIndex < 0 ? 0 : cityIndex;
      _point = LatLng(initial.latitude, initial.longitude);
    }
    _initialDraft = _draft();
    for (final field in [
      _title,
      _description,
      _address,
      _price,
      _area,
      _rooms,
      _floor,
      _floors,
    ]) {
      field.addListener(_changed);
    }
    _submission = ListingSubmission(
      widget.repository ?? ListingSubmissionRepository(sl<ApiClient>()),
      listingId: initial?.id,
    );
    _submission.addListener(_changed);
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        widget.pickPhotos == null) {
      _recoverPhotos();
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _submission.removeListener(_changed);
    _submission.dispose();
    for (final field in [
      _title,
      _description,
      _address,
      _price,
      _area,
      _rooms,
      _floor,
      _floors,
    ]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _recoverPhotos() async {
    try {
      final lost = await ImagePicker().retrieveLostData();
      if (lost.files != null) await _acceptPhotos(lost.files!);
    } catch (_) {
      /* No recovered selection: normal on unsupported platforms. */
    }
  }

  Future<void> _acceptPhotos(List<XFile> files) async {
    for (final file in files) {
      if (!mounted) return;
      if (_photoCount >= 20) {
        setState(() => _photoError = 'Можно добавить до 20 фотографий');
        break;
      }
      if (await file.length() > 10 * 1024 * 1024) {
        if (mounted) {
          setState(() => _photoError = 'Размер файла превышает 10 МБ');
        }
        continue;
      }
      final photo = ListingUpload(
        name: file.name,
        bytes: await file.readAsBytes(),
      );
      if (!mounted) return;
      if (photo.mime == null) {
        setState(() => _photoError = 'Поддерживаются JPEG, PNG и WebP');
        continue;
      }
      setState(() => _photos.add(photo));
    }
  }

  Future<void> _pick() async {
    if (_picking || _submission.busy) return;
    setState(() {
      _picking = true;
      _photoError = null;
    });
    try {
      final files =
          await (widget.pickPhotos?.call() ??
              ImagePicker().pickMultiImage(
                maxWidth: 2400,
                maxHeight: 2400,
                imageQuality: 90,
                requestFullMetadata: false,
              ));
      await _acceptPhotos(files);
    } catch (_) {
      if (mounted) {
        setState(
          () => _photoError =
              'Не удалось выбрать фотографии. Проверьте доступ к галерее.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _close() async {
    if (_submission.busy || _picking || _closing) return;
    _closing = true;
    if (_dirty && !_submission.complete) {
      final leave = await showAdaptiveConfirmationDialog(
        context: context,
        title: context.tr('Закрыть форму?'),
        message: context.tr(
          _submission.created == null
              ? _editing
                    ? 'Несохранённые изменения будут потеряны.'
                    : 'Введённые данные не будут сохранены.'
              : _editing
              ? 'Изменения объявления уже сохранены. Работа с фотографиями не завершена.'
              : 'Объявление уже создано. Незагруженные фотографии останутся только в этой форме.',
        ),
        confirmLabel: context.tr('Закрыть'),
      );
      if (!leave || !mounted) {
        _closing = false;
        return;
      }
    }
    setState(() => _allowClose = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) {
      closePage(context, fallback: _editing ? '/my-listings' : '/profile');
    }
  }

  String? _requiredLength(String? value, int min, int max, String message) =>
      (value?.trim().length ?? 0) < min || (value?.trim().length ?? 0) > max
      ? context.tr(message)
      : null;
  String? _positive(String? value) {
    final n = double.tryParse((value ?? '').replaceAll(',', '.'));
    return n == null || !n.isFinite || n < 1
        ? context.tr('Введите число больше нуля')
        : null;
  }

  String? _integer(String? value) =>
      int.tryParse(value ?? '') == null || int.parse(value!) < 1
      ? context.tr('Введите целое число больше нуля')
      : null;
  String? _optionalInt(String? value) =>
      value == null || value.isEmpty ? null : _integer(value);
  Future<void> _choosePoint() async {
    final future = widget.pickLocation != null
        ? widget.pickLocation!()
        : Navigator.of(context).push<LatLng>(
            MaterialPageRoute(
              builder: (_) =>
                  _LocationPicker(initial: _point, center: _centers[_city]),
            ),
          );
    final point = await future;
    if (mounted && point != null) setState(() => _point = point);
  }

  Future<void> _submit() async {
    final user = context.read<AuthCubit>().state.user;
    if (user == null || !user.isVerified || _submission.busy || _picking) {
      return;
    }
    if (_owner != null && _owner != user.id) return;
    _owner = user.id;
    if (_submission.created == null) {
      final invalid = _form.currentState!.validateGranularly();
      if (invalid.isNotEmpty) {
        final field = invalid.first;
        final key = field.widget.key;
        final label = key is ValueKey<String> ? context.tr(key.value) : '';
        await _showSubmissionError(
          label.isEmpty ? field.errorText! : '$label: ${field.errorText!}',
          target: field.context,
        );
        return;
      }
    }
    if (_point == null) {
      await _showSubmissionError(
        context.tr('Выберите точное расположение объекта для отправки.'),
        target: _location.currentContext,
      );
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    await _submission.submit(
      _draft(),
      _photos,
      removedPhotoIds: _removedPhotos,
    );
    if (mounted && _submission.error != null) {
      await _showSubmissionError(context.errorText(_submission.error));
    }
  }

  Map<String, dynamic> _draft() {
    final initial = widget.initialListing;
    return <String, dynamic>{
      if (initial != null) ...{
        'district_id': _cityId == initial.cityId ? initial.districtId : null,
        'land_area': initial.landArea,
        'year': initial.year,
        'price_usd': initial.priceUsd,
        'contact_phone': initial.contactPhone,
      },
      'deal_type': _deal.wireName,
      'property_type': _property.wireName,
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'address': _address.text.trim(),
      'city_id': _cityId,
      'price': int.tryParse(_price.text),
      'area': double.tryParse(_area.text.replaceAll(',', '.')),
      'latitude': _point?.latitude,
      'longitude': _point?.longitude,
      'is_negotiable': _negotiable,
      if (_editing || _rooms.text.isNotEmpty)
        'rooms': int.tryParse(_rooms.text),
      if (_editing || _floor.text.isNotEmpty)
        'floor': int.tryParse(_floor.text),
      if (_editing || _floors.text.isNotEmpty)
        'floors': int.tryParse(_floors.text),
    };
  }

  Future<void> _showSubmissionError(
    String message, {
    BuildContext? target,
  }) async {
    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 6)),
      );
    if (target != null) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted || !target.mounted) return;
      await Scrollable.ensureVisible(
        target,
        alignment: 0.15,
        duration: const Duration(milliseconds: 250),
      );
    }
  }

  void _openCreated() {
    final id = _submission.created?.id;
    context.go(id == null ? '/my-listings' : '/my-listings/$id');
  }

  Widget _field(
    String name,
    TextEditingController controller, {
    String? hint,
    int lines = 1,
    int? max,
    bool number = false,
    String? Function(String?)? validate,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      key: ValueKey(name),
      controller: controller,
      enabled: _submission.created == null && !_submission.busy,
      minLines: lines,
      maxLines: lines,
      maxLength: max,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : lines > 1
          ? TextInputType.multiline
          : TextInputType.text,
      textInputAction: lines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
      validator: validate,
      decoration: InputDecoration(
        labelText: context.tr(name),
        helperText: hint == null ? null : context.tr(hint),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final user = auth.user;
    final wrongUser = _owner != null && _owner != user?.id;
    return PopScope<Object?>(
      canPop:
          _allowClose ||
          (!_dirty &&
              !_submission.busy &&
              !_picking &&
              MediaQuery.viewInsetsOf(context).bottom == 0 &&
              ModalRoute.of(context)?.isFirst == false),
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (MediaQuery.viewInsetsOf(context).bottom > 0) {
          FocusManager.instance.primaryFocus?.unfocus();
          SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
          return;
        }
        _close();
      },
      child: Scaffold(
        appBar: KonushAppBar(
          title: context.tr(
            _editing ? 'Редактировать объявление' : 'Подать объявление',
          ),
          actions: [
            IconButton(
              tooltip: context.tr('Закрыть'),
              onPressed: _submission.busy || _picking ? null : _close,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        body: ContentWidth(
          maxWidth: 600,
          child: user == null || wrongUser
              ? SingleChildScrollView(
                  child: AppEmptyState(
                    icon: Icons.person_outline,
                    title: context.tr('Войти в аккаунт'),
                    message: context.tr('Войдите, чтобы подать объявление.'),
                    action: FilledButton(
                      onPressed: () => openPage(context, '/login'),
                      child: Text(context.tr('Войти')),
                    ),
                  ),
                )
              : !user.isVerified
              ? SingleChildScrollView(
                  child: AppEmptyState(
                    icon: Icons.phone_outlined,
                    title: context.tr('Подтвердите номер телефона'),
                    message: context.tr(
                      'Для подачи объявления нужен подтверждённый номер.',
                    ),
                    action: FilledButton(
                      onPressed: () => openPage(
                        context,
                        '/verify-phone?phone=${Uri.encodeQueryComponent(user.phone)}',
                      ),
                      child: Text(context.tr('Подтвердить')),
                    ),
                  ),
                )
              : _submission.complete
              ? SingleChildScrollView(
                  child: AppEmptyState(
                    icon: Icons.task_alt,
                    title: context.tr(
                      _editing
                          ? 'Изменения сохранены'
                          : 'Объявление отправлено на проверку',
                    ),
                    message: context.tr(
                      _editing
                          ? 'Актуальный статус доступен в моих объявлениях.'
                          : 'После одобрения оно появится в каталоге. Статус доступен в моих объявлениях.',
                    ),
                    action: FilledButton(
                      onPressed: _openCreated,
                      child: Text(context.tr('Открыть объявление')),
                    ),
                  ),
                )
              : Form(
                  key: _form,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.tr(
                            _step == 0
                                ? 'Начнём с главного'
                                : 'Расскажите об объекте',
                          ),
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_editing) ...[
                          Notice(
                            context.tr(
                              'Изменение содержания отправит объявление на повторную проверку.',
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (_step == 0) ...[
                          Text(
                            context.tr('Новое объявление'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final deal in DealType.values)
                                ChoiceChip(
                                  label: Text(
                                    context.tr(switch (deal) {
                                      DealType.sale => 'Продать',
                                      DealType.rent => 'Сдать в аренду',
                                      DealType.rentDay => 'Посуточно',
                                    }),
                                  ),
                                  selected: _deal == deal,
                                  onSelected: (_) =>
                                      setState(() => _deal = deal),
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            context.tr('Недвижимость'),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final property in PropertyType.values)
                                ChoiceChip(
                                  label: Text(
                                    context.tr(switch (property) {
                                      PropertyType.apartment => 'Квартира',
                                      PropertyType.house => 'Дом',
                                      PropertyType.commercial => 'Коммерческая',
                                      PropertyType.land => 'Участок',
                                      PropertyType.garage => 'Гараж',
                                    }),
                                  ),
                                  selected: _property == property,
                                  onSelected: (_) =>
                                      setState(() => _property = property),
                                ),
                            ],
                          ),
                        ] else ...[
                          _field(
                            'Заголовок',
                            _title,
                            max: 200,
                            hint: 'От 10 до 200 символов',
                            validate: (v) => _requiredLength(
                              v,
                              10,
                              200,
                              'От 10 до 200 символов',
                            ),
                          ),
                          _field(
                            'Описание',
                            _description,
                            max: 5000,
                            lines: 4,
                            hint: 'От 20 до 5000 символов',
                            validate: (v) => _requiredLength(
                              v,
                              20,
                              5000,
                              'От 20 до 5000 символов',
                            ),
                          ),
                          _field(
                            'Цена, сом',
                            _price,
                            number: true,
                            validate: _integer,
                          ),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(context.tr('Возможен торг')),
                            value: _negotiable,
                            onChanged: _submission.created != null
                                ? null
                                : (value) =>
                                      setState(() => _negotiable = value!),
                          ),
                          _field(
                            'Площадь, м²',
                            _area,
                            number: true,
                            validate: _positive,
                          ),
                          _field(
                            'Комнат',
                            _rooms,
                            number: true,
                            validate: _optionalInt,
                          ),
                          _field(
                            'Этаж',
                            _floor,
                            number: true,
                            validate: (v) {
                              final error = _optionalInt(v);
                              if (error != null) return error;
                              if (v != null &&
                                  v.isNotEmpty &&
                                  _floors.text.isNotEmpty &&
                                  (int.tryParse(v) ?? 0) >
                                      (int.tryParse(_floors.text) ?? 0)) {
                                return context.tr(
                                  'Этаж не может быть выше этажности дома',
                                );
                              }
                              return null;
                            },
                          ),
                          _field(
                            'Этажей в доме',
                            _floors,
                            number: true,
                            validate: _optionalInt,
                          ),
                          DropdownButtonFormField<int>(
                            initialValue: _city,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: context.tr('Город'),
                            ),
                            items: [
                              for (var i = 0; i < _cities.length; i++)
                                DropdownMenuItem(
                                  value: i,
                                  child: Text(context.tr(_cities[i])),
                                ),
                            ],
                            onChanged:
                                _submission.created != null || _submission.busy
                                ? null
                                : (value) => setState(() {
                                    _city = value!;
                                    _point = null;
                                  }),
                          ),
                          const SizedBox(height: 16),
                          _field(
                            'Адрес',
                            _address,
                            validate: (v) => _requiredLength(
                              v,
                              3,
                              300,
                              'От 3 до 300 символов',
                            ),
                          ),
                          OutlinedButton.icon(
                            key: _location,
                            onPressed:
                                _submission.created != null || _submission.busy
                                ? null
                                : _choosePoint,
                            icon: const Icon(Icons.location_on_outlined),
                            label: Text(
                              context.tr(
                                _point == null
                                    ? 'Указать место на карте'
                                    : 'Место на карте выбрано',
                              ),
                            ),
                          ),
                          if (_point == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                context.tr(
                                  'Выберите точное расположение объекта для отправки.',
                                ),
                                style: const TextStyle(color: muted),
                              ),
                            ),
                          const SizedBox(height: 24),
                          Text(
                            context.tr('Фотографии'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr(
                              'До 20 фото, JPEG, PNG или WebP, до 10 МБ каждое.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final photo in _existingPhotos)
                                SizedBox(
                                  width: 96,
                                  height: 96,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Opacity(
                                        opacity:
                                            _removedPhotos.contains(photo.id)
                                            ? 0.3
                                            : 1,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Image.network(
                                            photo.url,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                const Icon(
                                                  Icons.broken_image_outlined,
                                                ),
                                          ),
                                        ),
                                      ),
                                      if (_submission.created == null &&
                                          !_submission.busy &&
                                          !_submission.uncertain)
                                        Align(
                                          alignment: Alignment.topRight,
                                          child: IconButton(
                                            key: ValueKey(
                                              'existing-photo-${photo.id}',
                                            ),
                                            tooltip: context.tr(
                                              _removedPhotos.contains(photo.id)
                                                  ? 'Вернуть фото'
                                                  : 'Удалить фото',
                                            ),
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.white,
                                            ),
                                            onPressed: () => setState(() {
                                              if (_removedPhotos.contains(
                                                    photo.id,
                                                  ) &&
                                                  _photoCount >= 20) {
                                                _photoError =
                                                    'Можно добавить до 20 фотографий';
                                              } else if (!_removedPhotos.remove(
                                                photo.id,
                                              )) {
                                                _removedPhotos.add(photo.id);
                                              }
                                            }),
                                            icon: Icon(
                                              _removedPhotos.contains(photo.id)
                                                  ? Icons.undo
                                                  : Icons.close,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              for (final photo in _photos)
                                SizedBox(
                                  width: 96,
                                  height: 96,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.memory(
                                          photo.bytes,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(
                                            Icons.broken_image_outlined,
                                          ),
                                        ),
                                      ),
                                      if (photo.uploaded)
                                        const Align(
                                          alignment: Alignment.bottomRight,
                                          child: Icon(
                                            Icons.check_circle,
                                            color: teal,
                                          ),
                                        ),
                                      if (!photo.uploaded &&
                                          !_submission.busy &&
                                          !_submission.uncertain)
                                        Align(
                                          alignment: Alignment.topRight,
                                          child: IconButton(
                                            tooltip: context.tr('Удалить фото'),
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.white,
                                            ),
                                            onPressed: () => setState(
                                              () => _photos.remove(photo),
                                            ),
                                            icon: const Icon(
                                              Icons.close,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (_removedPhotos.isNotEmpty &&
                              _submission.created == null)
                            Notice(
                              context.tr(
                                'Фотографии будут удалены после сохранения.',
                              ),
                            ),
                          if (_photoCount < 20 && !_submission.uncertain)
                            TextButton.icon(
                              onPressed: _picking || _submission.busy
                                  ? null
                                  : _pick,
                              icon: const Icon(
                                Icons.add_photo_alternate_outlined,
                              ),
                              label: Text(
                                context.tr(
                                  _picking
                                      ? 'Загрузка…'
                                      : 'Добавить фотографии',
                                ),
                              ),
                            ),
                          if (_photoError != null)
                            Notice(context.tr(_photoError!)),
                          if (_submission.created != null &&
                              !_submission.complete)
                            Notice(
                              context.tr(
                                _editing
                                    ? 'Изменения объявления уже сохранены. Работа с фотографиями не завершена.'
                                    : 'Объявление создано. Завершите загрузку фотографий.',
                              ),
                            ),
                          if (_submission.error != null) ...[
                            Notice(context.errorText(_submission.error)),
                            if (_submission.validationDetails is Map)
                              Text(
                                context.tr(
                                  'Проверьте обязательные поля и расположение на карте.',
                                ),
                              ),
                            TextButton(
                              onPressed: _openCreated,
                              child: Text(
                                context.tr('Проверить мои объявления'),
                              ),
                            ),
                          ],
                          if (_submission.busy) ...[
                            const LinearProgressIndicator(),
                            const SizedBox(height: 8),
                            Text(
                              '${context.tr('Загружено фото')}: ${_submission.uploadedCount}/${_photos.length}',
                            ),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            context.tr(
                              'Объявление появится в каталоге после проверки.',
                            ),
                            style: const TextStyle(color: muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
        bottomNavigationBar:
            user == null ||
                !user.isVerified ||
                wrongUser ||
                _submission.complete
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: ContentWidth(
                    maxWidth: 600,
                    child: Row(
                      children: [
                        if (_step > 0 && _submission.created == null) ...[
                          IconButton(
                            tooltip: context.tr('Назад'),
                            onPressed: _submission.busy
                                ? null
                                : () => setState(() => _step = 0),
                            icon: const Icon(Icons.arrow_back),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: FilledButton(
                            onPressed:
                                _submission.busy ||
                                    _picking ||
                                    _submission.uncertain ||
                                    (_editing &&
                                        _step == 1 &&
                                        _submission.created == null &&
                                        !_dirty)
                                ? null
                                : _step == 0
                                ? () => setState(() => _step = 1)
                                : _submit,
                            child: Text(
                              context.tr(
                                _step == 0
                                    ? 'Далее'
                                    : _submission.busy
                                    ? _editing
                                          ? 'Сохранение…'
                                          : 'Отправка…'
                                    : _submission.created == null
                                    ? _editing
                                          ? 'Сохранить изменения'
                                          : 'Отправить на проверку'
                                    : _editing
                                    ? 'Повторить сохранение'
                                    : 'Повторить загрузку фото',
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
    );
  }
}

class _LocationPicker extends StatefulWidget {
  const _LocationPicker({required this.center, this.initial});
  final LatLng center;
  final LatLng? initial;
  @override
  State<_LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<_LocationPicker> {
  LatLng? _point;
  @override
  void initState() {
    super.initState();
    _point = widget.initial;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Расположение объекта'))),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(context.tr('Нажмите на карту, чтобы отметить объект.')),
        ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: widget.initial ?? widget.center,
              initialZoom: 13,
              maxZoom: 19,
              onTap: (_, point) {
                if (point.latitude >= 39 &&
                    point.latitude <= 43.4 &&
                    point.longitude >= 69 &&
                    point.longitude <= 80.5) {
                  setState(() => _point = point);
                }
              },
            ),
            children: [
              const OpenStreetMapTiles(),
              if (_point != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _point!,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_on,
                        color: teal,
                        size: 42,
                      ),
                    ),
                  ],
                ),
              const OpenStreetMapAttribution(),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _point == null
                    ? null
                    : () => Navigator.of(context).pop(_point),
                child: Text(context.tr('Выбрать это место')),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

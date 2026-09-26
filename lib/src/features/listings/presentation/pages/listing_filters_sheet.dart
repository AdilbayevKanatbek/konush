import 'package:konush/l10n/source_messages.dart';
import 'package:flutter/material.dart';
import 'package:konush/src/core/ui/konush_ui.dart';
import 'package:konush/src/features/listings/domain/listing_filter.dart';

class ListingFiltersSheet extends StatefulWidget {
  const ListingFiltersSheet({
    super.key,
    required this.initial,
    required this.districts,
    this.newBuild = false,
  });
  final ListingFilter initial;
  final Map<String, String> districts;
  final bool newBuild;
  @override
  State<ListingFiltersSheet> createState() => _ListingFiltersSheetState();
}

class _ListingFiltersSheetState extends State<ListingFiltersSheet> {
  final _form = GlobalKey<FormState>();
  late final _priceFrom = TextEditingController(
    text: widget.initial.priceMin?.toString() ?? '',
  );
  late final _priceTo = TextEditingController(
    text: widget.initial.priceMax?.toString() ?? '',
  );
  late final _areaFrom = TextEditingController(
    text: widget.initial.areaMin?.toString() ?? '',
  );
  late final _areaTo = TextEditingController(
    text: widget.initial.areaMax?.toString() ?? '',
  );
  late int? _rooms = widget.initial.rooms, _floor = widget.initial.floorMin;
  late String? _district = widget.initial.districtId;
  int _reset = 0;
  @override
  void dispose() {
    for (final controller in [_priceFrom, _priceTo, _areaFrom, _areaTo]) {
      controller.dispose();
    }
    super.dispose();
  }

  double? _number(String value) =>
      double.tryParse(value.trim().replaceAll(',', '.'));
  String? _validate(String? raw, {bool integer = false}) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    final number = _number(value);
    if (number == null || !number.isFinite || number < 0) {
      return context.tr("Введите число от 0");
    }
    if (integer && int.tryParse(value) == null) {
      return context.tr("Введите целую сумму");
    }
    return null;
  }

  Widget _range(
    String title,
    TextEditingController from,
    TextEditingController to, {
    bool integer = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: from,
              keyboardType: TextInputType.numberWithOptions(decimal: !integer),
              textInputAction: TextInputAction.next,
              validator: (value) => _validate(value, integer: integer),
              decoration: InputDecoration(labelText: context.tr("От")),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: to,
              keyboardType: TextInputType.numberWithOptions(decimal: !integer),
              textInputAction: TextInputAction.next,
              validator: (value) {
                final error = _validate(value, integer: integer);
                if (error != null) return error;
                final lower = _number(from.text), upper = _number(to.text);
                if (lower != null && upper != null && upper < lower) {
                  return context.tr("Не меньше значения «От»");
                }
                return null;
              },
              decoration: InputDecoration(labelText: context.tr("До")),
            ),
          ),
        ],
      ),
    ],
  );
  void _apply() {
    if (!_form.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(
      context,
      ListingFilter(
        rooms: _rooms,
        districtId: _district,
        floorMin: _floor,
        priceMin: int.tryParse(_priceFrom.text.trim()),
        priceMax: int.tryParse(_priceTo.text.trim()),
        areaMin: _number(_areaFrom.text),
        areaMax: _number(_areaTo.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PageBackScope(
    child: SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.tr("Фильтры"),
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr("Закрыть"),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _rooms = null;
                    _floor = null;
                    _district = null;
                    _reset++;
                    _form.currentState!.reset();
                    for (final controller in [
                      _priceFrom,
                      _priceTo,
                      _areaFrom,
                      _areaTo,
                    ]) {
                      controller.clear();
                    }
                  }),
                  child: Text(context.tr("Сбросить фильтры")),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr("Комнаты"),
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final room in <int?>[null, 1, 2, 3, 4])
                      ChoiceChip(
                        label: Text(
                          room == null ? context.tr("Любое") : '$room',
                        ),
                        selected: _rooms == room,
                        showCheckmark: false,
                        selectedColor: tint,
                        onSelected: (_) => setState(() => _rooms = room),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey('district-$_reset'),
                  initialValue: _district,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.tr("Район Бишкека"),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(context.tr("Все районы")),
                    ),
                    for (final entry in widget.districts.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                  ],
                  onChanged: (value) => setState(() => _district = value),
                ),
                const SizedBox(height: 16),
                _range(
                  widget.newBuild
                      ? context.tr("Цена за м², USD")
                      : context.tr("Цена, сом"),
                  _priceFrom,
                  _priceTo,
                  integer: true,
                ),
                const SizedBox(height: 16),
                _range(context.tr("Площадь, м²"), _areaFrom, _areaTo),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  key: ValueKey('floor-$_reset'),
                  initialValue: _floor,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: context.tr("Этаж")),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(context.tr("Любой")),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text(context.tr("Не первый")),
                    ),
                    DropdownMenuItem(
                      value: 5,
                      child: Text(context.tr("От 5 этажа")),
                    ),
                    DropdownMenuItem(
                      value: 10,
                      child: Text(context.tr("От 10 этажа")),
                    ),
                  ],
                  onChanged: (value) => setState(() => _floor = value),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _apply,
                    child: Text(context.tr("Показать объявления")),
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

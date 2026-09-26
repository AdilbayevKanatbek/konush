import 'package:flutter/material.dart';
import 'construction_widgets.dart';

Future<Json?> showConstructionFilters(
  BuildContext context,
  Json current, {
  bool units = false,
}) => showModalBottomSheet<Json>(
  context: context,
  isScrollControlled: true,
  useRootNavigator: true,
  useSafeArea: true,
  builder: (_) => FractionallySizedBox(
    heightFactor: .94,
    child: ConstructionFilters(initial: current, units: units),
  ),
);

class ConstructionFilters extends StatefulWidget {
  const ConstructionFilters({
    super.key,
    required this.initial,
    this.units = false,
  });
  final Json initial;
  final bool units;
  @override
  State<ConstructionFilters> createState() => _ConstructionFiltersState();
}

class _ConstructionFiltersState extends State<ConstructionFilters> {
  final _form = GlobalKey<FormState>();
  late Json _value = {...widget.initial};
  final _numbers = <String, TextEditingController>{};
  late final _building = TextEditingController(
    text: _value['building'] as String? ?? '',
  );
  static const _labels = {
    'price_min': 'Цена от, сом',
    'price_max': 'Цена до, сом',
    'price_per_m2_min': 'Цена за м² от, сом',
    'price_per_m2_max': 'Цена за м² до, сом',
    'handover_year_min': 'Сдача с года',
    'handover_year_max': 'Сдача до года',
    'readiness_min': 'Готовность от, %',
    'area_min': 'Площадь от, м²',
    'area_max': 'Площадь до, м²',
    'floor_min': 'Этаж от',
    'floor_max': 'Этаж до',
  };
  @override
  void initState() {
    super.initState();
    _value['room_choice'] = _value['rooms_min'] != null
        ? '4plus'
        : _value['rooms']?.toString() ?? '';
    for (final key in _labels.keys) {
      _numbers[key] = TextEditingController(
        text: _value[key]?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final control in _numbers.values) {
      control.dispose();
    }
    _building.dispose();
    super.dispose();
  }

  Widget _select(String key, String label, Map<String, String> options) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: DropdownButtonFormField<String>(
          key: ValueKey('$key-${_value[key]}'),
          initialValue: _value[key]?.toString() ?? '',
          isExpanded: true,
          decoration: InputDecoration(labelText: context.tr(label)),
          items: [
            if (!options.containsKey(''))
              DropdownMenuItem(value: '', child: Text(context.tr('Все'))),
            for (final entry in options.entries)
              DropdownMenuItem(
                value: entry.key,
                child: Text(context.tr(entry.value)),
              ),
          ],
          onChanged: (value) => setState(() {
            if (value == null || value.isEmpty) {
              _value.remove(key);
            } else {
              _value[key] = value;
            }
          }),
        ),
      );
  Widget _multi(String key, String label, Map<String, String> options) {
    final selected = (_value[key] as String? ?? '')
        .split(',')
        .where((s) => s.isNotEmpty)
        .toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(label),
        Wrap(
          spacing: 8,
          children: [
            for (final entry in options.entries)
              FilterChip(
                label: Text(context.tr(entry.value)),
                selected: selected.contains(entry.key),
                onSelected: (on) => setState(() {
                  on ? selected.add(entry.key) : selected.remove(entry.key);
                  if (selected.isEmpty) {
                    _value.remove(key);
                  } else {
                    _value[key] = selected.join(',');
                  }
                }),
              ),
          ],
        ),
      ],
    );
  }

  String? _validate(String key, String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final raw = value.trim().replaceAll(',', '.');
    final decimal = key.startsWith('area');
    final pattern = decimal
        ? RegExp(r'^\d{1,6}(\.\d{1,2})?$')
        : RegExp(r'^-?\d{1,15}$');
    final number = num.tryParse(raw);
    final min = key.startsWith('floor')
        ? -10
        : key.startsWith('handover')
        ? 2000
        : 0;
    final max = key.startsWith('floor')
        ? 150
        : key.startsWith('handover')
        ? 2100
        : key == 'readiness_min'
        ? 100
        : 999999999999999;
    if (!pattern.hasMatch(raw) ||
        number == null ||
        !number.isFinite ||
        number < min ||
        number > max) {
      return context.tr('Проверьте допустимое значение');
    }
    if (key.endsWith('_max')) {
      final minText = _numbers[key.replaceAll('_max', '_min')]?.text
          .trim()
          .replaceAll(',', '.');
      final lower = num.tryParse(minText ?? '');
      if (lower != null && number < lower) {
        return context.tr('Максимум должен быть не меньше минимума');
      }
    }
    return null;
  }

  Widget _number(String key) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: _numbers[key],
      key: ValueKey('filter-$key'),
      keyboardType: TextInputType.numberWithOptions(
        decimal: key.startsWith('area'),
        signed: key.startsWith('floor'),
      ),
      decoration: InputDecoration(labelText: context.tr(_labels[key]!)),
      validator: (value) => _validate(key, value),
    ),
  );
  void _apply() {
    final invalid = _form.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      Scrollable.ensureVisible(
        invalid.first.context,
        duration: const Duration(milliseconds: 250),
        alignment: .15,
      );
      return;
    }
    for (final entry in _numbers.entries) {
      final raw = entry.value.text.trim().replaceAll(',', '.');
      if (raw.isEmpty) {
        _value.remove(entry.key);
      } else {
        _value[entry.key] = num.parse(raw);
      }
    }
    final rooms = _value.remove('room_choice');
    _value.remove('rooms');
    _value.remove('rooms_min');
    if (rooms == '4plus') {
      _value['rooms_min'] = 4;
    } else if (rooms != null && rooms != '') {
      _value['rooms'] = widget.units ? int.parse(rooms as String) : rooms;
    }
    if (widget.units) {
      final building = _building.text.trim();
      if (building.isEmpty) {
        _value.remove('building');
      } else {
        _value['building'] = building;
      }
    }
    Navigator.pop(context, _value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _apply,
            child: Text(context.tr('Применить')),
          ),
        ),
      ),
      appBar: AppBar(
        title: Text(context.tr('Фильтры')),
        leading: IconButton(
          tooltip: context.tr('Закрыть'),
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _value = {};
              _building.clear();
              for (final control in _numbers.values) {
                control.clear();
              }
            }),
            child: Text(context.tr('Сбросить')),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!widget.units) _select('city_id', 'Город', cities),
              if (widget.units) ...[
                _select('unit_type', 'Тип объекта', unitTypes),
                _multi('sale_status', 'Статус продажи', saleStatuses),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _building,
                  maxLength: 50,
                  decoration: InputDecoration(labelText: context.tr('Корпус')),
                ),
              ],
              _select(
                'room_choice',
                widget.units ? 'Комнат' : 'Есть квартиры с комнатностью',
                {
                  '0': 'Студия',
                  for (var i = 1; i <= 20; i++) '$i': '$i',
                  '4plus': '4+',
                },
              ),
              if (!widget.units) ...[
                _multi('class', 'Класс жилья', housingClasses),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr('Только сданные')),
                  value: _value['handover_completed'] == true,
                  onChanged: (on) => setState(() {
                    if (on) {
                      _value['handover_completed'] = true;
                    } else {
                      _value.remove('handover_completed');
                    }
                  }),
                ),
                _number('handover_year_min'),
                _number('handover_year_max'),
                _number('readiness_min'),
              ],
              if (widget.units) _number('price_min'),
              _number('price_max'),
              if (widget.units) _number('price_per_m2_min'),
              _number('price_per_m2_max'),
              if (widget.units) ...[
                _number('area_min'),
                _number('area_max'),
                _number('floor_min'),
                _number('floor_max'),
              ],
              if (!widget.units) ...[
                for (final entry in const {
                  'has_mortgage': 'Есть ипотека',
                  'has_installment': 'Есть рассрочка',
                }.entries)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.tr(entry.value)),
                    value: _value[entry.key] == true,
                    onChanged: (on) => setState(() {
                      if (on) {
                        _value[entry.key] = true;
                      } else {
                        _value.remove(entry.key);
                      }
                    }),
                  ),
                _multi(
                  'amenities',
                  'Инфраструктура — все выбранные',
                  amenities,
                ),
                const SizedBox(height: 16),
              ],
              _select(
                'sort',
                'Сортировка',
                widget.units ? unitSorts : complexSorts,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

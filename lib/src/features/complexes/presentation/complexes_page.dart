import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:konush/src/core/ui/open_street_map.dart';
import 'construction_widgets.dart';
import 'construction_filters.dart';
import 'construction_pager.dart';
export 'complex_detail_page.dart';

class ComplexesPage extends StatefulWidget {
  const ComplexesPage({super.key});
  @override
  State<ComplexesPage> createState() => _ComplexesPageState();
}

class _ComplexesPageState extends State<ComplexesPage> {
  final _repository = constructionRepository();
  final _search = TextEditingController();
  Json _filters = {};
  String _query = '';
  bool _map = false;
  double? _rate;
  @override
  void initState() {
    super.initState();
    _loadRate();
  }

  Future<void> _loadRate() async {
    final rate = await _repository.exchangeRate();
    if (mounted) setState(() => _rate = rate);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reset() => setState(() {
    _filters = {};
    _query = '';
    _search.clear();
  });
  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _query = _search.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final filtered =
        _filters.keys.any((key) => key != 'sort') || _query.isNotEmpty;
    return Scaffold(
      backgroundColor: canvas,
      appBar: KonushAppBar(
        title: context.tr('Жилые комплексы'),
        back: true,
        fallback: '/',
        actions: [
          IconButton(
            tooltip: context.tr('Ипотека'),
            icon: const Icon(Icons.account_balance_outlined),
            onPressed: () => openPage(context, '/mortgage'),
          ),
        ],
      ),
      body: ContentWidth(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _search,
                    maxLength: 100,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: context.tr('Название ЖК или застройщик'),
                      suffixIcon: IconButton(
                        tooltip: context.tr('Найти'),
                        onPressed: _submit,
                        icon: const Icon(Icons.search),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ChoiceChip(
                        label: Text(context.tr('Все')),
                        selected: _filters['handover_completed'] != true,
                        onSelected: (_) => setState(() {
                          _filters = {..._filters}
                            ..remove('handover_completed');
                        }),
                      ),
                      ChoiceChip(
                        label: Text(context.tr('Сданы')),
                        selected: _filters['handover_completed'] == true,
                        onSelected: (_) => setState(() {
                          _filters = {..._filters, 'handover_completed': true};
                        }),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.tune, size: 18),
                        label: Text(context.tr('Фильтры')),
                        onPressed: () async {
                          final filters = await showConstructionFilters(
                            context,
                            _filters,
                          );
                          if (mounted && filters != null) {
                            setState(() => _filters = filters);
                          }
                        },
                      ),
                      ActionChip(
                        avatar: Icon(
                          _map ? Icons.list : Icons.map_outlined,
                          size: 18,
                        ),
                        label: Text(context.tr(_map ? 'Список' : 'Карта')),
                        onPressed: () => setState(() => _map = !_map),
                      ),
                      if (filtered)
                        ActionChip(
                          label: Text(context.tr('Сбросить')),
                          onPressed: _reset,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ConstructionPager<ResidentialComplex>(
                key: ValueKey(jsonEncode([_query, _filters, _map])),
                load: (page) => _repository.list(
                  page: page,
                  query: _query,
                  filters: _filters,
                  perPage: _map ? 50 : 20,
                ),
                row: (item) => ComplexCard(item, rate: _rate),
                emptyTitle: filtered
                    ? 'Ничего не найдено по этим фильтрам'
                    : 'Жилых комплексов пока нет',
                emptyAction: filtered
                    ? TextButton(
                        onPressed: _reset,
                        child: Text(context.tr('Сбросить фильтры')),
                      )
                    : null,
                mapBuilder: !_map
                    ? null
                    : (items, footer, failed) => Stack(
                        children: [
                          ComplexesMap(items: items),
                          if (items.isEmpty && !failed)
                            Positioned(
                              top: 8,
                              left: 8,
                              right: 8,
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        context.tr(
                                          filtered
                                              ? 'Ничего не найдено по этим фильтрам'
                                              : 'Жилых комплексов пока нет',
                                        ),
                                      ),
                                      if (filtered)
                                        TextButton(
                                          onPressed: _reset,
                                          child: Text(
                                            context.tr('Сбросить фильтры'),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 32,
                            left: 16,
                            right: 16,
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              child: footer,
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
}

class ComplexesMap extends StatelessWidget {
  const ComplexesMap({super.key, required this.items});
  final List<ResidentialComplex> items;
  @override
  Widget build(BuildContext context) {
    final mapped = items
        .where((c) => validPoint(c.latitude, c.longitude))
        .toList();
    final points = mapped
        .map((c) => LatLng(c.latitude!, c.longitude!))
        .toList();
    return FlutterMap(
      key: ValueKey(mapped.map((c) => c.id).join(',')),
      options: MapOptions(
        initialCenter: points.firstOrNull ?? const LatLng(42.8746, 74.5698),
        initialZoom: 12,
        maxZoom: 19,
        initialCameraFit: points.length > 1
            ? CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(points),
                padding: const EdgeInsets.fromLTRB(95, 45, 95, 80),
                maxZoom: 14,
              )
            : null,
      ),
      children: [
        const OpenStreetMapTiles(),
        MarkerLayer(
          markers: [
            for (final item in mapped)
              Marker(
                point: LatLng(item.latitude!, item.longitude!),
                width: 185,
                height: 60,
                child: Semantics(
                  button: true,
                  label: item.name,
                  child: GestureDetector(
                    key: ValueKey('complex-pin-${item.id}'),
                    onTap: () => openPage(context, '/complexes/${item.id}'),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: teal,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.displayPrice == null
                              ? item.name
                              : '${context.tr(item.parkingOnly ? 'Машиноместа от' : 'от')} ${money(item.displayPrice!)} ${context.tr('сом')}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const OpenStreetMapAttribution(),
      ],
    );
  }
}

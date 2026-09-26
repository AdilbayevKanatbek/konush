import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:konush/src/core/error/app_exception.dart';
import 'package:konush/src/core/network/pagination.dart';
import 'construction_widgets.dart';
import 'construction_pager.dart';
import 'construction_filters.dart';
import 'construction_financing.dart';
import 'construction_contacts.dart';
import 'complexes_page.dart' show ComplexesMap;

class ComplexDetailPage extends StatelessWidget {
  const ComplexDetailPage({super.key, required this.id});
  final String id;
  Future<(ResidentialComplex, double?)> _load() async {
    final repo = constructionRepository();
    final results = await Future.wait<Object?>([
      repo.get(id),
      repo.exchangeRate(),
    ]);
    return (results[0] as ResidentialComplex, results[1] as double?);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: KonushAppBar(
      title: context.tr('Жилой комплекс'),
      back: true,
      fallback: '/complexes',
    ),
    body: ContentWidth(
      child: ConstructionLoad(
        key: ValueKey('complex-$id'),
        load: _load,
        builder: (data) {
          final (item, rate) = data;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              ConstructionGallery(item.photos),
              const SizedBox(height: 20),
              Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
              if (item.companyId.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () =>
                        openPage(context, '/companies/${item.companyId}'),
                    child: Text(item.company),
                  ),
                ),
              Text(item.address),
              const SizedBox(height: 12),
              ComplexStatus(item),
              if (item.progressDate != null)
                Text(
                  '${context.tr('Обновлено')}: ${displayDate(item.progressDate!)}',
                ),
              const SizedBox(height: 12),
              Text(
                context.tr(
                  'Данные о строительстве предоставлены застройщиком. Платформа не гарантирует сроки сдачи.',
                ),
                style: const TextStyle(color: muted),
              ),
              const SizedBox(height: 16),
              if (item.displayPrice != null)
                PriceText(
                  item.displayPrice!,
                  rate: rate,
                  prefix: context.tr(
                    item.parkingOnly ? 'Машиноместа от' : 'от',
                  ),
                ),
              if (item.catalogDate != null)
                Text(
                  '${context.tr(item.json['catalog_updated_at'] == null ? 'Цены опубликованы' : 'Цены обновлены')}: ${displayDate(item.catalogDate!)}',
                ),
              if (staleCatalog(item, DateTime.now()))
                Notice(context.tr('Цены могут быть неактуальны')),
              const SectionTitle('Об объекте'),
              Text(item.description),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (housingClasses.containsKey(item.text('housing_class')))
                    Chip(
                      label: Text(
                        context.tr(housingClasses[item.text('housing_class')]!),
                      ),
                    ),
                  if (item.intValue('floors_total') != null)
                    Chip(
                      label: Text(
                        '${context.tr('Этажей')}: ${item.intValue('floors_total')}',
                      ),
                    ),
                  if (item.intValue('buildings_count') != null)
                    Chip(
                      label: Text(
                        '${context.tr('Корпусов')}: ${item.intValue('buildings_count')}',
                      ),
                    ),
                  if (item.amount('ceiling_height') != null)
                    Chip(
                      label: Text(
                        '${context.tr('Высота потолков')}: ${item.amount('ceiling_height')} м',
                      ),
                    ),
                  for (final tag in (item.json['amenities'] as List? ?? []))
                    if (amenities.containsKey(tag))
                      Chip(label: Text(context.tr(amenities[tag]!))),
                ],
              ),
              if (validPoint(item.latitude, item.longitude)) ...[
                const SectionTitle('На карте'),
                SizedBox(height: 220, child: ComplexesMap(items: [item])),
              ],
              if (item.text('video_url').isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () =>
                      openConstructionLink(context, item.text('video_url')),
                  icon: const Icon(Icons.play_circle_outline),
                  label: Text(context.tr('Видео о комплексе')),
                ),
              if (item.documents.isNotEmpty) ...[
                const SectionTitle('Документы'),
                for (final doc in item.documents)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      doc['content_type'] == 'application/pdf'
                          ? Icons.picture_as_pdf_outlined
                          : Icons.image_outlined,
                    ),
                    title: Text(doc['title'] as String? ?? ''),
                    subtitle: Text(
                      '${((integer(doc['size_bytes']) ?? 0) / 1024).ceil()} ${context.tr('КБ')}',
                    ),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () {
                      final url = doc['url'] as String? ?? '';
                      if ((doc['content_type'] as String? ?? '').startsWith(
                        'image/',
                      )) {
                        showConstructionImage(context, url);
                      } else {
                        openConstructionLink(context, url);
                      }
                    },
                  ),
              ],
              const SectionTitle('Доступные предложения'),
              for (final row in item.summary)
                Card(
                  child: ListTile(
                    title: Text(
                      unitTitle(
                        context,
                        row['unit_type'] as String? ?? '',
                        integer(row['rooms']),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${context.tr('Свободно')}: ${row['available_count'] ?? 0} / ${row['total_count'] ?? 0}',
                        ),
                        if (row['min_area'] != null)
                          Text('${row['min_area']}–${row['max_area']} м²'),
                        if (row['min_price'] is num)
                          PriceText(
                            integer(row['min_price'])!,
                            rate: rate,
                            prefix: context.tr('от'),
                            small: true,
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => openPage(
                      context,
                      Uri(
                        path: '/complexes/$id/units',
                        queryParameters: {
                          'unit_type':
                              row['unit_type'] as String? ?? 'apartment',
                          if (row['rooms'] != null)
                            'rooms': row['rooms'].toString(),
                        },
                      ).toString(),
                    ),
                  ),
                ),
              FilledButton(
                onPressed: () => openPage(context, '/complexes/$id/units'),
                child: Text(context.tr('Все предложения')),
              ),
              FinancingSection(complex: item),
              const SizedBox(height: 20),
              ContactButton(
                companyId: item.companyId,
                targetType: 'complex',
                targetId: item.id,
              ),
            ],
          );
        },
      ),
    ),
  );
}

class UnitCatalogPage extends StatefulWidget {
  const UnitCatalogPage({
    super.key,
    required this.complexId,
    this.initial = const {},
  });
  final String complexId;
  final Json initial;
  @override
  State<UnitCatalogPage> createState() => _UnitCatalogPageState();
}

class _UnitCatalogPageState extends State<UnitCatalogPage> {
  final _repo = constructionRepository();
  late Json _filters = {...widget.initial};
  double? _rate;
  @override
  void initState() {
    super.initState();
    _loadRate();
  }

  Future<void> _loadRate() async {
    final rate = await _repo.exchangeRate();
    if (mounted) setState(() => _rate = rate);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: KonushAppBar(
      title: context.tr('Предложения в ЖК'),
      back: true,
      fallback: '/complexes/${widget.complexId}',
    ),
    body: ContentWidth(
      child: ConstructionLoad<ResidentialComplex>(
        key: ValueKey('units-${widget.complexId}'),
        load: () => _repo.get(widget.complexId),
        builder: (complex) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complex.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(context.tr('Все')),
                        selected: !_filters.containsKey('unit_type'),
                        onSelected: (_) => setState(() {
                          _filters = {..._filters}..remove('unit_type');
                        }),
                      ),
                      for (final entry in unitTypes.entries)
                        if (complex.summary.any(
                          (r) => r['unit_type'] == entry.key,
                        ))
                          ChoiceChip(
                            label: Text(
                              '${context.tr(entry.value)} (${complex.summary.where((r) => r['unit_type'] == entry.key).fold<int>(0, (sum, r) => sum + (integer(r['total_count']) ?? 0))})',
                            ),
                            selected: _filters['unit_type'] == entry.key,
                            onSelected: (_) => setState(() {
                              _filters = {..._filters, 'unit_type': entry.key}
                                ..remove('rooms')
                                ..remove('rooms_min');
                            }),
                          ),
                      ActionChip(
                        label: Text(context.tr('Фильтры')),
                        avatar: const Icon(Icons.tune, size: 18),
                        onPressed: () async {
                          final value = await showConstructionFilters(
                            context,
                            _filters,
                            units: true,
                          );
                          if (mounted && value != null) {
                            setState(() => _filters = value);
                          }
                        },
                      ),
                      if (_filters.isNotEmpty)
                        ActionChip(
                          label: Text(context.tr('Сбросить')),
                          onPressed: () => setState(() => _filters = {}),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ConstructionPager<ComplexUnit>(
                key: ValueKey((complex, jsonEncode(_filters))),
                load: (page) => _repo.units(
                  widget.complexId,
                  page: page,
                  filters: _filters,
                ),
                emptyTitle: _filters.isEmpty
                    ? 'Предложений пока нет'
                    : 'Ничего не найдено по этим фильтрам',
                emptyAction: _filters.isEmpty
                    ? null
                    : TextButton(
                        onPressed: () => setState(() => _filters = {}),
                        child: Text(context.tr('Сбросить фильтры')),
                      ),
                row: (unit) => Card(
                  child: ListTile(
                    title: Text(unitTitle(context, unit.type, unit.rooms)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${unit.area} м² · ${context.tr('Этаж')}: ${unit.floor ?? '—'}',
                        ),
                        if (unit.building.isNotEmpty)
                          Text('${context.tr('Корпус')}: ${unit.building}'),
                        if (unit.number.isNotEmpty) Text('№ ${unit.number}'),
                        ListingBadge(
                          context.tr(
                            saleStatuses[unit.saleStatus] ?? 'Свободно',
                          ),
                          quiet: unit.saleStatus != 'available',
                        ),
                        PriceText(unit.price, rate: _rate),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => openPage(
                      context,
                      '/complexes/${widget.complexId}/units/${unit.id}',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class UnitDetailPage extends StatelessWidget {
  const UnitDetailPage({super.key, required this.id, this.complexId});
  final String id;
  final String? complexId;
  Future<(ComplexUnit, ResidentialComplex, double?)> _load() async {
    final repo = constructionRepository();
    if (complexId != null) {
      final result = await Future.wait<Object?>([
        repo.unit(id),
        repo.get(complexId!),
        repo.exchangeRate(),
      ]);
      final unit = result[0] as ComplexUnit;
      if (unit.complexId != complexId) {
        throw const AppException('Объект недоступен', statusCode: 404);
      }
      return (unit, result[1] as ResidentialComplex, result[2] as double?);
    }
    final unit = await repo.unit(id);
    final result = await Future.wait<Object?>([
      repo.get(unit.complexId),
      repo.exchangeRate(),
    ]);
    return (unit, result[0] as ResidentialComplex, result[1] as double?);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: KonushAppBar(
      title: context.tr('Объект в ЖК'),
      back: true,
      fallback: complexId == null
          ? '/complexes'
          : '/complexes/$complexId/units',
    ),
    body: ContentWidth(
      child: ConstructionLoad(
        key: ValueKey('unit-$id-$complexId'),
        load: _load,
        builder: (data) {
          final (unit, complex, rate) = data;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                unitTitle(context, unit.type, unit.rooms),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              TextButton(
                onPressed: () => openPage(context, '/complexes/${complex.id}'),
                child: Text(complex.name),
              ),
              Text(complex.address),
              const SizedBox(height: 12),
              ListingBadge(
                context.tr(saleStatuses[unit.saleStatus] ?? 'Свободно'),
                quiet: unit.saleStatus != 'available',
              ),
              if (unit.saleStatus != 'available')
                OutlinedButton(
                  onPressed: () => openPage(
                    context,
                    '/complexes/${complex.id}/units?sale_status=available',
                  ),
                  child: Text(context.tr('Посмотреть свободные')),
                ),
              const SizedBox(height: 12),
              PriceText(unit.price, rate: rate),
              if (unit.pricePerM2 != null)
                Text('${money(unit.pricePerM2!)} ${context.tr('сом/м²')}'),
              const SectionTitle('Характеристики'),
              Text('${context.tr('Площадь')}: ${unit.area} м²'),
              if (unit.floor != null)
                Text('${context.tr('Этаж')}: ${unit.floor}'),
              if (unit.building.isNotEmpty)
                Text('${context.tr('Корпус')}: ${unit.building}'),
              if (unit.number.isNotEmpty) Text('№ ${unit.number}'),
              if (finishingTypes.containsKey(unit.text('finishing')))
                Text(context.tr(finishingTypes[unit.text('finishing')]!)),
              if (unit.layout?.isNotEmpty == true) ...[
                const SectionTitle('Планировка'),
                SizedBox(
                  height: 280,
                  child: InkWell(
                    onTap: () => showConstructionImage(context, unit.layout!),
                    child: ListingImage(url: unit.layout),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ConstructionGallery(unit.photos),
              if (staleCatalog(complex, DateTime.now()))
                Notice(context.tr('Цены могут быть неактуальны')),
              FinancingSection(complex: complex, unit: unit),
              const SizedBox(height: 20),
              ContactButton(
                companyId: complex.companyId,
                targetType: 'unit',
                targetId: unit.id,
              ),
            ],
          );
        },
      ),
    ),
  );
}

class CompanyPage extends StatelessWidget {
  const CompanyPage({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: KonushAppBar(
      title: context.tr('Застройщик'),
      back: true,
      fallback: '/complexes',
    ),
    body: ContentWidth(
      child: ConstructionLoad<ConstructionCompany>(
        key: ValueKey('company-$id'),
        load: () => constructionRepository().company(id),
        builder: (company) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (company.text('cover_url').isNotEmpty)
              SizedBox(
                height: 180,
                child: ListingImage(url: company.text('cover_url')),
              ),
            if (company.text('logo_url').isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: 72,
                  width: 72,
                  child: ListingImage(url: company.text('logo_url')),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              company.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(company.text('description')),
            if (company.text('website').isNotEmpty)
              TextButton.icon(
                onPressed: () =>
                    openConstructionLink(context, company.text('website')),
                icon: const Icon(Icons.open_in_new),
                label: Text(context.tr('Сайт застройщика')),
              ),
            if (company.text('email').isNotEmpty)
              SelectableText(company.text('email')),
            ContactButton(companyId: id, targetType: 'company', targetId: id),
            const SectionTitle('Комплексы застройщика'),
            CompanyPortfolio(key: ObjectKey(company), companyId: id),
          ],
        ),
      ),
    ),
  );
}

class CompanyPortfolio extends StatefulWidget {
  const CompanyPortfolio({super.key, required this.companyId});
  final String companyId;
  @override
  State<CompanyPortfolio> createState() => _CompanyPortfolioState();
}

class _CompanyPortfolioState extends State<CompanyPortfolio> {
  final _repo = constructionRepository();
  final _items = <ResidentialComplex>[];
  int _page = 0;
  bool _next = true, _busy = false, _error = false;
  double? _rate;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = false;
    });
    try {
      final results = await Future.wait<Object?>([
        _repo.list(page: _page + 1, filters: {'company_id': widget.companyId}),
        _repo.exchangeRate(),
      ]);
      if (!mounted) return;
      final result = results[0] as PaginatedResult<ResidentialComplex>;
      setState(() {
        _items.addAll(result.items);
        _page = result.meta.page;
        _next = result.meta.hasNext;
        _rate = results[1] as double?;
      });
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final completed in [false, true]) ...[
        SectionTitle(completed ? 'Сданы' : 'Строятся'),
        for (final item in _items.where((c) => c.completed == completed))
          ComplexCard(item, rate: _rate),
      ],
      if (_items.isEmpty && !_busy && !_error)
        Text(context.tr('Жилых комплексов пока нет')),
      if (_error) Text(context.tr('Не удалось загрузить')),
      if (_busy)
        const Center(child: CircularProgressIndicator())
      else if (_next || _error)
        TextButton(
          onPressed: _load,
          child: Text(context.tr(_error ? 'Повторить' : 'Загрузить ещё')),
        ),
    ],
  );
}

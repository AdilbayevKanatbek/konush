import 'package:konush/l10n/source_messages.dart';
import 'package:flutter/material.dart';
import 'package:konush/src/features/complexes/presentation/complexes_page.dart';
import 'package:konush/src/features/listings/presentation/pages/listing_filters_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:konush/src/core/di/injection.dart';
import 'package:konush/src/core/ui/konush_ui.dart';
import 'package:konush/src/core/ui/open_street_map.dart';
import 'package:konush/src/features/listings/domain/listing.dart';
import 'package:konush/src/features/listings/domain/listing_filter.dart';
import 'package:konush/src/features/listings/presentation/cubit/listings_cubit.dart';
import 'package:konush/src/features/listings/presentation/cubit/favorites_cubit.dart';
export 'package:konush/src/core/ui/konush_ui.dart';

enum CatalogTab { buy, rent, newBuilds }

const _districts = <String, String>{
  '00000000-0000-0000-0000-0000000000d1': 'Джал',
  '00000000-0000-0000-0000-0000000000d2': 'Золотой квадрат',
  '00000000-0000-0000-0000-0000000000d3': 'Восток-5',
  '00000000-0000-0000-0000-0000000000d4': 'Кок-Жар',
  '00000000-0000-0000-0000-0000000000d5': 'Асанбай',
  '00000000-0000-0000-0000-0000000000d6': 'Эркиндик',
  '00000000-0000-0000-0000-0000000000d7': 'Магистраль',
};

class ListingsPage extends StatelessWidget {
  const ListingsPage({super.key, this.initialTab = CatalogTab.buy});
  final CatalogTab initialTab;
  @override
  Widget build(BuildContext context) => initialTab == CatalogTab.newBuilds
      ? const ComplexesPage()
      : BlocProvider(
          key: ValueKey(initialTab),
          create: (_) => sl<ListingsCubit>(),
          child: _CatalogView(initialTab: initialTab),
        );
}

class _CatalogView extends StatefulWidget {
  const _CatalogView({required this.initialTab});
  final CatalogTab initialTab;
  @override
  State<_CatalogView> createState() => _CatalogViewState();
}

class _CatalogViewState extends State<_CatalogView> {
  late CatalogTab _tab;
  final _search = TextEditingController();
  String _query = '';
  int? _rooms, _floorMin;
  String? _districtId;
  bool _showMap = false;
  final _priceFrom = TextEditingController(),
      _priceTo = TextEditingController();
  final _areaFrom = TextEditingController(), _areaTo = TextEditingController();
  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _load();
  }

  ListingFilter get _filter => ListingFilter(
    query: _query,
    dealType: _tab == CatalogTab.rent ? DealType.rent : DealType.sale,
    rooms: _rooms,
    districtId: _districtId,
    floorMin: _floorMin,
    priceMin: int.tryParse(_priceFrom.text),
    priceMax: int.tryParse(_priceTo.text),
    areaMin: double.tryParse(_areaFrom.text),
    areaMax: double.tryParse(_areaTo.text),
  );
  Future<void> _load() async {
    final cubit = context.read<ListingsCubit>();
    await cubit.load(_filter);
  }

  @override
  void dispose() {
    _search.dispose();
    _priceFrom.dispose();
    _priceTo.dispose();
    _areaFrom.dispose();
    _areaTo.dispose();
    super.dispose();
  }

  void _submitSearch() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _query = _search.text.trim());
    _load();
  }

  bool _filtersOpen = false;
  Future<void> _filters() async {
    if (_filtersOpen) return;
    _filtersOpen = true;
    try {
      final result = await showModalBottomSheet<ListingFilter>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.white,
        builder: (_) => ListingFiltersSheet(
          initial: _filter,
          districts: _districts,
          newBuild: _tab == CatalogTab.newBuilds,
        ),
      );
      if (!mounted || result == null) return;
      setState(() {
        _rooms = result.rooms;
        _districtId = result.districtId;
        _floorMin = result.floorMin;
        _priceFrom.text = result.priceMin?.toString() ?? '';
        _priceTo.text = result.priceMax?.toString() ?? '';
        _areaFrom.text = result.areaMin?.toString() ?? '';
        _areaTo.text = result.areaMax?.toString() ?? '';
      });
      await _load();
    } finally {
      _filtersOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: KonushAppBar(
      title: context.tr("Недвижимость"),
      back: true,
      actions: [
        IconButton(
          tooltip: context.tr("Фильтры"),
          onPressed: _filters,
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    ),
    body: Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
          child: ContentWidth(
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _submitSearch(),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: context.tr('Поиск по названию или адресу'),
                    prefixIcon: IconButton(
                      tooltip: context.tr('Найти'),
                      onPressed: _submitSearch,
                      icon: const Icon(Icons.search),
                    ),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: context.tr('Очистить поиск'),
                            onPressed: () {
                              _search.clear();
                              _submitSearch();
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: canvas,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    children: [
                      for (final tab in CatalogTab.values)
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              if (tab == CatalogTab.newBuilds) {
                                openPage(context, '/complexes');
                                return;
                              }
                              if (_tab == tab) return;
                              setState(() => _tab = tab);
                              _load();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              decoration: BoxDecoration(
                                color: _tab == tab
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: _tab == tab
                                    ? [
                                        const BoxShadow(
                                          color: Color(0x0A12211F),
                                          blurRadius: 4,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Text(
                                [
                                  context.tr("Купить"),
                                  context.tr("Арендовать"),
                                  context.tr("Новостройки"),
                                ][tab.index],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _tab == tab ? teal : muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _filters,
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: Text(
                          _districtId == null
                              ? context.tr("Фильтры")
                              : _districts[_districtId]!,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showMap = !_showMap),
                      icon: Icon(
                        _showMap
                            ? Icons.view_agenda_outlined
                            : Icons.map_outlined,
                        size: 18,
                      ),
                      label: Text(
                        _showMap ? context.tr("Список") : context.tr("Карта"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<ListingsCubit, ListingsState>(
            builder: (context, state) {
              if (state is ListingsLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ListingsFailure) {
                return SingleChildScrollView(
                  child: AppEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: context.tr("Не удалось загрузить"),
                    message: context.errorText(state.message),
                    action: FilledButton(
                      onPressed: _load,
                      child: Text(context.tr("Повторить")),
                    ),
                  ),
                );
              }
              final loaded = state as ListingsLoaded;
              if (loaded.items.isEmpty && !_showMap) {
                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      AppEmptyState(
                        icon: Icons.search_off_rounded,
                        title: context.tr("Пока ничего не нашли"),
                        message: context.tr(
                          "Попробуйте изменить район, цену или количество комнат.",
                        ),
                        action: OutlinedButton(
                          onPressed: _filters,
                          child: Text(context.tr("Изменить фильтры")),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  ContentWidth(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.tr("Объявлений: {arg0}", {
                                'arg0': loaded.meta.total,
                              }),
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (_tab == CatalogTab.newBuilds)
                            Text(
                              context.tr("Демо-каталог"),
                              style: TextStyle(color: muted, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: _showMap
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: ListingMap(items: loaded.items),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ContentWidth(
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  0,
                                  12,
                                  20,
                                ),
                                itemCount:
                                    loaded.items.length +
                                    (loaded.meta.hasNext ? 1 : 0),
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, i) => i < loaded.items.length
                                    ? ListingCard(item: loaded.items[i])
                                    : Column(
                                        children: [
                                          if (loaded.moreError != null)
                                            Notice(
                                              context.errorText(
                                                loaded.moreError,
                                              ),
                                            ),
                                          TextButton(
                                            onPressed: loaded.loadingMore
                                                ? null
                                                : context
                                                      .read<ListingsCubit>()
                                                      .loadMore,
                                            child: Text(
                                              context.tr(
                                                loaded.loadingMore
                                                    ? 'Загрузка…'
                                                    : 'Загрузить ещё',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.item,
    this.photoHeight,
    this.available = true,
  });
  final Listing item;
  final double? photoHeight;
  final bool available;
  @override
  Widget build(BuildContext context) {
    final newBuild = item.id.startsWith('new-build-');
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: !available || item.isPublic == false
            ? null
            : () => openPage(context, '/listings/${item.id}', extra: item),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      priceText(item, context: context),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.4,
                      ),
                    ),
                  ),
                  FavoriteButton(id: item.id),
                ],
              ),
              Text(
                newBuild ? item.title : listingSummary(context, item),
                maxLines: 2,
                style: const TextStyle(fontSize: 13, color: ink, height: 1.4),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: SizedBox(
                      width: 116,
                      height: 94,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ListingImage(url: item.photoUrl),
                          if (item.photos.length > 1)
                            Positioned(
                              right: 5,
                              bottom: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${item.photos.length}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.address.isEmpty ? item.city : item.address,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 12, height: 1.45),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.city,
                          style: const TextStyle(color: muted, fontSize: 11),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          item.agencyName ??
                              (item.seller == 'owner'
                                  ? context.tr("От собственника")
                                  : context.tr("Агентство")),
                          maxLines: 2,
                          style: const TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 5,
                children: [
                  if (item.isVip) const ListingBadge('VIP'),
                  if (!available || item.isPublic == false)
                    ListingBadge(
                      context.tr('Объявление больше недоступно'),
                      quiet: true,
                    ),
                  if (item.isTop) ListingBadge(context.tr("Топ")),
                  if (newBuild) ListingBadge(context.tr("Новостройка")),
                  if (item.status == ListingStatus.archived)
                    ListingBadge(context.tr("В архиве"), quiet: true),
                  if (item.status == ListingStatus.sold)
                    ListingBadge(context.tr("Продано"), quiet: true),
                  if (item.isNegotiable)
                    ListingBadge(context.tr("Возможен торг"), quiet: true),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    listingDate(item.createdAt),
                    style: const TextStyle(color: muted, fontSize: 10),
                  ),
                  const Spacer(),
                  const Icon(Icons.visibility_outlined, color: muted, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    '${item.viewsCount}',
                    style: const TextStyle(color: muted, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.id});
  final String id;
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<FavoritesCubit, FavoritesState>(
        buildWhen: (previous, current) =>
            previous.ids.contains(id) != current.ids.contains(id) ||
            previous.pending.contains(id) != current.pending.contains(id),
        builder: (context, state) => IconButton(
          tooltip: state.ids.contains(id)
              ? context.tr("Убрать из избранного")
              : context.tr("Добавить в избранное"),
          onPressed: state.pending.contains(id)
              ? null
              : () => context.read<FavoritesCubit>().toggle(id),
          icon: Icon(
            state.ids.contains(id)
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: state.ids.contains(id) ? teal : muted,
            size: 23,
          ),
        ),
      );
}

class ListingImage extends StatelessWidget {
  const ListingImage({super.key, this.url});
  final String? url;
  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(
      color: Color(0xFFEDF2EF),
      child: Center(
        child: Icon(
          Icons.apartment_rounded,
          size: 38,
          color: Color(0xFFB9CEC5),
        ),
      ),
    );
    return url == null
        ? placeholder
        : CachedNetworkImage(
            imageUrl: url!,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 180),
            placeholder: (_, _) => placeholder,
            errorWidget: (_, _, _) => placeholder,
          );
  }
}

class ListingBadge extends StatelessWidget {
  const ListingBadge(this.label, {super.key, this.quiet = false});
  final String label;
  final bool quiet;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: quiet ? canvas : tint,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        color: quiet ? muted : teal,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

String listingSummary(BuildContext context, Listing item) => [
  if (item.rooms != null) context.tr('{arg0}-комн.', {'arg0': item.rooms}),
  context.tr(switch (item.propertyType) {
    PropertyType.apartment => 'квартира',
    PropertyType.house => 'дом',
    PropertyType.commercial => 'коммерческая недвижимость',
    PropertyType.land => 'участок',
    PropertyType.garage => 'гараж',
  }),
  context.tr('{arg0} м²', {
    'arg0': item.area.toStringAsFixed(item.area % 1 == 0 ? 0 : 1),
  }),
  if (item.floor != null)
    context.tr('{arg0}/{arg1} этаж', {
      'arg0': item.floor,
      'arg1': item.totalFloors ?? '—',
    }),
].join(' · ');
String listingDate(DateTime date) => date.millisecondsSinceEpoch == 0
    ? ''
    : '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
String priceText(Listing item, {BuildContext? context}) {
  final grouped = (item.priceUsd ?? item.price).toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ' ',
  );
  final amount = item.priceUsd == null ? '$grouped сом' : '\$$grouped';
  return '$amount${item.id.startsWith('new-build-')
      ? '/м²'
      : item.dealType == DealType.rentDay
      ? (context?.tr('/сутки') ?? '/сутки')
      : item.dealType == DealType.rent
      ? (context?.tr('/мес') ?? '/мес')
      : ''}';
}

class ListingMap extends StatelessWidget {
  const ListingMap({super.key, required this.items});
  final List<Listing> items;
  @override
  Widget build(BuildContext context) {
    final located = items
        .where(
          (item) =>
              item.latitude.isFinite &&
              item.longitude.isFinite &&
              item.latitude.abs() <= 90 &&
              item.longitude.abs() <= 180 &&
              (item.latitude != 0 || item.longitude != 0),
        )
        .toList();
    final points = located
        .map((item) => LatLng(item.latitude, item.longitude))
        .toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: points.isEmpty
              ? const LatLng(42.8746, 74.5698)
              : points.first,
          initialZoom: points.length == 1 ? 13 : 11.5,
          maxZoom: 19,
          initialCameraFit: points.length > 1
              ? CameraFit.bounds(
                  bounds: LatLngBounds.fromPoints(points),
                  padding: const EdgeInsets.fromLTRB(70, 35, 70, 55),
                  maxZoom: 14,
                )
              : null,
        ),
        children: [
          const OpenStreetMapTiles(),
          MarkerLayer(
            markers: [
              for (final item in located)
                Marker(
                  point: LatLng(item.latitude, item.longitude),
                  width: 126,
                  height: 44,
                  child: GestureDetector(
                    key: ValueKey('map-listing-${item.id}'),
                    onTap: () =>
                        openPage(context, '/listings/${item.id}', extra: item),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: teal),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Color(0x2212211F), blurRadius: 8),
                          ],
                        ),
                        child: Text(
                          priceText(item),
                          maxLines: 1,
                          style: const TextStyle(
                            color: teal,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

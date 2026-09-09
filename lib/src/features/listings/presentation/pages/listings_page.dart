import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:konush/src/core/di/injection.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:konush/src/features/listings/domain/listing.dart';
import 'package:konush/src/features/listings/domain/listing_filter.dart';
import 'package:konush/src/features/listings/presentation/cubit/listings_cubit.dart';
import 'package:konush/src/features/listings/presentation/cubit/favorites_cubit.dart';
import 'package:latlong2/latlong.dart';

const ink = Color(0xFF12211F);
const muted = Color(0xFF8A9694);
const teal = Color(0xFF0E877A);
const tint = Color(0xFFE8F4F2);
const border = Color(0xFFE2E6E2);

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

String _catalogPath(String label) => switch (label) {
  'Аренда' => '/listings?tab=rent',
  'Новостройки' => '/listings?tab=new',
  'ЖК' => '/complexes',
  _ => '/listings',
};

class ListingsPage extends StatelessWidget {
  const ListingsPage({super.key, this.initialTab = CatalogTab.buy});

  final CatalogTab initialTab;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) {
      final cubit = sl<ListingsCubit>();
      if (initialTab == CatalogTab.newBuilds) {
        cubit.loadNewBuilds();
      } else {
        cubit.load(
          ListingFilter(
            dealType: initialTab == CatalogTab.rent
                ? DealType.rent
                : DealType.sale,
          ),
        );
      }
      return cubit;
    },
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
  int? _rooms;
  String? _districtId;
  int? _floorMin;
  bool _menuOpen = false;
  final _priceFrom = TextEditingController();
  final _priceTo = TextEditingController();
  final _areaFrom = TextEditingController();
  final _areaTo = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  ListingFilter get _filter => ListingFilter(
    dealType: _tab == CatalogTab.rent ? DealType.rent : DealType.sale,
    rooms: _rooms,
    districtId: _districtId,
    priceMin: int.tryParse(_priceFrom.text),
    priceMax: int.tryParse(_priceTo.text),
    areaMin: double.tryParse(_areaFrom.text),
    areaMax: double.tryParse(_areaTo.text),
    floorMin: _floorMin,
  );
  void _load() {
    FocusManager.instance.primaryFocus?.unfocus();
    final cubit = context.read<ListingsCubit>();
    if (_tab == CatalogTab.newBuilds) {
      cubit.loadNewBuilds(_filter);
    } else {
      cubit.load(_filter);
    }
  }

  void _toggleMenu() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _menuOpen = !_menuOpen);
  }

  @override
  void dispose() {
    _priceFrom.dispose();
    _priceTo.dispose();
    _areaFrom.dispose();
    _areaTo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_menuOpen,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && _menuOpen) setState(() => _menuOpen = false);
    },
    child: Scaffold(
      appBar: CatalogHeader(menuOpen: _menuOpen, onMenu: _toggleMenu),
      body: Column(
        children: [
          if (_menuOpen)
            MobileHeaderMenu(onClose: () => setState(() => _menuOpen = false)),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<ListingsCubit>().load(_filter),
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: _Filters(
                      tab: _tab,
                      rooms: _rooms,
                      districtId: _districtId,
                      floorMin: _floorMin,
                      priceFrom: _priceFrom,
                      priceTo: _priceTo,
                      areaFrom: _areaFrom,
                      areaTo: _areaTo,
                      onTab: (value) {
                        setState(() => _tab = value);
                        _load();
                      },
                      onRooms: (value) {
                        setState(() => _rooms = value);
                        _load();
                      },
                      onDistrict: (value) {
                        setState(() => _districtId = value);
                        _load();
                      },
                      onFloor: (value) {
                        setState(() => _floorMin = value);
                        _load();
                      },
                      onApply: _load,
                    ),
                  ),
                  BlocBuilder<ListingsCubit, ListingsState>(
                    builder: (context, state) => switch (state) {
                      ListingsLoading() => const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      ListingsFailure(:final message) => SliverFillRemaining(
                        child: _Failure(message: message, retry: _load),
                      ),
                      ListingsLoaded(:final items) when items.isEmpty =>
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _Empty(),
                        ),
                      ListingsLoaded(:final items) => SliverToBoxAdapter(
                        child: _Results(items: items),
                      ),
                    },
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

class CatalogHeader extends StatelessWidget implements PreferredSizeWidget {
  const CatalogHeader({super.key, this.onMenu, this.menuOpen = false});
  final VoidCallback? onMenu;
  final bool menuOpen;
  @override
  Size get preferredSize => const Size.fromHeight(64);
  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 900;
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: desktop ? 80 : 64,
      titleSpacing: desktop ? 28 : 16,
      title: const Logo(),
      actions: desktop
          ? [
              for (final label in [
                'Купить',
                'Аренда',
                'Новостройки',
                'ЖК',
                'Ипотека',
              ])
                TextButton(
                  onPressed: () => context.go(_catalogPath(label)),
                  child: Text(label, style: const TextStyle(color: ink)),
                ),
              BlocBuilder<FavoritesCubit, FavoritesState>(
                builder: (context, state) => TextButton.icon(
                  onPressed: () => context.go('/favorites'),
                  icon: const Icon(Icons.favorite_border, size: 18),
                  label: Text(
                    'Избранное${state.ids.isEmpty ? '' : ' (${state.ids.length})'}',
                  ),
                  style: TextButton.styleFrom(foregroundColor: ink),
                ),
              ),
              const SizedBox(width: 80),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) => TextButton(
                  onPressed: () => context.push(
                    state.status == AuthStatus.authenticated
                        ? '/profile'
                        : '/login',
                  ),
                  child: Text(
                    state.status == AuthStatus.authenticated
                        ? 'Кабинет'
                        : 'Войти',
                    style: const TextStyle(color: ink),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 28),
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Разместить объявление'),
                ),
              ),
            ]
          : [
              IconButton(
                onPressed: onMenu ?? () => _menu(context),
                icon: Icon(menuOpen ? Icons.close : Icons.menu),
              ),
            ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: border),
      ),
    );
  }

  static Future<void> _menu(BuildContext context) => showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Закрыть меню',
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (dialogContext, _, _) => Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: double.infinity,
          height: 414,
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 64,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(
                      children: [
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFFBFAF7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: border),
                Expanded(
                  child: ColoredBox(
                    color: const Color(0xFFFBFAF7),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final label in [
                            'Купить',
                            'Аренда',
                            'Новостройки',
                            'ЖК',
                            'Ипотека',
                          ])
                            InkWell(
                              onTap: () {
                                Navigator.pop(dialogContext);
                                context.go(_catalogPath(label));
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    color: Color(0xFF42504E),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          InkWell(
                            onTap: () {
                              Navigator.pop(dialogContext);
                              context.go('/favorites');
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 11),
                              child: Row(
                                children: [
                                  const Icon(Icons.favorite_border, size: 17),
                                  const SizedBox(width: 7),
                                  BlocBuilder<FavoritesCubit, FavoritesState>(
                                    builder: (_, state) => Text(
                                      'Избранное${state.ids.isEmpty ? '' : ' (${state.ids.length})'}',
                                      style: const TextStyle(
                                        color: Color(0xFF42504E),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Divider(height: 1, color: border),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.pop(dialogContext);
                                    context.push('/login');
                                  },
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 38),
                                    side: const BorderSide(color: border),
                                    foregroundColor: ink,
                                  ),
                                  child: const Text(
                                    'Войти',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () {},
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 38),
                                  ),
                                  child: const Text(
                                    'Разместить',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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

class MobileHeaderMenu extends StatelessWidget {
  const MobileHeaderMenu({super.key, this.onClose});
  final VoidCallback? onClose;

  void _navigate(BuildContext context, String path) {
    onClose?.call();
    context.go(path);
  }

  @override
  Widget build(BuildContext context) => Container(
    height: 350,
    color: const Color(0xFFFBFAF7),
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final label in [
          'Купить',
          'Аренда',
          'Новостройки',
          'ЖК',
          'Ипотека',
        ])
          InkWell(
            onTap: () => _navigate(context, _catalogPath(label)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Text(
                label,
                style: const TextStyle(color: Color(0xFF42504E), fontSize: 12),
              ),
            ),
          ),
        InkWell(
          onTap: () => _navigate(context, '/favorites'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              children: [
                const Icon(Icons.favorite_border, size: 17),
                const SizedBox(width: 7),
                BlocBuilder<FavoritesCubit, FavoritesState>(
                  builder: (_, state) => Text(
                    'Избранное${state.ids.isEmpty ? '' : ' (${state.ids.length})'}',
                    style: const TextStyle(
                      color: Color(0xFF42504E),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        const Divider(height: 1, color: border),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) => OutlinedButton(
                  onPressed: () {
                    onClose?.call();
                    context.push(
                      state.status == AuthStatus.authenticated
                          ? '/profile'
                          : '/login',
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    side: const BorderSide(color: border),
                    foregroundColor: ink,
                  ),
                  child: Text(
                    state.status == AuthStatus.authenticated
                        ? 'Кабинет'
                        : 'Войти',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(minimumSize: const Size(0, 38)),
                child: const Text(
                  'Разместить',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class Logo extends StatelessWidget {
  const Logo({super.key});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.go('/'),
    borderRadius: BorderRadius.circular(8),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: teal,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: Text(
                'K',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        Text(
          'konush',
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
      ],
    ),
  );
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.tab,
    required this.rooms,
    required this.districtId,
    required this.floorMin,
    required this.priceFrom,
    required this.priceTo,
    required this.areaFrom,
    required this.areaTo,
    required this.onTab,
    required this.onRooms,
    required this.onDistrict,
    required this.onFloor,
    required this.onApply,
  });
  final CatalogTab tab;
  final int? rooms;
  final String? districtId;
  final int? floorMin;
  final TextEditingController priceFrom, priceTo, areaFrom, areaTo;
  final ValueChanged<CatalogTab> onTab;
  final ValueChanged<int?> onRooms;
  final ValueChanged<String?> onDistrict;
  final ValueChanged<int?> onFloor;
  final VoidCallback onApply;
  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: mobile ? 12 : 32,
        vertical: mobile ? 10 : 18,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1460),
          child: mobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Segmented(tab: tab, onChanged: onTab),
                    const SizedBox(height: 8),
                    _roomsFilter(),
                    const SizedBox(height: 8),
                    _districtFilter(mobile: true),
                    const SizedBox(height: 8),
                    _Range(
                      label: 'Цена \$',
                      from: priceFrom,
                      to: priceTo,
                      onDone: onApply,
                    ),
                    const SizedBox(height: 8),
                    _Range(
                      label: 'Площадь м²',
                      from: areaFrom,
                      to: areaTo,
                      onDone: onApply,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _floorFilter(mobile: true),
                        const Spacer(),
                        _resultCount(),
                      ],
                    ),
                  ],
                )
              : Wrap(
                  spacing: 18,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Segmented(tab: tab, onChanged: onTab),
                    _roomsFilter(),
                    _districtFilter(mobile: false),
                    _Range(
                      label: 'Цена \$',
                      from: priceFrom,
                      to: priceTo,
                      onDone: onApply,
                    ),
                    _Range(
                      label: 'Площадь м²',
                      from: areaFrom,
                      to: areaTo,
                      onDone: onApply,
                    ),
                    _floorFilter(mobile: false),
                    _resultCount(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _roomsFilter() => _Labeled(
    label: 'Комнат',
    child: Wrap(
      spacing: 5,
      children: [
        _Chip(
          label: 'Любое',
          active: rooms == null,
          onTap: () => onRooms(null),
        ),
        for (final room in [1, 2, 3, 4])
          _Chip(
            label: room == 4 ? '4+' : '$room',
            active: rooms == room,
            onTap: () => onRooms(room),
          ),
      ],
    ),
  );

  Widget _districtFilter({required bool mobile}) => _Labeled(
    label: 'Район',
    child: _Select<String>(
      value: districtId,
      width: mobile ? 160 : 194,
      items: [
        const DropdownMenuItem(value: null, child: Text('Все районы')),
        for (final entry in _districts.entries)
          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      ],
      onChanged: onDistrict,
    ),
  );

  Widget _floorFilter({required bool mobile}) => _Labeled(
    label: 'Этаж',
    child: _Select<int>(
      value: floorMin,
      width: mobile ? 120 : 150,
      items: const [
        DropdownMenuItem(value: null, child: Text('Любой')),
        DropdownMenuItem(value: 2, child: Text('Не первый')),
        DropdownMenuItem(value: 5, child: Text('5+')),
        DropdownMenuItem(value: 10, child: Text('10+')),
      ],
      onChanged: onFloor,
    ),
  );

  Widget _resultCount() => BlocBuilder<ListingsCubit, ListingsState>(
    builder: (_, state) {
      final count = state is ListingsLoaded ? state.meta.total : 0;
      return Text(
        '$count объявлений',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
      );
    },
  );
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.tab, required this.onChanged});
  final CatalogTab tab;
  final ValueChanged<CatalogTab> onChanged;
  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    final tabs = [
      _tab('Купить', CatalogTab.buy, compact: mobile),
      _tab('Аренда', CatalogTab.rent, compact: mobile),
      _tab('Новостройки', CatalogTab.newBuilds, compact: mobile),
    ];
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F0),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: tabs),
    );
  }

  Widget _tab(String text, CatalogTab value, {bool compact = false}) => InkWell(
    onTap: () => onChanged(value),
    borderRadius: BorderRadius.circular(22),
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 18,
        vertical: compact ? 8 : 11,
      ),
      decoration: BoxDecoration(
        color: tab == value ? tint : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: compact ? 12 : 14,
          color: tab == value ? teal : const Color(0xFF50605D),
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(label, style: const TextStyle(color: muted, fontSize: 12)),
      const SizedBox(width: 6),
      child,
    ],
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(99),
    child: Container(
      constraints: const BoxConstraints(minWidth: 34),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? teal : Colors.white,
        border: Border.all(color: active ? teal : border),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: active ? Colors.white : ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _Select<T> extends StatelessWidget {
  const _Select({
    required this.value,
    required this.items,
    required this.onChanged,
    this.width = 194,
  });
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    final selected = items.firstWhere((item) => item.value == value);
    final height = MediaQuery.sizeOf(context).width < 700 ? 36.0 : 46.0;
    return ScrollbarTheme(
      data: const ScrollbarThemeData(
        thumbVisibility: WidgetStatePropertyAll(false),
        trackVisibility: WidgetStatePropertyAll(false),
        thickness: WidgetStatePropertyAll(0),
      ),
      child: MenuAnchor(
        alignmentOffset: const Offset(0, 6),
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.white),
          elevation: const WidgetStatePropertyAll(8),
          shadowColor: const WidgetStatePropertyAll(Color(0x3512211F)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 6),
          ),
          minimumSize: WidgetStatePropertyAll(Size(width, 0)),
          maximumSize: WidgetStatePropertyAll(Size(width, 280)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        menuChildren: [
          for (final item in items)
            MenuItemButton(
              onPressed: () => onChanged(item.value),
              style: ButtonStyle(
                minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 12),
                ),
                foregroundColor: const WidgetStatePropertyAll(ink),
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(fontSize: 12),
                ),
                overlayColor: const WidgetStatePropertyAll(tint),
              ),
              child: Row(
                children: [
                  Expanded(child: item.child),
                  if (item.value == value)
                    const Icon(Icons.check_rounded, size: 17, color: teal),
                ],
              ),
            ),
        ],
        builder: (context, controller, _) => Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () =>
                controller.isOpen ? controller.close() : controller.open(),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: width,
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: controller.isOpen ? teal : border),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DefaultTextStyle(
                      style: const TextStyle(color: ink, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: selected.child,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    controller.isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: const Color(0xFF52615F),
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

class _Range extends StatelessWidget {
  const _Range({
    required this.label,
    required this.from,
    required this.to,
    required this.onDone,
  });
  final String label;
  final TextEditingController from, to;
  final VoidCallback onDone;
  @override
  Widget build(BuildContext context) => _Labeled(
    label: label,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _field(context, from, 'от'),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 5),
          child: Text('–', style: TextStyle(color: muted)),
        ),
        _field(context, to, 'до'),
      ],
    ),
  );
  Widget _field(
    BuildContext context,
    TextEditingController controller,
    String hint,
  ) => SizedBox(
    width: MediaQuery.sizeOf(context).width < 700 ? 64 : 120,
    height: MediaQuery.sizeOf(context).width < 700 ? 36 : 46,
    child: TextField(
      controller: controller,
      style: const TextStyle(fontSize: 12, color: ink),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: hint == 'до'
          ? TextInputAction.done
          : TextInputAction.next,
      onSubmitted: (_) {
        if (hint == 'до') onDone();
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: teal),
        ),
      ),
    ),
  );
}

class _Results extends StatefulWidget {
  const _Results({required this.items});
  final List<Listing> items;

  @override
  State<_Results> createState() => _ResultsState();
}

class _ResultsState extends State<_Results> {
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 1000;
    final items = widget.items;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1504),
        child: Padding(
          padding: EdgeInsets.all(desktop ? 26 : 14),
          child: desktop
              ? SizedBox(
                  height: 650,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.3,
                                crossAxisSpacing: 18,
                                mainAxisSpacing: 18,
                              ),
                          itemCount: items.length.clamp(0, 4),
                          itemBuilder: (_, i) => ListingCard(item: items[i]),
                        ),
                      ),
                      const SizedBox(width: 26),
                      Expanded(child: _MapPanel(items: items)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _MobileViewSwitch(
                      showMap: _showMap,
                      onChanged: (value) => setState(() => _showMap = value),
                    ),
                    const SizedBox(height: 14),
                    if (_showMap)
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.62,
                        child: _MapPanel(items: items),
                      )
                    else
                      for (final item in items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: SizedBox(
                            height: 420,
                            child: ListingCard(item: item),
                          ),
                        ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _MobileViewSwitch extends StatelessWidget {
  const _MobileViewSwitch({required this.showMap, required this.onChanged});

  final bool showMap;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F3F0),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Expanded(
          child: _MobileViewButton(
            label: 'Список',
            icon: Icons.view_agenda_outlined,
            selected: !showMap,
            onTap: () => onChanged(false),
          ),
        ),
        Expanded(
          child: _MobileViewButton(
            label: 'Карта',
            icon: Icons.map_outlined,
            selected: showMap,
            onTap: () => onChanged(true),
          ),
        ),
      ],
    ),
  );
}

class _MobileViewButton extends StatelessWidget {
  const _MobileViewButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? Colors.white : Colors.transparent,
    borderRadius: BorderRadius.circular(11),
    elevation: selected ? 1 : 0,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? teal : muted),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected ? ink : muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.item, this.photoHeight});
  final Listing item;
  final double? photoHeight;
  @override
  Widget build(BuildContext context) {
    final newBuild = item.id.startsWith('new-build-');
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/listings/${item.id}', extra: item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photoHeight == null)
              Expanded(child: _photo())
            else
              SizedBox(height: photoHeight, child: _photo()),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    priceText(item),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    newBuild
                        ? '${item.title} · сдача в ${item.year}'
                        : [
                            if (item.rooms != null) '${item.rooms}-комн.',
                            '${item.area.toStringAsFixed(0)} м²',
                            if (item.floor != null)
                              '${item.floor}/${item.totalFloors ?? '?'} эт',
                          ].join(' · '),
                    style: const TextStyle(
                      color: Color(0xFF43514F),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                          item.address,
                          if (!item.address.toLowerCase().contains(
                            item.city.toLowerCase(),
                          ))
                            item.city,
                          item.agencyName ??
                              (item.seller == 'owner'
                                  ? 'От собственника'
                                  : null),
                        ]
                        .whereType<String>()
                        .where((e) => e.isNotEmpty)
                        .join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photo() => Stack(
    fit: StackFit.expand,
    children: [
      item.photoUrl == null
          ? const ColoredBox(
              color: Colors.white,
              child: Center(
                child: Text('фото', style: TextStyle(color: Color(0xFFC7CBC9))),
              ),
            )
          : CachedNetworkImage(
              imageUrl: item.photoUrl!,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 180),
              fadeOutDuration: const Duration(milliseconds: 80),
              placeholder: (_, _) => const ColoredBox(color: Color(0xFFF6F7F5)),
              errorWidget: (_, _, _) => const Center(child: Text('фото')),
            ),
      if (item.isVip || item.isTop)
        Positioned(
          left: 10,
          top: 10,
          child: _Badge(text: item.isVip ? 'VIP' : 'Топ', gold: item.isVip),
        ),
      Positioned(
        right: 8,
        top: 8,
        child: BlocBuilder<FavoritesCubit, FavoritesState>(
          buildWhen: (previous, current) =>
              previous.ids.contains(item.id) != current.ids.contains(item.id),
          builder: (context, state) {
            final favorite = state.ids.contains(item.id);
            return IconButton.filled(
              tooltip: favorite
                  ? 'Убрать из избранного'
                  : 'Добавить в избранное',
              onPressed: () => context.read<FavoritesCubit>().toggle(item.id),
              icon: Icon(
                favorite ? Icons.favorite : Icons.favorite_border,
                size: 18,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: favorite ? const Color(0xFFD3483E) : ink,
              ),
            );
          },
        ),
      ),
    ],
  );
}

String priceText(Listing item) {
  final value = item.priceUsd ?? item.price;
  final grouped = value.round().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${item.priceUsd != null ? '\$' : ''}$grouped${item.id.startsWith('new-build-')
      ? '/м²'
      : item.dealType.isRent
      ? '/мес'
      : item.priceUsd == null
      ? ' сом'
      : ''}';
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.gold});
  final String text;
  final bool gold;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: gold ? const Color(0xFFB98210) : ink,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    ),
  );
}

class _MapPanel extends StatelessWidget {
  const _MapPanel({required this.items});
  final List<Listing> items;
  static const _token = String.fromEnvironment('ACCESS_TOKEN');

  @override
  Widget build(BuildContext context) {
    final markers = items
        .where(
          (item) =>
              item.latitude.abs() <= 90 &&
              item.longitude.abs() <= 180 &&
              (item.latitude != 0 || item.longitude != 0),
        )
        .map(
          (item) => Marker(
            point: LatLng(item.latitude, item.longitude),
            width: 112,
            height: 44,
            child: GestureDetector(
              onTap: () => context.push('/listings/${item.id}', extra: item),
              child: Center(
                child: Material(
                  elevation: 3,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    child: Text(
                      priceText(item),
                      maxLines: 1,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
        .toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(42.8746, 74.5698),
          initialZoom: 11.5,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://api.mapbox.com/styles/v1/mapbox/light-v11/tiles/256/{z}/{x}/{y}@2x?access_token=$_token',
            userAgentPackageName: 'kg.konush.mobile',
          ),
          MarkerLayer(markers: markers),
          const RichAttributionWidget(
            attributions: [
              TextSourceAttribution('Mapbox'),
              TextSourceAttribution('OpenStreetMap'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 46, color: muted),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: retry, child: const Text('Повторить')),
        ],
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_outlined, size: 52, color: muted),
          SizedBox(height: 16),
          Text(
            'Ничего не найдено по этим фильтрам',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          SizedBox(height: 7),
          Text('Попробуйте смягчить условия', style: TextStyle(color: muted)),
        ],
      ),
    ),
  );
}

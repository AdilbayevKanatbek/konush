import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:konush/src/core/di/injection.dart';
import 'package:konush/src/features/listings/domain/listing.dart';
import 'package:konush/src/features/listings/domain/listing_filter.dart';
import 'package:konush/src/features/listings/presentation/cubit/listings_cubit.dart';
import 'package:konush/src/features/listings/presentation/pages/listings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<ListingsCubit>()..load(const ListingFilter(perPage: 8)),
    child: const _HomeView(),
  );
}

class _HomeView extends StatefulWidget {
  const _HomeView();
  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  DealType _deal = DealType.sale;
  bool _newBuilds = false;
  bool _menuOpen = false;
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _openCatalog() {
    FocusManager.instance.primaryFocus?.unfocus();
    context.go(
      _newBuilds
          ? '/listings?tab=new'
          : _deal == DealType.rent
          ? '/listings?tab=rent'
          : '/listings',
    );
  }

  void _toggleMenu() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _menuOpen = !_menuOpen);
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 700;
    return PopScope(
      canPop: !_menuOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _menuOpen) setState(() => _menuOpen = false);
      },
      child: Scaffold(
        appBar: CatalogHeader(onMenu: _toggleMenu, menuOpen: _menuOpen),
        body: Column(
          children: [
            if (_menuOpen)
              MobileHeaderMenu(
                onClose: () => setState(() => _menuOpen = false),
              ),
            Expanded(
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        mobile ? 64 : 80,
                        16,
                        mobile ? 56 : 64,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFF2F7F4), Color(0xFFFBFAF7)],
                        ),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 850),
                          child: Column(
                            children: [
                              Text(
                                'Вся недвижимость Кыргызстана. Один поиск.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ink,
                                  fontSize: mobile ? 36 : 52,
                                  height: 1.08,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: mobile ? -1.08 : -1.56,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Объявления от агентств, застройщиков и собственников — обновляются ежечасно.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF5A6967),
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                              SizedBox(height: mobile ? 32 : 36),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(19),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x2412211F),
                                      blurRadius: 28,
                                      offset: Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _HomeTab(
                                            label: 'Купить',
                                            selected:
                                                !_newBuilds &&
                                                _deal == DealType.sale,
                                            onTap: () => setState(() {
                                              _newBuilds = false;
                                              _deal = DealType.sale;
                                            }),
                                          ),
                                          _HomeTab(
                                            label: 'Аренда',
                                            selected:
                                                !_newBuilds &&
                                                _deal == DealType.rent,
                                            onTap: () => setState(() {
                                              _newBuilds = false;
                                              _deal = DealType.rent;
                                            }),
                                          ),
                                          _HomeTab(
                                            label: 'Новостройки',
                                            selected: _newBuilds,
                                            onTap: () => setState(
                                              () => _newBuilds = true,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _query,
                                            onSubmitted: (_) => _openCatalog(),
                                            decoration: const InputDecoration(
                                              hintText:
                                                  'Например: 3-комн в Джале до \$90k',
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              hintStyle: TextStyle(
                                                fontSize: 14,
                                                color: muted,
                                              ),
                                            ),
                                          ),
                                        ),
                                        FilledButton(
                                          onPressed: _openCatalog,
                                          style: FilledButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text(
                                            'Найти',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  for (final label in [
                                    'Бишкек · Джал',
                                    'Золотой квадрат',
                                    'Эркиндик',
                                    'Восток-5',
                                  ])
                                    ActionChip(
                                      label: Text(label),
                                      onPressed: _openCatalog,
                                      backgroundColor: Colors.white,
                                      elevation: 3,
                                      pressElevation: 1,
                                      shadowColor: const Color(0x2612211F),
                                      surfaceTintColor: Colors.white,
                                      side: const BorderSide(color: border),
                                      shape: const StadiumBorder(),
                                      labelStyle: const TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFF485654),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Свежее на Konush',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: ink,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _openCatalog,
                            child: const Text('Все объявления →'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  BlocBuilder<ListingsCubit, ListingsState>(
                    builder: (context, state) => switch (state) {
                      ListingsLoaded(:final items) => SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverLayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.crossAxisExtent >= 1000
                                ? 4
                                : constraints.crossAxisExtent >= 650
                                ? 2
                                : 1;
                            return SliverGrid.builder(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisExtent: columns == 1 ? 240 : null,
                                    childAspectRatio: columns == 1
                                        ? 1.48
                                        : 1.05,
                                    crossAxisSpacing: 18,
                                    mainAxisSpacing: 18,
                                  ),
                              itemCount: items.take(8).length,
                              itemBuilder: (_, i) =>
                                  ListingCard(item: items[i], photoHeight: 132),
                            );
                          },
                        ),
                      ),
                      ListingsFailure() => SliverToBoxAdapter(
                        child: Center(
                          child: TextButton(
                            onPressed: () =>
                                context.read<ListingsCubit>().load(),
                            child: const Text('Повторить загрузку'),
                          ),
                        ),
                      ),
                      _ => const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(50),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                    },
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(8, 34, 8, 48),
                    sliver: SliverToBoxAdapter(child: _MarketPanel()),
                  ),
                  const SliverToBoxAdapter(child: KonushFooter()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketPanel extends StatelessWidget {
  const _MarketPanel();
  static const values = [
    ('Золотой квадрат', 1350),
    ('Эркиндик', 1280),
    ('Магистраль', 1050),
    ('Джал', 980),
    ('Асанбай', 890),
    ('Восток-5', 760),
  ];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(18, 25, 18, 18),
    decoration: BoxDecoration(
      color: ink,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Рынок Бишкека',
          style: TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                'Средняя цена за м² по районам, продажа квартир',
                style: TextStyle(
                  color: Color(0x8CFFFFFF),
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
            Text(
              'демо-\nданные',
              textAlign: TextAlign.right,
              style: TextStyle(color: Color(0xFF7FB5AD), fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 20),
        for (final item in values)
          Padding(
            padding: const EdgeInsets.only(bottom: 13),
            child: Row(
              children: [
                Expanded(
                  flex: 10,
                  child: Text(
                    item.$1,
                    style: const TextStyle(
                      color: Color(0xB8FFFFFF),
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: SizedBox(
                      height: 7,
                      child: LayoutBuilder(
                        builder: (_, constraints) => Stack(
                          children: [
                            const Positioned.fill(
                              child: ColoredBox(color: Color(0xFF1F3834)),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: item.$2 / 1350,
                                child: const DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF249E91),
                                        Color(0xFF56D1C0),
                                      ],
                                    ),
                                  ),
                                  child: SizedBox.expand(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 5,
                  child: Text(
                    '\$${_groupThousands(item.$2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF4FD0BE),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  static String _groupThousands(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
}

class KonushFooter extends StatelessWidget {
  const KonushFooter({super.key});
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF0C2420),
    padding: const EdgeInsets.fromLTRB(16, 40, 16, 26),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: teal,
                borderRadius: BorderRadius.all(Radius.circular(7)),
              ),
              child: SizedBox(
                width: 24,
                height: 24,
                child: Center(
                  child: Text(
                    'K',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 9),
            Text(
              'konush',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        const Text(
          'Агрегатор недвижимости Кыргызстана. Конуш\n— место, где ставят юрту; место, с которого\nначинается дом.',
          style: TextStyle(
            color: Color(0xFF86AAA4),
            height: 1.55,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 27),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _FooterGroup(
                title: 'ПОКУПАТЕЛЯМ',
                links: [
                  'Купить квартиру',
                  'Снять квартиру',
                  'Дома и дачи',
                  'Коммерческая',
                  'Ипотечный калькулятор',
                ],
              ),
            ),
            Expanded(
              child: _FooterGroup(
                title: 'НОВОСТРОЙКИ',
                links: ['Жилые комплексы', 'От застройщика'],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _FooterGroup(
          title: 'KONUSH',
          links: ['Избранное', 'Разместить объявление', 'Войти'],
        ),
        const SizedBox(height: 34),
        const Divider(color: Color(0xFF18342F)),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: Text(
                '© 2026 Konush',
                style: TextStyle(color: Color(0xFF557C75), fontSize: 10),
              ),
            ),
            Text(
              'Кыргызстан',
              style: TextStyle(color: Color(0xFF557C75), fontSize: 10),
            ),
          ],
        ),
      ],
    ),
  );
}

class _FooterGroup extends StatelessWidget {
  const _FooterGroup({required this.title, required this.links});
  final String title;
  final List<String> links;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Color(0xFF53756F),
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
      const SizedBox(height: 10),
      for (final link in links)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            link,
            style: const TextStyle(color: Color(0xFFA1BCB7), fontSize: 12),
          ),
        ),
    ],
  );
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.label, this.selected = false, this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tab = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? tint : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? teal : const Color(0xFF465552),
          ),
          child: Text(label, maxLines: 1),
        ),
      ),
    );
    return tab;
  }
}

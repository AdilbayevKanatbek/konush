import 'package:konush/l10n/locale_cubit.dart';
import 'package:konush/l10n/source_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:konush/src/core/di/injection.dart';
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

class _HomeView extends StatelessWidget {
  const _HomeView();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: const KonushAppBar(
      title: 'Konush',
      brand: true,
      actions: [LanguageButton()],
    ),
    body: RefreshIndicator(
      onRefresh: () =>
          context.read<ListingsCubit>().load(const ListingFilter(perPage: 8)),
      child: ContentWidth(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr("Дом начинается здесь"),
                      style: TextStyle(
                        fontSize: 25,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.7,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      context.tr("Недвижимость в Кыргызстане"),
                      style: TextStyle(color: muted, fontSize: 13),
                    ),
                    const SizedBox(height: 22),
                    const _HomeCategories(),
                    const SizedBox(height: 22),
                    const _HomeShortcuts(),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SectionLabel(
                context.tr("Свежие объявления"),
                trailing: TextButton(
                  onPressed: () => openPage(context, '/listings'),
                  child: Text(
                    context.tr("Все"),
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
            BlocBuilder<ListingsCubit, ListingsState>(
              builder: (context, state) {
                if (state is ListingsLoading) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                if (state is ListingsFailure) {
                  return SliverToBoxAdapter(
                    child: AppEmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: context.tr("Объявления не загрузились"),
                      message: context.errorText(state.message),
                      action: OutlinedButton(
                        onPressed: () => context.read<ListingsCubit>().load(
                          const ListingFilter(perPage: 8),
                        ),
                        child: Text(context.tr("Повторить")),
                      ),
                    ),
                  );
                }
                final items = (state as ListingsLoaded).items.take(8).toList();
                if (items.isEmpty) {
                  return SliverToBoxAdapter(
                    child: AppEmptyState(
                      icon: Icons.home_outlined,
                      title: context.tr("Здесь появятся новые объекты"),
                      message: context.tr(
                        "Объявлений пока нет. Загляните позже.",
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => ListingCard(item: items[i]),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: KonushFooter()),
          ],
        ),
      ),
    ),
  );
}

bool _needsWideTiles(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 380 &&
    MediaQuery.textScalerOf(context).scale(14) > 17;

class _HomeCategories extends StatelessWidget {
  const _HomeCategories();
  @override
  Widget build(BuildContext context) {
    final stacked = _needsWideTiles(context);
    final buy = _CategoryTile(
      title: context.tr("Купить"),
      subtitle: context.tr("Своя история"),
      icon: Icons.key_rounded,
      onTap: () => openPage(context, '/listings'),
    );
    final rent = _CategoryTile(
      title: context.tr("Арендовать"),
      subtitle: context.tr("Своё пространство"),
      icon: Icons.chair_rounded,
      onTap: () => openPage(context, '/listings?tab=rent'),
    );
    final builds = _CategoryTile(
      title: context.tr("Новостройки"),
      subtitle: context.tr("Новые возможности"),
      icon: Icons.apartment_rounded,
      tall: !stacked,
      onTap: () => openPage(context, '/listings?tab=new'),
    );
    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final tile in [buy, rent, builds])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(height: 84, child: tile),
            ),
        ],
      );
    }
    return SizedBox(
      height: 190,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: buy),
                const SizedBox(height: 10),
                Expanded(child: rent),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: builds),
        ],
      ),
    );
  }
}

class _HomeShortcuts extends StatelessWidget {
  const _HomeShortcuts();
  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _Shortcut(
        context.tr("Жилые\nкомплексы"),
        Icons.apartment_outlined,
        () => openPage(context, '/complexes'),
      ),
      _Shortcut(
        context.tr("Избранное"),
        Icons.favorite_border_rounded,
        () => context.go('/favorites'),
      ),
      _Shortcut(
        context.tr("Мои\nобъявления"),
        Icons.home_work_outlined,
        () => openPage(context, '/my-listings'),
      ),
      _Shortcut(
        context.tr("Помощь"),
        Icons.help_outline_rounded,
        () => openPage(context, '/support'),
      ),
    ];
    if (_needsWideTiles(context)) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: tiles.take(2).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: tiles.skip(2).toList(),
          ),
        ],
      );
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: tiles);
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.tall = false,
  });
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool tall;
  @override
  Widget build(BuildContext context) => Material(
    color: tall ? tint : canvas,
    borderRadius: BorderRadius.circular(14),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -22,
            child: Container(
              width: tall ? 150 : 85,
              height: tall ? 150 : 85,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: teal.withValues(alpha: .055),
              ),
            ),
          ),
          if (tall)
            const Positioned(
              right: 3,
              bottom: 0,
              width: 135,
              height: 120,
              child: CustomPaint(painter: _BuildingsPainter()),
            )
          else
            Positioned(
              right: 9,
              bottom: 10,
              child: Transform.rotate(
                angle: -.14,
                child: Icon(icon, size: 45, color: const Color(0xFF6EA99A)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                if (tall)
                  Text(
                    subtitle,
                    style: const TextStyle(color: muted, fontSize: 10),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _BuildingsPainter extends CustomPainter {
  const _BuildingsPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    void block(double x, double y, double width, double height, Color color) {
      p.color = color;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, width, height),
          const Radius.circular(3),
        ),
        p,
      );
    }

    block(11, 49, 41, 71, const Color(0xFFC6DCD2));
    block(51, 11, 53, 109, const Color(0xFF8CB6A6));
    block(104, 33, 26, 87, const Color(0xFF5E9682));
    for (var row = 0; row < 5; row++) {
      for (var col = 0; col < 3; col++) {
        block(59 + col * 14.0, 24 + row * 17.0, 7, 9, const Color(0xFFF2F8F2));
      }
    }
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 2; col++) {
        block(19 + col * 15.0, 61 + row * 17.0, 7, 9, const Color(0xFFF5F9F4));
      }
    }
    block(67, 103, 18, 17, const Color(0xFF437C6B));
    p.color = const Color(0xFF397864);
    canvas.drawCircle(const Offset(26, 108), 12, p);
    p.color = const Color(0xFF669D7F);
    canvas.drawCircle(const Offset(15, 113), 9, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Shortcut extends StatelessWidget {
  const _Shortcut(this.label, this.icon, this.onTap);
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: canvas,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: teal, size: 23),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, height: 1.35, color: ink),
            ),
          ],
        ),
      ),
    ),
  );
}

class KonushFooter extends StatelessWidget {
  const KonushFooter({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 28, horizontal: 20),
    child: Text(
      context.tr("Konush · Недвижимость Кыргызстана"),
      textAlign: TextAlign.center,
      style: TextStyle(color: muted, fontSize: 11),
    ),
  );
}

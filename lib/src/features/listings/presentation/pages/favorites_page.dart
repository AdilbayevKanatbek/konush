import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konush/src/features/home/presentation/home_page.dart';
import 'package:konush/src/features/listings/presentation/cubit/favorites_cubit.dart';
import 'package:konush/src/features/listings/presentation/pages/listings_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();
    context.read<FavoritesCubit>().load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: CatalogHeader(
      menuOpen: _menuOpen,
      onMenu: () => setState(() => _menuOpen = !_menuOpen),
    ),
    body: Column(
      children: [
        if (_menuOpen)
          MobileHeaderMenu(onClose: () => setState(() => _menuOpen = false)),
        Expanded(
          child: BlocBuilder<FavoritesCubit, FavoritesState>(
            builder: (context, state) {
              if (state.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              return RefreshIndicator(
                onRefresh: context.read<FavoritesCubit>().load,
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 50, 18, 20),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Сохранённое',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${state.items.length} сохранено · '
                              'сообщим, когда цены изменятся.',
                              style: const TextStyle(
                                color: Color(0xFF657371),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (state.items.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.favorite_border,
                                  size: 52,
                                  color: muted,
                                ),
                                SizedBox(height: 14),
                                Text(
                                  'Здесь пока ничего нет',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Нажмите на сердце в карточке объявления',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: muted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
                        sliver: SliverLayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.crossAxisExtent >= 900
                                ? 3
                                : constraints.crossAxisExtent >= 600
                                ? 2
                                : 1;
                            return SliverGrid.builder(
                              itemCount: state.items.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisExtent: columns == 1 ? 240 : 300,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              itemBuilder: (_, index) => ListingCard(
                                item: state.items[index],
                                photoHeight: 132,
                              ),
                            );
                          },
                        ),
                      ),
                    const SliverToBoxAdapter(child: KonushFooter()),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

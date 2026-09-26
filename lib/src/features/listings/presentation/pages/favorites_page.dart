import 'package:konush/l10n/source_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konush/src/features/listings/domain/listing.dart';
import 'package:konush/src/features/listings/presentation/cubit/favorites_cubit.dart';
import 'package:konush/src/features/listings/presentation/pages/listings_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  int _filter = 0;
  @override
  void initState() {
    super.initState();
    context.read<FavoritesCubit>().load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: KonushAppBar(title: context.tr("Избранное")),
    body: Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: ContentWidth(
            child: Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: ChoiceChip(
                        label: Center(
                          child: Text(
                            [
                              context.tr("Все"),
                              context.tr("Покупка"),
                              context.tr("Аренда"),
                            ][i],
                            style: TextStyle(
                              fontSize: 12,
                              color: _filter == i ? teal : muted,
                            ),
                          ),
                        ),
                        selected: _filter == i,
                        showCheckmark: false,
                        selectedColor: tint,
                        backgroundColor: canvas,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onSelected: (_) => setState(() => _filter = i),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<FavoritesCubit, FavoritesState>(
            builder: (context, state) {
              if (state.loading && state.items.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = state.items
                  .where(
                    (item) =>
                        state.ids.contains(item.id) &&
                        (_filter == 0 ||
                            (_filter == 1
                                ? item.dealType == DealType.sale
                                : item.dealType.isRent)),
                  )
                  .toList();
              return RefreshIndicator(
                onRefresh: context.read<FavoritesCubit>().load,
                child: ContentWidth(
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    children: [
                      if (state.message != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            children: [
                              Notice(context.errorText(state.message)),
                              TextButton(
                                onPressed: state.loading
                                    ? null
                                    : context.read<FavoritesCubit>().load,
                                child: Text(context.tr("Повторить")),
                              ),
                            ],
                          ),
                        ),
                      if (items.isEmpty && state.unavailableIds.isEmpty)
                        AppEmptyState(
                          icon: Icons.favorite_border_rounded,
                          title: _filter == 0
                              ? context.tr("Сохраните то, что нравится")
                              : context.tr("В этой категории пока пусто"),
                          message: context.tr(
                            "Нажмите на сердце рядом с объявлением, чтобы вернуться к нему позже.",
                          ),
                          action: FilledButton(
                            onPressed: () => openPage(context, '/listings'),
                            child: Text(context.tr("Найти недвижимость")),
                          ),
                        )
                      else ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                          child: Text(
                            context.tr("{arg0} сохранено", {
                              'arg0': items.length,
                            }),
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                        ),
                        for (final item in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ListingCard(
                              item: item,
                              available: !state.unavailableIds.contains(
                                item.id,
                              ),
                            ),
                          ),
                      ],
                      if (_filter == 0)
                        for (final id in state.unavailableIds.where(
                          (id) =>
                              state.ids.contains(id) &&
                              !state.items.any((item) => item.id == id),
                        ))
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.hide_source_outlined),
                              title: Text(
                                context.tr('Объявление больше недоступно'),
                              ),
                              trailing: FavoriteButton(id: id),
                            ),
                          ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

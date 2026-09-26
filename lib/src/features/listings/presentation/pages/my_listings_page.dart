import 'package:konush/l10n/source_messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:konush/src/core/di/injection.dart';
import 'package:konush/src/core/ui/adaptive_dialog.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:konush/src/features/listings/domain/listing.dart';
import 'package:konush/src/features/listings/presentation/cubit/my_listings_cubit.dart';
import 'package:konush/src/features/listings/presentation/pages/listings_page.dart';

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    if (auth.status == AuthStatus.unknown ||
        auth.status == AuthStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (auth.user == null) {
      return Scaffold(
        appBar: KonushAppBar(
          title: context.tr('Мои объявления'),
          back: true,
          fallback: '/profile',
        ),
        body: SingleChildScrollView(
          child: AppEmptyState(
            icon: Icons.person_outline,
            title: context.tr('Войти в аккаунт'),
            message: context.tr(
              'Все ваши объекты и их статусы — в одном месте.',
            ),
            action: FilledButton(
              onPressed: () => openPage(context, '/login'),
              child: Text(context.tr('Войти')),
            ),
          ),
        ),
      );
    }
    return BlocProvider(
      create: (_) => sl<MyListingsCubit>()..load(),
      child: const _MyListingsView(),
    );
  }
}

class _MyListingsView extends StatelessWidget {
  const _MyListingsView();
  Future<void> _edit(BuildContext context, Listing item) async {
    await openPage<void>(context, '/my-listings/${item.id}/edit');
    if (context.mounted) await context.read<MyListingsCubit>().load();
  }

  Future<void> _delete(BuildContext context, Listing item) async {
    final confirmed = await showAdaptiveConfirmationDialog(
      context: context,
      title: context.tr("Удалить объявление?"),
      message: context.tr(
        "«{arg0}» будет удалено без возможности восстановления.",
        {'arg0': item.title},
      ),
      confirmLabel: context.tr("Удалить"),
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final cubit = context.read<MyListingsCubit>();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final ok = await cubit.delete(item.id);
    if (!context.mounted) return;
    final state = cubit.state;
    final message = ok
        ? context.tr('Объявление удалено')
        : '${context.tr('Не удалось удалить объявление')}. '
              '${context.errorText(state is MyListingsLoaded ? state.message : null)}';
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: Duration(seconds: ok ? 4 : 8),
          action: ok
              ? null
              : SnackBarAction(
                  label: context.tr('Повторить'),
                  onPressed: () {
                    if (context.mounted) _delete(context, item);
                  },
                ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: KonushAppBar(
      title: context.tr("Мои объявления"),
      back: true,
      fallback: '/profile',
      actions: [
        IconButton(
          tooltip: context.tr("Подать объявление"),
          onPressed: () => openPage(context, '/submit'),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    ),
    body: ContentWidth(
      child: BlocBuilder<MyListingsCubit, MyListingsState>(
        builder: (context, state) {
          if (state is MyListingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MyListingsFailure) {
            return SingleChildScrollView(
              child: AppEmptyState(
                icon: Icons.cloud_off_outlined,
                title: context.tr("Не удалось загрузить"),
                message: context.errorText(state.message),
                action: FilledButton(
                  onPressed: context.read<MyListingsCubit>().load,
                  child: Text(context.tr("Повторить")),
                ),
              ),
            );
          }
          final loaded = state as MyListingsLoaded;
          return RefreshIndicator(
            onRefresh: context.read<MyListingsCubit>().load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              children: [
                if (loaded.message != null)
                  Notice(context.errorText(loaded.message)),
                if (loaded.items.isEmpty)
                  AppEmptyState(
                    icon: Icons.home_work_outlined,
                    title: context.tr("Ваши объявления будут здесь"),
                    message: context.tr(
                      "Здесь можно следить за статусами, просмотрами и контактами по вашим объектам.",
                    ),
                    action: OutlinedButton(
                      onPressed: () => openPage(context, '/listings'),
                      child: Text(context.tr("Перейти к каталогу")),
                    ),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                    child: Text(
                      context.tr("Всего: {arg0}", {'arg0': loaded.total}),
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ),
                  for (final item in loaded.items)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ListingBadge(switch (item.status) {
                                ListingStatus.active => context.tr(
                                  "Опубликовано",
                                ),
                                ListingStatus.pending => context.tr(
                                  "На проверке",
                                ),
                                ListingStatus.rejected => context.tr(
                                  "Отклонено",
                                ),
                                ListingStatus.draft => context.tr("Черновик"),
                                ListingStatus.sold => context.tr("Продано"),
                                ListingStatus.archived => context.tr(
                                  "В архиве",
                                ),
                              }),
                              Text(
                                listingDate(item.createdAt),
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () => openPage(
                              context,
                              '/my-listings/${item.id}',
                              extra: item,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(9),
                                  child: SizedBox(
                                    width: 88,
                                    height: 84,
                                    child: ListingImage(url: item.photoUrl),
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        priceText(item, context: context),
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        item.city,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr("{arg0} просмотров · {arg1} контактов", {
                              'arg0': item.viewsCount,
                              'arg1': item.contactsCount,
                            }),
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                          if (item.status == ListingStatus.rejected &&
                              item.rejectReason?.isNotEmpty == true) ...[
                            const SizedBox(height: 12),
                            Notice(item.rejectReason!),
                          ],
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              OutlinedButton(
                                onPressed: () => openPage(
                                  context,
                                  '/my-listings/${item.id}',
                                  extra: item,
                                ),
                                child: Text(context.tr("Открыть")),
                              ),
                              if (item.canEdit)
                                FilledButton.icon(
                                  onPressed: loaded.deletingId == null
                                      ? () => _edit(context, item)
                                      : null,
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  label: Text(context.tr('Редактировать')),
                                ),
                              IconButton(
                                key: ValueKey('delete-${item.id}'),
                                tooltip: context.tr("Удалить объявление"),
                                onPressed: loaded.deletingId != null
                                    ? null
                                    : () => _delete(context, item),
                                icon: loaded.deletingId == item.id
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFC44949),
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    ),
  );
}

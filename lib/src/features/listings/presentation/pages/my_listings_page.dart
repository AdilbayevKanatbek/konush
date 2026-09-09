import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:konush/src/core/di/injection.dart';
import 'package:konush/src/core/ui/adaptive_dialog.dart';
import 'package:konush/src/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:konush/src/features/home/presentation/home_page.dart';
import 'package:konush/src/features/listings/domain/listing.dart';
import 'package:konush/src/features/listings/presentation/cubit/my_listings_cubit.dart';
import 'package:konush/src/features/listings/presentation/pages/listings_page.dart';

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.watch<AuthCubit>().state.status != AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return BlocProvider(
      create: (_) => sl<MyListingsCubit>()..load(),
      child: const _MyListingsView(),
    );
  }
}

class _MyListingsView extends StatefulWidget {
  const _MyListingsView();
  @override
  State<_MyListingsView> createState() => _MyListingsViewState();
}

class _MyListingsViewState extends State<_MyListingsView> {
  bool _menuOpen = false;

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
          child: BlocBuilder<MyListingsCubit, MyListingsState>(
            builder: (context, state) => switch (state) {
              MyListingsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              MyListingsFailure(:final message) => _Failure(
                message: message,
                retry: context.read<MyListingsCubit>().load,
              ),
              MyListingsLoaded(:final items, :final total, :final deletingId) =>
                RefreshIndicator(
                  onRefresh: context.read<MyListingsCubit>().load,
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 32, 18, 20),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Мои объявления',
                                  style: TextStyle(
                                    fontSize: 27,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Text(
                                '$total',
                                style: const TextStyle(
                                  color: muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (items.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _Empty(),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
                          sliver: SliverList.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) => _MyListingCard(
                              listing: items[index],
                              deleting: deletingId == items[index].id,
                              onDelete: () =>
                                  _confirmDelete(context, items[index]),
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(child: KonushFooter()),
                    ],
                  ),
                ),
            },
          ),
        ),
      ],
    ),
  );

  Future<void> _confirmDelete(BuildContext context, Listing listing) async {
    final confirmed = await showAdaptiveConfirmationDialog(
      context: context,
      title: 'Удалить объявление?',
      message:
          '«${listing.title}» будет удалено без возможности восстановления.',
      confirmLabel: 'Удалить',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final ok = await context.read<MyListingsCubit>().delete(listing.id);
    if (context.mounted && ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Объявление удалено')));
    }
  }
}

class _MyListingCard extends StatelessWidget {
  const _MyListingCard({
    required this.listing,
    required this.deleting,
    required this.onDelete,
  });
  final Listing listing;
  final bool deleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = _status(listing.status);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () =>
                      context.push('/listings/${listing.id}', extra: listing),
                  borderRadius: BorderRadius.circular(10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 100,
                      height: 76,
                      child: listing.photoUrl == null
                          ? const ColoredBox(
                              color: Color(0xFFDCE4E0),
                              child: Center(
                                child: Text(
                                  'фото',
                                  style: TextStyle(color: muted, fontSize: 11),
                                ),
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: listing.photoUrl!,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 7,
                        runSpacing: 5,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _StatusBadge(
                            label: status.$1,
                            color: status.$2,
                            background: status.$3,
                          ),
                          Text(
                            '${listing.viewsCount} просмотров · ${listing.contactsCount} контактов',
                            style: const TextStyle(
                              color: muted,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        priceText(listing),
                        style: const TextStyle(
                          color: teal,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (listing.status == ListingStatus.rejected &&
                listing.rejectReason?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Причина: ${listing.rejectReason}',
                  style: const TextStyle(
                    color: Color(0xFFB93831),
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      context.push('/listings/${listing.id}', extra: listing),
                  icon: const Icon(Icons.visibility_outlined, size: 17),
                  label: const Text('Открыть'),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Удалить',
                  onPressed: deleting ? null : onDelete,
                  color: const Color(0xFFD3483E),
                  icon: deleting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (String, Color, Color) _status(ListingStatus value) => switch (value) {
    ListingStatus.active => ('Опубликовано', teal, tint),
    ListingStatus.pending => (
      'На модерации',
      const Color(0xFF986B08),
      const Color(0xFFFFF4D8),
    ),
    ListingStatus.rejected => (
      'Отклонено',
      const Color(0xFFB93831),
      const Color(0xFFFFEEEE),
    ),
    ListingStatus.draft => (
      'Черновик',
      const Color(0xFF53615F),
      const Color(0xFFF1F3F0),
    ),
    ListingStatus.sold => (
      'Продано',
      const Color(0xFF53615F),
      const Color(0xFFF1F3F0),
    ),
    ListingStatus.archived => (
      'В архиве',
      const Color(0xFF53615F),
      const Color(0xFFF1F3F0),
    ),
  };
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.background,
  });
  final String label;
  final Color color;
  final Color background;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.home_work_outlined, size: 52, color: muted),
          const SizedBox(height: 14),
          const Text(
            'У вас пока нет объявлений',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Создание объявления добавим следующим этапом',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('На главную'),
          ),
        ],
      ),
    ),
  );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48, color: muted),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton(onPressed: retry, child: const Text('Повторить')),
        ],
      ),
    ),
  );
}

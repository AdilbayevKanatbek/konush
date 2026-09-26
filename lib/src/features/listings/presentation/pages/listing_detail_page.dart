import 'dart:async';
import 'package:konush/src/core/error/app_exception.dart';
import 'package:konush/l10n/source_messages.dart';
import 'package:konush/src/features/chat/presentation/chat_pages.dart';
import 'package:flutter/material.dart';
import 'package:konush/src/core/di/injection.dart';
import 'package:konush/src/features/listings/domain/listing.dart';
import 'package:konush/src/features/listings/domain/listings_repository.dart';
import 'package:konush/src/features/listings/presentation/pages/listings_page.dart';
import 'package:url_launcher/url_launcher.dart';

class ListingDetailPage extends StatefulWidget {
  const ListingDetailPage({
    super.key,
    required this.listingId,
    this.initialListing,
    this.owned = false,
  });
  final String listingId;
  final Listing? initialListing;
  final bool owned;
  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  late Future<Listing> _listing;
  @override
  void initState() {
    super.initState();
    _listing = _load();
  }

  Future<Listing> _load() => widget.owned
      ? sl<ListingsRepository>().getMyById(widget.listingId)
      : sl<ListingsRepository>().getById(widget.listingId);

  void _retry() => setState(() {
    _listing = _load();
  });
  Future<void> _edit() async {
    await openPage<void>(context, '/my-listings/${widget.listingId}/edit');
    if (mounted) _retry();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Listing>(
    future: _listing,
    builder: (context, snapshot) {
      final listing = snapshot.data;
      return Scaffold(
        backgroundColor: canvas,
        appBar: KonushAppBar(
          title: context.tr("Объявление"),
          back: true,
          fallback: widget.owned ? '/my-listings' : '/listings',
          actions: [
            if (listing != null && !widget.owned)
              FavoriteButton(id: listing.id),
          ],
        ),
        body: snapshot.connectionState != ConnectionState.done
            ? const Center(child: CircularProgressIndicator())
            : snapshot.hasError
            ? SingleChildScrollView(
                child: AppEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: context.tr("Не удалось загрузить объявление"),
                  message: context.tr(
                    snapshot.error is AppException &&
                            (snapshot.error as AppException).statusCode == 404
                        ? 'Объявление больше недоступно'
                        : 'Проверьте подключение и попробуйте ещё раз.',
                  ),
                  action: FilledButton(
                    onPressed: _retry,
                    child: Text(context.tr("Повторить")),
                  ),
                ),
              )
            : ContentWidth(
                child: ListView(
                  children: [
                    _Gallery(listing: listing!),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (widget.owned)
                                ListingBadge(
                                  context.tr(switch (listing.status) {
                                    ListingStatus.pending => 'На проверке',
                                    ListingStatus.rejected => 'Отклонено',
                                    ListingStatus.active => 'Опубликовано',
                                    ListingStatus.sold => 'Продано',
                                    ListingStatus.archived => 'В архиве',
                                    ListingStatus.draft => 'Черновик',
                                  }),
                                ),
                              if (listing.isVip) const ListingBadge('VIP'),
                              if (listing.isTop)
                                ListingBadge(context.tr("Топ")),
                              if (listing.id.startsWith('new-build-'))
                                ListingBadge(context.tr("Новостройка · демо")),
                              if (listing.isNegotiable)
                                ListingBadge(
                                  context.tr("Возможен торг"),
                                  quiet: true,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            priceText(listing, context: context),
                            style: const TextStyle(
                              fontSize: 29,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.9,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            listing.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: teal,
                                size: 19,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  [
                                    listing.address,
                                    listing.city,
                                  ].where((s) => s.isNotEmpty).join(', '),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: muted,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          LayoutBuilder(
                            builder: (context, constraints) => Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final fact in [
                                  (
                                    context.tr("Комнаты"),
                                    '${listing.rooms ?? '—'}',
                                    Icons.meeting_room_outlined,
                                  ),
                                  (
                                    context.tr("Площадь"),
                                    context.tr("{arg0} м²", {
                                      'arg0': listing.area.toStringAsFixed(0),
                                    }),
                                    Icons.square_foot_rounded,
                                  ),
                                  (
                                    context.tr("Этаж"),
                                    '${listing.floor ?? '—'}/${listing.totalFloors ?? '—'}',
                                    Icons.layers_outlined,
                                  ),
                                  (
                                    context.tr("Год постройки"),
                                    '${listing.year ?? '—'}',
                                    Icons.calendar_today_outlined,
                                  ),
                                ])
                                  SizedBox(
                                    width: (constraints.maxWidth - 8) / 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(13),
                                      decoration: BoxDecoration(
                                        color: canvas,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(fact.$3, color: muted, size: 19),
                                          const SizedBox(height: 10),
                                          Text(
                                            fact.$2,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            fact.$1,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr("Об объекте"),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            listing.description,
                            style: const TextStyle(fontSize: 14, height: 1.65),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            context.tr("Опубликовано {arg0}", {
                              'arg0': listingDate(listing.createdAt),
                            }),
                            style: const TextStyle(color: muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr("Продавец"),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: tint,
                                foregroundColor: teal,
                                child: Text(
                                  listing.agentName.isEmpty
                                      ? 'K'
                                      : listing.agentName.characters.first,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      listing.agentName.isEmpty
                                          ? context.tr("Продавец")
                                          : listing.agentName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      listing.agencyName ??
                                          context.tr("Собственник"),
                                      style: const TextStyle(
                                        color: muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
        bottomNavigationBar:
            listing == null || (widget.owned && !listing.canEdit)
            ? null
            : widget.owned
            ? SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: ContentWidth(
                    child: FilledButton.icon(
                      onPressed: _edit,
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(context.tr('Редактировать')),
                    ),
                  ),
                ),
              )
            : DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: border)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: ContentWidth(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ContactButton(listing: listing),
                          const SizedBox(height: 8),
                          ListingChatButton(listing: listing),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      );
    },
  );
}

class _Gallery extends StatefulWidget {
  const _Gallery({required this.listing});
  final Listing listing;
  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;
  @override
  Widget build(BuildContext context) {
    final photos = widget.listing.photos;
    return AspectRatio(
      aspectRatio: 1.35,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photos.isEmpty)
            const ListingImage()
          else
            PageView.builder(
              onPageChanged: (value) => setState(() => _page = value),
              itemCount: photos.length,
              itemBuilder: (_, i) => ListingImage(url: photos[i].url),
            ),
          if (photos.isNotEmpty)
            Positioned(
              right: 16,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x9912211F),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${_page + 1} / ${photos.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatefulWidget {
  const _ContactButton({required this.listing});
  final Listing listing;
  @override
  State<_ContactButton> createState() => _ContactButtonState();
}

class _ContactButtonState extends State<_ContactButton> {
  bool _recorded = false;
  bool _showing = false;

  Future<void> _showContact() async {
    if (_showing) return;
    _showing = true;
    if (!_recorded) {
      _recorded = true;
      try {
        unawaited(
          sl<ListingsRepository>()
              .recordContact(widget.listing.id)
              .catchError((_) {}),
        );
      } catch (_) {}
    }
    if (!mounted) {
      _showing = false;
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ContactSheet(listing: widget.listing),
    ).whenComplete(() => _showing = false);
  }

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: _showContact,
    child: Text(
      widget.listing.seller == 'owner'
          ? context.tr("Связаться с продавцом")
          : context.tr("Связаться с агентом"),
    ),
  );
}

class _ContactSheet extends StatelessWidget {
  const _ContactSheet({required this.listing});
  final Listing listing;

  String get _phone {
    final value = listing.contactPhone ?? '';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 12 || !digits.startsWith('996')) return value;
    return '+996 ${digits.substring(3, 6)} ${digits.substring(6, 9)} ${digits.substring(9)}';
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      18,
      20,
      20 + MediaQuery.viewPaddingOf(context).bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                listing.agentName.isEmpty
                    ? context.tr("Продавец")
                    : listing.agentName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        Text(
          context.tr("По объявлению: {arg0}-комн., {arg1} м² · {arg2}", {
            'arg0': listing.rooms ?? '—',
            'arg1': listing.area.toStringAsFixed(0),
            'arg2': priceText(listing, context: context),
          }),
          style: const TextStyle(color: muted, fontSize: 12.5),
        ),
        const SizedBox(height: 22),
        if (listing.contactPhone?.isNotEmpty == true) ...[
          Center(
            child: Text(
              _phone,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final uri = Uri(scheme: 'tel', path: listing.contactPhone);
                if (!await launchUrl(uri) && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.tr("Не удалось открыть приложение телефона"),
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.phone, size: 19),
              label: Text(context.tr("Позвонить")),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              context.tr("Скажите, что нашли объявление на Konush"),
              style: TextStyle(color: muted, fontSize: 11.5),
            ),
          ),
        ] else
          DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFF1F3F0),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Center(
                child: Text(
                  context.tr("Продавец не указал номер телефона"),
                  style: TextStyle(color: muted),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

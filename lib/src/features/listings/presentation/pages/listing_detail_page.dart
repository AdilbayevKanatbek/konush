import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:konush/src/core/di/injection.dart';
import 'package:konush/src/features/listings/domain/listing.dart';
import 'package:konush/src/features/listings/domain/listings_repository.dart';
import 'package:konush/src/features/listings/presentation/pages/listings_page.dart';
import 'package:konush/src/features/listings/presentation/cubit/favorites_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

class ListingDetailPage extends StatefulWidget {
  const ListingDetailPage({
    super.key,
    required this.listingId,
    this.initialListing,
  });
  final String listingId;
  final Listing? initialListing;

  @override
  State<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends State<ListingDetailPage> {
  bool _menuOpen = false;
  late Future<Listing> _listing;

  @override
  void initState() {
    super.initState();
    _listing = widget.initialListing != null
        ? Future.value(widget.initialListing)
        : sl<ListingsRepository>().getById(widget.listingId);
  }

  void _retry() => setState(
    () => _listing = sl<ListingsRepository>().getById(widget.listingId),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<Listing>(
    future: _listing,
    builder: (context, snapshot) => PopScope(
      canPop: !_menuOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _menuOpen) setState(() => _menuOpen = false);
      },
      child: Scaffold(
        appBar: CatalogHeader(
          menuOpen: _menuOpen,
          onMenu: () {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _menuOpen = !_menuOpen);
          },
        ),
        body: snapshot.connectionState != ConnectionState.done
            ? const Center(child: CircularProgressIndicator())
            : snapshot.hasError
            ? _DetailFailure(onRetry: _retry)
            : _body(snapshot.requireData),
      ),
    ),
  );

  Widget _body(Listing listing) => Column(
    children: [
      if (_menuOpen)
        MobileHeaderMenu(onClose: () => setState(() => _menuOpen = false)),
      Expanded(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final desktop = constraints.maxWidth >= 850;
                    final content = [
                      _Main(listing: listing),
                      _Side(listing: listing),
                    ];
                    return desktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: content[0]),
                              const SizedBox(width: 24),
                              Expanded(child: content[1]),
                            ],
                          )
                        : Column(children: content);
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _DetailFailure extends StatelessWidget {
  const _DetailFailure({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: muted),
            const SizedBox(height: 12),
            const Text(
              'Не удалось загрузить объявление',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    ),
  );
}

class _Main extends StatelessWidget {
  const _Main({required this.listing});
  final Listing listing;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextButton.icon(
        onPressed: () => context.go('/listings'),
        icon: const Icon(Icons.arrow_back, size: 17),
        label: const Text('Назад к поиску'),
      ),
      const SizedBox(height: 10),
      AspectRatio(
        aspectRatio: 1.3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: listing.photoUrl == null
              ? const ColoredBox(
                  color: Color(0xFFD3E0DC),
                  child: Center(
                    child: Text('фото', style: TextStyle(color: muted)),
                  ),
                )
              : CachedNetworkImage(
                  imageUrl: listing.photoUrl!,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 180),
                  placeholder: (_, _) =>
                      const ColoredBox(color: Color(0xFFD3E0DC)),
                  errorWidget: (_, _, _) => const Center(
                    child: Icon(Icons.image_not_supported_outlined),
                  ),
                ),
        ),
      ),
      const SizedBox(height: 22),
      Text(
        priceText(listing),
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          color: ink,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '${listing.rooms ?? '—'}-комн. ${listing.propertyType == PropertyType.apartment ? 'квартира' : listing.propertyType.name}, ${listing.area.toStringAsFixed(0)} м²',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 7),
      Text(
        '${listing.address}, ${listing.city}',
        style: const TextStyle(color: muted),
      ),
      const SizedBox(height: 16),
      BlocBuilder<FavoritesCubit, FavoritesState>(
        buildWhen: (previous, current) =>
            previous.ids.contains(listing.id) !=
            current.ids.contains(listing.id),
        builder: (context, state) {
          final favorite = state.ids.contains(listing.id);
          return OutlinedButton.icon(
            onPressed: () => context.read<FavoritesCubit>().toggle(listing.id),
            icon: Icon(
              favorite ? Icons.favorite : Icons.favorite_border,
              size: 18,
            ),
            label: Text(favorite ? 'Сохранено' : 'Сохранить'),
          );
        },
      ),
      const SizedBox(height: 20),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 2.1,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          _Fact('КОМНАТ', '${listing.rooms ?? '—'}'),
          _Fact('ПЛОЩАДЬ', '${listing.area.toStringAsFixed(0)} м²'),
          _Fact(
            'ЭТАЖ',
            '${listing.floor ?? '—'}/${listing.totalFloors ?? '—'} эт',
          ),
          _Fact('ПОСТРОЕН', '${listing.year ?? '—'}'),
        ],
      ),
      const SizedBox(height: 25),
      const Text(
        'Об объекте',
        style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 10),
      Text(
        listing.description,
        style: const TextStyle(height: 1.55, color: Color(0xFF53615F)),
      ),
      const SizedBox(height: 28),
      const Text(
        'История цены, \$/м²',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
      const Text('демо-данные', style: TextStyle(color: muted, fontSize: 12)),
      const SizedBox(height: 20),
      SizedBox(
        height: 130,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    height: 55.0 + i * 9,
                    decoration: BoxDecoration(
                      color: i == 6 ? teal : const Color(0xFFE8ECE9),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(5),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: border),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    ),
  );
}

class _Side extends StatelessWidget {
  const _Side({required this.listing});
  final Listing listing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 45),
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
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
                              ? 'Продавец'
                              : listing.agentName,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          listing.agencyName ?? 'Собственник',
                          style: const TextStyle(color: muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _ContactButton(listing: listing),
              ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.chat_bubble_outline, size: 17),
                  label: const Text('Чат скоро появится'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ink,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ипотечный калькулятор',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 18),
              _LoanRow('Первый взнос', '30%'),
              Slider(value: .3, onChanged: null),
              _LoanRow('Срок', '15 лет'),
              Slider(value: .55, onChanged: null),
              _LoanRow('Ставка', '14%'),
              Slider(value: .45, onChanged: null),
              Divider(color: Color(0xFF29413D)),
              Text(
                'Платёж в месяц',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              SizedBox(height: 4),
              Text(
                '\$1,958',
                style: TextStyle(
                  color: Color(0xFF4CC2B2),
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ContactButton extends StatefulWidget {
  const _ContactButton({required this.listing});
  final Listing listing;
  @override
  State<_ContactButton> createState() => _ContactButtonState();
}

class _ContactButtonState extends State<_ContactButton> {
  bool _recorded = false;

  Future<void> _showContact() async {
    if (!_recorded) {
      _recorded = true;
      try {
        await sl<ListingsRepository>().recordContact(widget.listing.id);
      } catch (_) {}
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ContactSheet(listing: widget.listing),
    );
  }

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: _showContact,
    child: Text(
      widget.listing.seller == 'owner'
          ? 'Связаться с продавцом'
          : 'Связаться с агентом',
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
                listing.agentName.isEmpty ? 'Продавец' : listing.agentName,
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
          'По объявлению: ${listing.rooms ?? '—'}-комн., ${listing.area.toStringAsFixed(0)} м² · ${priceText(listing)}',
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
                    const SnackBar(
                      content: Text('Не удалось открыть приложение телефона'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.phone, size: 19),
              label: const Text('Позвонить'),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Скажите, что нашли объявление на Konush',
              style: TextStyle(color: muted, fontSize: 11.5),
            ),
          ),
        ] else
          const DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFF1F3F0),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Center(
                child: Text(
                  'Продавец не указал номер телефона',
                  style: TextStyle(color: muted),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _LoanRow extends StatelessWidget {
  const _LoanRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(label, style: const TextStyle(color: muted, fontSize: 12)),
      ),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    ],
  );
}

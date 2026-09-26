import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:konush/l10n/source_messages.dart';
import 'package:konush/src/core/di/injection.dart';
import 'package:konush/src/core/error/app_exception.dart';
import 'package:konush/src/core/network/api_client.dart';
import 'package:konush/src/core/ui/konush_ui.dart';
import 'package:konush/src/features/listings/presentation/pages/listings_page.dart'
    show ListingImage, ListingBadge;
import '../data/complex_repository.dart';
import '../domain/construction_rules.dart';
export 'package:konush/l10n/source_messages.dart';
export 'package:konush/src/core/ui/konush_ui.dart';
export '../data/complex_repository.dart';
export '../domain/construction_rules.dart';
export 'package:konush/src/features/listings/presentation/pages/listings_page.dart'
    show ListingImage, ListingBadge;

ComplexRepository constructionRepository() =>
    ComplexRepository(sl<ApiClient>());
String money(num value) =>
    NumberFormat.decimalPattern('ru').format(value.round());
String displayDate(DateTime value) =>
    DateFormat('dd.MM.yyyy').format(bishkekTime(value));
String unitTitle(BuildContext context, String type, int? rooms) {
  if (type == 'apartment' && rooms != null) {
    if (rooms == 0) return context.tr('Студия');
    return '$rooms ${context.tr('комн. квартира')}';
  }
  return context.tr(unitTypes[type] ?? 'Объект');
}

class PriceText extends StatelessWidget {
  const PriceText(
    this.price, {
    super.key,
    this.rate,
    this.prefix = '',
    this.small = false,
  });
  final int price;
  final double? rate;
  final String prefix;
  final bool small;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '${prefix.isEmpty ? '' : '$prefix '}${rate == null ? '${money(price)} ${context.tr('сом')}' : '\$${money(price / rate!)}'}',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: teal,
          fontSize: small ? 14 : 20,
        ),
      ),
      if (rate != null)
        Text(
          '${money(price)} ${context.tr('сом')}',
          style: const TextStyle(color: muted),
        ),
    ],
  );
}

class ComplexStatus extends StatelessWidget {
  const ComplexStatus(this.item, {super.key, this.now});
  final ResidentialComplex item;
  final DateTime? now;
  @override
  Widget build(BuildContext context) {
    final year = item.handoverYear;
    final quarter = item.handoverQuarter;
    final period =
        '${quarter == null ? '' : '${const ['I', 'II', 'III', 'IV'][(quarter - 1).clamp(0, 3)]} ${context.tr('кв.')} '}$year';
    final handover = item.completed
        ? context.tr('Сдан')
        : year == null
        ? context.tr('Срок сдачи не указан')
        : handoverOverdue(item, now ?? DateTime.now())
        ? '${context.tr('Срок сдачи прошёл')} ($period)'
        : period;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ListingBadge(handover),
        if (!item.completed && constructionStages.containsKey(item.stage))
          ListingBadge(
            context.tr(constructionStages[item.stage]!),
            quiet: true,
          ),
        if (item.readiness != null)
          ListingBadge(
            '${context.tr('Готовность')}: ${item.readiness}%',
            quiet: true,
          ),
      ],
    );
  }
}

class ComplexCard extends StatelessWidget {
  const ComplexCard(this.item, {super.key, this.rate});
  final ResidentialComplex item;
  final double? rate;
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => openPage(context, '/complexes/${item.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 170,
            child: ListingImage(url: item.photos.firstOrNull),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.titleLarge),
                if (item.company.isNotEmpty)
                  Text(item.company, style: const TextStyle(color: muted)),
                Text(item.address),
                const SizedBox(height: 12),
                ComplexStatus(item),
                const SizedBox(height: 12),
                if (item.displayPrice != null)
                  PriceText(
                    item.displayPrice!,
                    rate: rate,
                    prefix: context.tr(
                      item.parkingOnly ? 'Машиноместа от' : 'от',
                    ),
                  ),
                if (item.json['price_per_m2_from'] is num)
                  Text(
                    '${context.tr('от')} ${money(item.json['price_per_m2_from'] as num)} ${context.tr('сом/м²')}',
                  ),
                Text(
                  '${context.tr('Свободно')}: ${item.available} / ${item.total}',
                ),
                if (item.banks.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final bank in item.banks)
                        Chip(
                          avatar: bank['logo_url'] is String
                              ? ClipOval(
                                  child: ListingImage(
                                    url: bank['logo_url'] as String,
                                  ),
                                )
                              : null,
                          label: Text(bank['name'] as String? ?? ''),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(
      context.tr(text),
      style: Theme.of(context).textTheme.titleLarge,
    ),
  );
}

class ConstructionLoad<T> extends StatefulWidget {
  const ConstructionLoad({
    super.key,
    required this.load,
    required this.builder,
    this.fallback = '/complexes',
  });
  final Future<T> Function() load;
  final Widget Function(T data) builder;
  final String fallback;
  @override
  State<ConstructionLoad<T>> createState() => _ConstructionLoadState<T>();
}

class _ConstructionLoadState<T> extends State<ConstructionLoad<T>> {
  late Future<T> _future = widget.load();
  Future<void> _reload() async {
    final future = widget.load();
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        final error = snapshot.error;
        final missing =
            error is AppException &&
            (error.statusCode == 404 || error.code == 'NOT_FOUND');
        return ListView(
          children: [
            AppEmptyState(
              icon: missing ? Icons.search_off : Icons.cloud_off_outlined,
              title: context.tr(
                missing ? 'Объект недоступен' : 'Не удалось загрузить',
              ),
              message: context.tr(
                missing
                    ? 'Объект скрыт или больше не опубликован.'
                    : 'Проверьте подключение и попробуйте ещё раз.',
              ),
              action: FilledButton(
                onPressed: missing
                    ? () => context.go(widget.fallback)
                    : _reload,
                child: Text(
                  context.tr(missing ? 'Вернуться в каталог' : 'Повторить'),
                ),
              ),
            ),
          ],
        );
      }
      return RefreshIndicator(
        onRefresh: _reload,
        child: widget.builder(snapshot.data as T),
      );
    },
  );
}

Future<void> openConstructionLink(
  BuildContext context,
  String raw, {
  bool phone = false,
}) async {
  final uri = Uri.tryParse(raw);
  final allowed =
      uri != null &&
      (phone ? uri.scheme == 'tel' : ['https', 'http'].contains(uri.scheme));
  var opened = false;
  if (allowed) {
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('Не удалось открыть ссылку'))),
    );
  }
}

Future<void> showConstructionImage(BuildContext context, String url) =>
    showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(title: Text(context.tr('Просмотр изображения'))),
          body: InteractiveViewer(
            minScale: .5,
            maxScale: 5,
            child: Center(child: ListingImage(url: url)),
          ),
        ),
      ),
    );

class ConstructionGallery extends StatelessWidget {
  const ConstructionGallery(this.photos, {super.key});
  final List<String> photos;
  @override
  Widget build(BuildContext context) => photos.isEmpty
      ? const SizedBox.shrink()
      : SizedBox(
          height: 240,
          child: PageView(
            children: [
              for (final url in photos)
                InkWell(
                  onTap: () => showConstructionImage(context, url),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ListingImage(url: url),
                  ),
                ),
            ],
          ),
        );
}

import 'package:flutter/material.dart';
import 'package:konush/l10n/source_messages.dart';
import 'package:konush/src/core/di/injection.dart';
import 'package:konush/src/core/ui/konush_ui.dart';
import 'package:konush/src/features/listings/domain/listing.dart';
import 'package:konush/src/features/listings/domain/listings_repository.dart';
import 'package:konush/src/features/listings/presentation/pages/submit_listing_page.dart';

class EditListingPage extends StatefulWidget {
  const EditListingPage({super.key, required this.id});
  final String id;

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  late Future<Listing> _listing;

  @override
  void initState() {
    super.initState();
    _listing = _load();
  }

  @override
  void didUpdateWidget(covariant EditListingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) _listing = _load();
  }

  Future<Listing> _load() => sl<ListingsRepository>().getMyById(widget.id);

  @override
  Widget build(BuildContext context) => FutureBuilder<Listing>(
    future: _listing,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          snapshot.hasData) {
        if (!snapshot.data!.canEdit) {
          return PageBackScope(
            fallback: '/my-listings',
            child: Scaffold(
              appBar: KonushAppBar(
                title: context.tr('Редактировать объявление'),
                back: true,
                fallback: '/my-listings',
              ),
              body: SingleChildScrollView(
                child: AppEmptyState(
                  icon: Icons.edit_off_outlined,
                  title: context.tr('Редактирование недоступно'),
                  message: context.tr(
                    'В этом статусе объявление нельзя редактировать.',
                  ),
                ),
              ),
            ),
          );
        }
        return SubmitListingPage(
          key: ValueKey(widget.id),
          initialListing: snapshot.data!,
        );
      }
      return PageBackScope(
        fallback: '/my-listings',
        child: Scaffold(
          appBar: KonushAppBar(
            title: context.tr('Редактировать объявление'),
            back: true,
            fallback: '/my-listings',
          ),
          body: snapshot.hasError
              ? SingleChildScrollView(
                  child: AppEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: context.tr('Не удалось загрузить объявление'),
                    message: context.errorText(snapshot.error.toString()),
                    action: FilledButton(
                      onPressed: () => setState(() {
                        _listing = _load();
                      }),
                      child: Text(context.tr('Повторить')),
                    ),
                  ),
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      );
    },
  );
}

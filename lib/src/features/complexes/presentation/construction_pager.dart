import 'package:flutter/material.dart';
import 'package:konush/src/core/network/pagination.dart';
import 'construction_widgets.dart';

class ConstructionPager<T> extends StatefulWidget {
  const ConstructionPager({
    super.key,
    required this.load,
    required this.row,
    required this.emptyTitle,
    this.emptyAction,
    this.mapBuilder,
  });
  final Future<PaginatedResult<T>> Function(int page) load;
  final Widget Function(T item) row;
  final String emptyTitle;
  final Widget? emptyAction;
  final Widget Function(List<T> items, Widget footer, bool failed)? mapBuilder;
  @override
  State<ConstructionPager<T>> createState() => _ConstructionPagerState<T>();
}

class _ConstructionPagerState<T> extends State<ConstructionPager<T>> {
  final _items = <T>[];
  PaginationMeta? _meta;
  bool _loading = true, _more = false, _failed = false;
  int _revision = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (more && (_loading || _more || _meta?.hasNext != true)) return;
    final revision = more ? _revision : ++_revision;
    setState(() {
      _loading = !more;
      _more = more;
      _failed = false;
      if (!more) {
        _items.clear();
        _meta = null;
      }
    });
    try {
      final result = await widget.load(more ? _meta!.page + 1 : 1);
      if (!mounted || revision != _revision) return;
      setState(() {
        Object? identity(T item) => switch (item) {
          ConstructionRecord record => record.id,
          Map<String, dynamic> record => record['id'],
          _ => null,
        };
        final ids = _items.map(identity).whereType<Object>().toSet();
        _items.addAll(
          result.items.where((item) {
            final id = identity(item);
            return id == null || ids.add(id);
          }),
        );
        _meta = result.meta;
      });
    } catch (_) {
      if (mounted && revision == _revision) setState(() => _failed = true);
    } finally {
      if (mounted && revision == _revision) {
        setState(() {
          _loading = false;
          _more = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final footer = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_failed)
          Text(
            context.tr('Не удалось загрузить'),
            style: const TextStyle(color: Colors.red),
          ),
        if (_more)
          const Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          )
        else if (_failed || _meta?.hasNext == true)
          TextButton(
            onPressed: () => _load(more: _items.isNotEmpty),
            child: Text(context.tr(_failed ? 'Повторить' : 'Загрузить ещё')),
          ),
      ],
    );
    final empty = AppEmptyState(
      icon: Icons.apartment_outlined,
      title: context.tr(widget.emptyTitle),
      message: context.tr(
        'Попробуйте изменить фильтры или обновить список позже.',
      ),
      action: widget.emptyAction,
    );
    if (widget.mapBuilder != null) {
      return widget.mapBuilder!(_items, footer, _failed);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        children: [
          if (_items.isEmpty && !_failed) empty,
          ..._items.map(widget.row),
          footer,
        ],
      ),
    );
  }
}

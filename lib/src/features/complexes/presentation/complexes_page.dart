import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:konush/src/core/di/injection.dart';
import 'package:konush/src/core/network/api_client.dart';
import 'package:konush/src/features/home/presentation/home_page.dart';
import 'package:konush/src/features/listings/presentation/pages/listings_page.dart';
import 'package:url_launcher/url_launcher.dart';

enum _ComplexFilter { all, building, done }

class _Complex {
  const _Complex({
    required this.id,
    required this.name,
    required this.building,
    required this.completion,
    required this.district,
    required this.complexClass,
    required this.developer,
    required this.price,
    required this.apartments,
    required this.parking,
    required this.commercial,
    required this.color,
  });

  final String id;
  final String name;
  final bool building;
  final String completion;
  final String district;
  final String complexClass;
  final String developer;
  final int price;
  final int apartments;
  final int parking;
  final int commercial;
  final Color color;

  factory _Complex.fromJson(Map<String, dynamic> json) => _Complex(
    id: json['id'] as String,
    name: json['name'] as String,
    building: json['under_construction'] as bool,
    completion: json['completion'] as String,
    district: json['district'] as String,
    complexClass: json['class'] as String,
    developer: json['developer'] as String,
    price: json['from_per_m2'] as int,
    apartments: json['apartments_available'] as int,
    parking: json['parking_available'] as int,
    commercial: json['commercial_available'] as int,
    color: Color(json['color'] as int),
  );
}

const _complexes = [
  _Complex(
    id: 'alatoo',
    name: 'Ала-Тоо Резиденс',
    building: true,
    completion: 'IV кв. 2027',
    district: 'Магистраль',
    complexClass: 'Бизнес',
    developer: 'Авангард Стиль',
    price: 1050,
    apartments: 49,
    parking: 64,
    commercial: 2,
    color: Color(0xFFD8CDB4),
  ),
  _Complex(
    id: 'konushcity',
    name: 'Конуш Сити',
    building: true,
    completion: 'II кв. 2028',
    district: 'Джал',
    complexClass: 'Комфорт',
    developer: 'Имарат Строй',
    price: 980,
    apartments: 93,
    parking: 120,
    commercial: 2,
    color: Color(0xFFB6D1CD),
  ),
  _Complex(
    id: 'tumar',
    name: 'Тумар Тауэрс',
    building: true,
    completion: 'I кв. 2027',
    district: 'Эркиндик',
    complexClass: 'Премиум',
    developer: 'Премиум КГ',
    price: 1340,
    apartments: 26,
    parking: 28,
    commercial: 1,
    color: Color(0xFFC9BED1),
  ),
  _Complex(
    id: 'erkindikplaza',
    name: 'Эркиндик Плаза',
    building: false,
    completion: '2023',
    district: 'Эркиндик',
    complexClass: 'Бизнес',
    developer: 'Премиум КГ',
    price: 1380,
    apartments: 4,
    parking: 12,
    commercial: 1,
    color: Color(0xFFD5CADB),
  ),
  _Complex(
    id: 'asanbaypark',
    name: 'Асанбай Парк',
    building: false,
    completion: '2022',
    district: 'Асанбай',
    complexClass: 'Комфорт',
    developer: 'Авангард Стиль',
    price: 890,
    apartments: 12,
    parking: 40,
    commercial: 2,
    color: Color(0xFFC7D5BE),
  ),
];

class ComplexesPage extends StatefulWidget {
  const ComplexesPage({super.key});

  @override
  State<ComplexesPage> createState() => _ComplexesPageState();
}

class _ComplexesPageState extends State<ComplexesPage> {
  bool _menuOpen = false;
  _ComplexFilter _filter = _ComplexFilter.all;
  List<_Complex> _items = _complexes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await sl<ApiClient>().get<List<_Complex>>(
        '/complexes',
        decode: (json) => (json as List<dynamic>)
            .map((item) => _Complex.fromJson(item as Map<String, dynamic>))
            .toList(),
      );
      if (mounted) setState(() => _items = response.data);
    } catch (_) {
      // Bundled data is the fallback until the new endpoint reaches staging.
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items.where(
      (item) => switch (_filter) {
        _ComplexFilter.all => true,
        _ComplexFilter.building => item.building,
        _ComplexFilter.done => !item.building,
      },
    );
    return Scaffold(
      appBar: CatalogHeader(
        menuOpen: _menuOpen,
        onMenu: () => setState(() => _menuOpen = !_menuOpen),
      ),
      body: Column(
        children: [
          if (_menuOpen)
            MobileHeaderMenu(onClose: () => setState(() => _menuOpen = false)),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1460),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Жилые комплексы',
                              style: TextStyle(
                                color: ink,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 7),
                            const Text(
                              '5 комплексов в Бишкеке — строящиеся и сданные, с '
                              'актуальной доступностью квартир, паркинга и коммерции.',
                              style: TextStyle(
                                color: Color(0xFF61706E),
                                fontSize: 12.5,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _chip('Все', _ComplexFilter.all),
                                const SizedBox(width: 8),
                                _chip('Строится', _ComplexFilter.building),
                                const SizedBox(width: 8),
                                _chip('Сдан', _ComplexFilter.done),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                  sliver: SliverLayoutBuilder(
                    builder: (_, constraints) {
                      final columns = constraints.crossAxisExtent >= 1000
                          ? 3
                          : constraints.crossAxisExtent >= 650
                          ? 2
                          : 1;
                      final list = items.toList();
                      return SliverGrid.builder(
                        itemCount: list.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent: 318,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 16,
                        ),
                        itemBuilder: (_, index) =>
                            _ComplexCard(item: list[index]),
                      );
                    },
                  ),
                ),
                const SliverToBoxAdapter(child: KonushFooter()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _ComplexFilter value) {
    final selected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(99),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? teal : Colors.white,
          border: Border.all(color: selected ? teal : border),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF465552),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ComplexCard extends StatelessWidget {
  const _ComplexCard({required this.item});
  final _Complex item;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(13),
      side: const BorderSide(color: border),
    ),
    child: InkWell(
      onTap: () => context.push('/complexes/${item.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 160,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: item.color,
                  child: const Center(
                    child: Text(
                      'фото',
                      style: TextStyle(color: Color(0x44919995), fontSize: 11),
                    ),
                  ),
                ),
                Positioned(
                  left: 11,
                  top: 11,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: item.building
                          ? const Color(0xFFFFF3DA)
                          : const Color(0xFFE5F2EF),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      item.building ? 'Строится' : 'Сдан',
                      style: TextStyle(
                        color: item.building ? const Color(0xFF98680D) : teal,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.district}, Бишкек · ${item.complexClass}-класс · ${item.completion}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF596866),
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'от ${item.developer}',
                  style: const TextStyle(color: muted, fontSize: 10),
                ),
                const SizedBox(height: 11),
                const Divider(height: 1, color: border),
                const SizedBox(height: 10),
                Text(
                  'от \$${_money(item.price)}/м²',
                  style: const TextStyle(
                    color: teal,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${item.apartments} квартир · ${item.parking} паркомест · ${item.commercial} коммерции',
                  style: const TextStyle(color: muted, fontSize: 9.5),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  static String _money(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
}

class ComplexDetailPage extends StatefulWidget {
  const ComplexDetailPage({super.key, required this.id});
  final String id;

  @override
  State<ComplexDetailPage> createState() => _ComplexDetailPageState();
}

class _ComplexDetailPageState extends State<ComplexDetailPage> {
  bool _menuOpen = false;
  late _Complex _item;

  @override
  void initState() {
    super.initState();
    _item = _complexes.firstWhere(
      (item) => item.id == widget.id,
      orElse: () => _complexes.first,
    );
    _load();
  }

  Future<void> _load() async {
    try {
      final response = await sl<ApiClient>().get<_Complex>(
        '/complexes/${widget.id}',
        decode: (json) => _Complex.fromJson(json as Map<String, dynamic>),
      );
      if (mounted) setState(() => _item = response.data);
    } catch (_) {
      // See the list page: local data remains available before staging deploy.
    }
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
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(15, 16, 15, 22),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 980),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton.icon(
                            onPressed: () => context.go('/complexes'),
                            icon: const Icon(Icons.arrow_back, size: 15),
                            label: const Text('Все комплексы'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              textStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _hero(),
                          const SizedBox(height: 18),
                          Text(
                            _item.name,
                            style: const TextStyle(
                              color: ink,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${_item.district}, Бишкек · ${_item.complexClass}-класс · от ${_item.developer}',
                            style: const TextStyle(color: muted, fontSize: 11),
                          ),
                          const SizedBox(height: 16),
                          _facts(),
                          const SizedBox(height: 20),
                          _sectionTitle('О комплексе'),
                          const SizedBox(height: 9),
                          Text(
                            _item.description,
                            style: const TextStyle(
                              color: Color(0xFF445350),
                              fontSize: 12,
                              height: 1.55,
                            ),
                          ),
                          const SizedBox(height: 22),
                          _sectionTitle('Доступные квартиры'),
                          const SizedBox(height: 10),
                          _apartments(),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => context.go('/listings?tab=new'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              'Все объявления в ${_item.name} →',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _infoCard(
                            title: 'Паркинг',
                            children: [
                              Text(
                                'Свободно ${_item.parking} из ${_item.parkingTotal}',
                              ),
                              Text('\$${_item.parkingPrice} за место'),
                              Text(
                                _item.parkingType,
                                style: const TextStyle(color: muted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _infoCard(
                            title: 'Коммерческие помещения',
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(_item.commercialLine)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: tint,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: const Text(
                                      'Свободно',
                                      style: TextStyle(
                                        color: teal,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _contactCard(),
                          const SizedBox(height: 12),
                          _salesCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: KonushFooter()),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _hero() => Container(
    height: 205,
    decoration: BoxDecoration(
      color: _item.color,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Stack(
      children: [
        const Center(
          child: Text(
            'фото 1 / 3',
            style: TextStyle(color: Color(0x44919995), fontSize: 11),
          ),
        ),
        Positioned(
          left: 9,
          top: 9,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: _item.building
                  ? const Color(0xFFFFF3DA)
                  : const Color(0xFFE5F2EF),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              _item.building ? 'Строится' : 'Сдан',
              style: TextStyle(
                color: _item.building ? const Color(0xFF98680D) : teal,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _facts() => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 2.5,
    children: [
      _fact('СТАТУС', _item.building ? 'Строится' : 'Сдан'),
      _fact('СРОК СДАЧИ', _item.completion),
      _fact('ЭТАЖЕЙ', _item.floors),
      _fact('КОРПУСОВ', _item.buildings),
    ],
  );

  Widget _fact(String label, String value) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: border),
      borderRadius: BorderRadius.circular(11),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0C12211F),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: muted,
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: ink,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );

  Widget _apartments() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: border),
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        const _ApartmentRow(
          header: true,
          values: ['ПЛАНИРОВКА', 'ПЛОЩАДЬ', 'ЦЕНА', '\$/М²'],
        ),
        for (final row in _item.apartmentRows) _ApartmentRow(values: row),
      ],
    ),
  );

  Widget _infoCard({required String title, required List<Widget> children}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(
            color: Color(0xFF455451),
            fontSize: 11,
            height: 1.6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              ...children,
            ],
          ),
        ),
      );

  Widget _contactCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ЦЕНЫ ОТ',
          style: TextStyle(
            color: muted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'от \$${_money(_item.price)}/м²',
          style: const TextStyle(
            color: teal,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '${_item.apartments} квартир · ${_item.parking} паркомест · ${_item.commercial} коммерция в наличии',
          style: const TextStyle(color: muted, fontSize: 9.5),
        ),
        const SizedBox(height: 11),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {},
            child: const Text('Связаться с застройщиком'),
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () =>
                launchUrl(Uri(scheme: 'tel', path: '+996555010101')),
            icon: const Icon(Icons.phone_outlined, size: 15),
            label: const Text('Показать телефон'),
          ),
        ),
      ],
    ),
  );

  Widget _salesCard() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: ink,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Отдел продаж',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_item.agent} · ${_item.developer}',
          style: const TextStyle(color: Color(0xFFA4BDB8), fontSize: 10.5),
        ),
        const SizedBox(height: 6),
        const Text(
          'Ежедневно 9:00–19:00',
          style: TextStyle(color: Color(0xFFA4BDB8), fontSize: 10.5),
        ),
        const SizedBox(height: 8),
        Text(
          '${_item.district}, Бишкек',
          style: const TextStyle(color: Color(0xFF49B7A8), fontSize: 10.5),
        ),
      ],
    ),
  );

  static Widget _sectionTitle(String value) => Text(
    value,
    style: const TextStyle(
      color: ink,
      fontSize: 14,
      fontWeight: FontWeight.w900,
    ),
  );
  static String _money(int value) => value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
}

class _ApartmentRow extends StatelessWidget {
  const _ApartmentRow({required this.values, this.header = false});
  final List<String> values;
  final bool header;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: border)),
    ),
    child: Row(
      children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            flex: i == 0 ? 13 : 10,
            child: Text(
              values[i],
              style: TextStyle(
                color: header ? muted : const Color(0xFF43514F),
                fontSize: header ? 8 : 9.5,
                fontWeight: header || i == 0
                    ? FontWeight.w800
                    : FontWeight.w500,
              ),
            ),
          ),
      ],
    ),
  );
}

extension on _Complex {
  String get floors => switch (id) {
    'tumar' => '22',
    'konushcity' => '14',
    _ => '12',
  };
  String get buildings => switch (id) {
    'alatoo' => '3',
    'konushcity' => '5',
    'tumar' => '2',
    'asanbaypark' => '4',
    _ => '1',
  };
  String get agent => switch (id) {
    'konushcity' => 'Чолпон Бейшенова',
    'erkindikplaza' || 'tumar' => 'Жылдыз Асанова',
    _ => 'Бакыт Орозбеков',
  };
  String get description => switch (id) {
    'erkindikplaza' =>
      'Сданный дом бизнес-класса над бульваром Эркиндик, введён в 2023 году. Консьерж, приватные лифтовые холлы, виды на дубовую аллею. Последние квартиры от застройщика.',
    _ =>
      'Современный жилой комплекс с закрытым двором, паркингом и продуманными планировками. Актуальные квартиры доступны напрямую от застройщика.',
  };
  List<List<String>> get apartmentRows => id == 'erkindikplaza'
      ? const [
          ['2-комн.', '72 м²', 'от \$99,400', '\$1,380'],
          ['4-комн.\nпентхаус', '140 м²', '\$210,000', '\$1,500'],
        ]
      : [
          [
            '1-комн.',
            '42–48 м²',
            'от \$${_ComplexDetailPageState._money(price * 42)}',
            '\$${_ComplexDetailPageState._money(price)}',
          ],
          [
            '2-комн.',
            '58–66 м²',
            'от \$${_ComplexDetailPageState._money(price * 58)}',
            '\$${_ComplexDetailPageState._money(price)}',
          ],
        ];
  int get parkingTotal => switch (id) {
    'erkindikplaza' => 96,
    'alatoo' => 180,
    'konushcity' => 320,
    'tumar' => 240,
    _ => 210,
  };
  int get parkingPrice => switch (id) {
    'erkindikplaza' => 15000,
    'alatoo' => 12000,
    'konushcity' => 7500,
    'tumar' => 18000,
    _ => 6000,
  };
  String get parkingType => id == 'asanbaypark' ? 'Наземный' : 'Подземный';
  String get commercialLine => id == 'erkindikplaza'
      ? 'Офис на первом этаже · 110 м² — \$176,000'
      : 'Помещение на первом этаже';
}

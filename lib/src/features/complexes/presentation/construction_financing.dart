import 'package:flutter/material.dart';
import 'construction_widgets.dart';

class MortgagePage extends StatelessWidget {
  const MortgagePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: canvas,
    appBar: KonushAppBar(
      title: context.tr('Ипотека'),
      back: true,
      fallback: '/complexes',
    ),
    body: ContentWidth(
      child: ConstructionLoad<List<MortgageProgram>>(
        load: () => constructionRepository().programs(),
        builder: (programs) {
          final banks = programs.map((p) => p.bankName).toSet();
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (programs.isEmpty)
                AppEmptyState(
                  icon: Icons.account_balance_outlined,
                  title: context.tr('Ипотечных программ пока нет'),
                  message: context.tr('Попробуйте обновить список позже.'),
                ),
              for (final bank in banks) ...[
                SectionTitle(bank),
                for (final program in programs.where((p) => p.bankName == bank))
                  MortgageProgramCard(program: program),
              ],
            ],
          );
        },
      ),
    ),
  );
}

class FinancingSection extends StatelessWidget {
  const FinancingSection({super.key, required this.complex, this.unit});
  final ResidentialComplex complex;
  final ComplexUnit? unit;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (complex.mortgages.isNotEmpty) ...[
        const SectionTitle('Ипотека'),
        for (final program in complex.mortgages)
          MortgageProgramCard(program: program, price: unit?.price),
      ],
      if (complex.installments.any(
        (p) => unit == null || p.fits(unit!.type),
      )) ...[
        const SectionTitle('Рассрочка'),
        for (final plan in complex.installments.where(
          (p) => unit == null || p.fits(unit!.type),
        ))
          InstallmentCard(plan: plan, price: unit?.price),
      ],
    ],
  );
}

class MortgageProgramCard extends StatelessWidget {
  const MortgageProgramCard({super.key, required this.program, this.price});
  final MortgageProgram program;
  final int? price;
  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      title: Text(program.name),
      subtitle: Text(
        '${program.bankName} · ${context.tr('Ставка от')}: ${program.rate}%',
      ),
      childrenPadding: const EdgeInsets.all(16),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr(
            program.text('program_type') == 'gov'
                ? 'Государственная программа'
                : 'Коммерческая программа',
          ),
        ),
        if (program.amount('rate_to') != null)
          Text(
            '${context.tr('Диапазон ставки')}: ${program.rate}–${program.amount('rate_to')}%',
          ),
        Text('${context.tr('Срок до, лет')}: ${program.years}'),
        Text('${context.tr('Первый взнос от, %')}: ${program.minDown}'),
        if (program.maxLoan != null)
          Text(
            '${context.tr('Максимальная сумма кредита')}: ${money(program.maxLoan!)} ${context.tr('сом')}',
          ),
        if (program.text('requirements').isNotEmpty)
          Text(program.text('requirements')),
        if (program.text('note').isNotEmpty) Text(program.text('note')),
        if (date(program.json['conditions_verified_at']) != null)
          Text(
            '${context.tr('Условия сверены')}: ${displayDate(date(program.json['conditions_verified_at'])!)}',
          ),
        if (program.text('source_url').isNotEmpty)
          TextButton(
            onPressed: () =>
                openConstructionLink(context, program.text('source_url')),
            child: Text(context.tr('Условия банка')),
          ),
        MortgageCalculator(program: program, price: price),
      ],
    ),
  );
}

class MortgageCalculator extends StatefulWidget {
  const MortgageCalculator({super.key, required this.program, this.price});
  final MortgageProgram program;
  final int? price;
  @override
  State<MortgageCalculator> createState() => _MortgageCalculatorState();
}

class _MortgageCalculatorState extends State<MortgageCalculator> {
  final _form = GlobalKey<FormState>();
  late final _price = TextEditingController(
    text: widget.price?.toString() ?? '',
  );
  late final _down = TextEditingController(
    text: widget.program.minDown.toString(),
  );
  late final _years = TextEditingController(
    text: widget.program.years.toString(),
  );
  MortgageResult? _result;
  @override
  void dispose() {
    _price.dispose();
    _down.dispose();
    _years.dispose();
    super.dispose();
  }

  Widget _field(
    TextEditingController control,
    String label,
    num min,
    num max,
  ) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: TextFormField(
      controller: control,
      readOnly: control == _price && widget.price != null,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: context.tr(label)),
      onChanged: (_) => setState(() => _result = null),
      validator: (raw) {
        final value = num.tryParse((raw ?? '').replaceAll(',', '.'));
        final whole = control != _down;
        return value == null ||
                !value.isFinite ||
                value < min ||
                value > max ||
                (whole && value != value.roundToDouble())
            ? '${context.tr('Допустимый диапазон')}: $min–$max'
            : null;
      },
    ),
  );
  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(_price, 'Стоимость, сом', 1, 999999999999999),
        _field(_down, 'Первый взнос, %', widget.program.minDown, 100),
        _field(_years, 'Срок, лет', 1, widget.program.years),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () {
            if (!_form.currentState!.validate()) return;
            setState(
              () => _result = mortgageCalculation(
                price: num.parse(_price.text.replaceAll(',', '.')).round(),
                downPct: double.parse(_down.text.replaceAll(',', '.')),
                ratePct: widget.program.rate,
                years: num.parse(_years.text.replaceAll(',', '.')).round(),
              ),
            );
          },
          child: Text(context.tr('Рассчитать ипотеку')),
        ),
        if (_result != null) ...[
          if (widget.program.maxLoan != null &&
              _result!.loan > widget.program.maxLoan!)
            Notice(context.tr('Сумма кредита превышает лимит программы')),
          Text(
            '${context.tr('Кредит')}: ${money(_result!.loan)} ${context.tr('сом')}',
          ),
          Text(
            '${context.tr('В месяц')}: ${money(_result!.monthly)} ${context.tr('сом')}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            '${context.tr('Всего выплат по кредиту')}: ${money(_result!.total)} ${context.tr('сом')}',
          ),
          Text(
            '${context.tr('Переплата')}: ${money(_result!.overpay)} ${context.tr('сом')}',
          ),
        ],
        const SizedBox(height: 8),
        Text(
          context.tr(
            'Расчёт ориентировочный. Решение и окончательную ставку определяет банк.',
          ),
          style: const TextStyle(color: muted),
        ),
      ],
    ),
  );
}

class InstallmentCard extends StatefulWidget {
  const InstallmentCard({super.key, required this.plan, this.price});
  final InstallmentPlan plan;
  final int? price;
  @override
  State<InstallmentCard> createState() => _InstallmentCardState();
}

class _InstallmentCardState extends State<InstallmentCard> {
  late final _price = TextEditingController(
    text: widget.price?.toString() ?? '',
  );
  final _form = GlobalKey<FormState>();
  InstallmentResult? _result;
  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final valid =
        plan.months > 0 &&
        plan.interval > 0 &&
        plan.months % plan.interval == 0;
    return Card(
      child: ExpansionTile(
        title: Text(plan.text('title')),
        subtitle: Text(
          '${context.tr('Первый взнос')}: ${plan.down}% · ${plan.months} ${context.tr('мес.')}',
        ),
        childrenPadding: const EdgeInsets.all(16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${context.tr('Удорожание за весь срок')}: ${plan.markup}%'),
          Text(
            context.tr(
              paymentIntervals[plan.interval] ?? 'Период платежа не указан',
            ),
          ),
          if ((plan.json['unit_types'] as List?)?.isNotEmpty == true)
            Text(
              (plan.json['unit_types'] as List)
                  .map((t) => context.tr(unitTypes[t] ?? 'Объект'))
                  .join(', '),
            ),
          if (plan.text('note').isNotEmpty) Text(plan.text('note')),
          const SizedBox(height: 12),
          if (!valid)
            Text(context.tr('Условия расчёта недоступны'))
          else
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _price,
                    readOnly: widget.price != null,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.tr('Стоимость, сом'),
                    ),
                    onChanged: (_) => setState(() => _result = null),
                    validator: (raw) {
                      final price = int.tryParse(raw ?? '');
                      return price == null ||
                              price <= 0 ||
                              price > 999999999999999
                          ? context.tr('Введите положительное целое число')
                          : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      if (!_form.currentState!.validate()) return;
                      setState(
                        () => _result = installmentCalculation(
                          int.parse(_price.text),
                          plan,
                        ),
                      );
                    },
                    child: Text(context.tr('Рассчитать рассрочку')),
                  ),
                  if (_result != null) ...[
                    Text(
                      '${context.tr('Стоимость с удорожанием')}: ${money(_result!.total)} ${context.tr('сом')}',
                    ),
                    Text(
                      '${context.tr('Первый взнос')}: ${money(_result!.down)} ${context.tr('сом')}',
                    ),
                    Text('${context.tr('Платежей')}: ${_result!.payments}'),
                    Text(
                      '${context.tr('Каждый платёж')}: ${money(_result!.payment)} ${context.tr('сом')}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                  Text(
                    context.tr(
                      'Расчёт ориентировочный. Уточните условия у застройщика.',
                    ),
                    style: const TextStyle(color: muted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

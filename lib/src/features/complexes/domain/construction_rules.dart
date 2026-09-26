import 'dart:math' as math;
import '../data/complex_repository.dart';

const housingClasses = {
  'economy': 'Эконом',
  'comfort': 'Комфорт',
  'business': 'Бизнес',
  'premium': 'Премиум',
};
const constructionStages = {
  'planning': 'Проектирование',
  'excavation': 'Земляные работы',
  'foundation': 'Фундамент',
  'frame': 'Каркас',
  'facade': 'Фасад',
  'finishing': 'Отделка',
  'completed': 'Сдан',
};
const amenities = {
  'school': 'Школа',
  'kindergarten': 'Детский сад',
  'underground_parking': 'Подземный паркинг',
  'surface_parking': 'Наземная парковка',
  'security': 'Охрана',
  'cctv': 'Видеонаблюдение',
  'closed_territory': 'Закрытая территория',
  'playground': 'Детская площадка',
  'sports_ground': 'Спортплощадка',
  'gym': 'Фитнес-зал',
  'commercial_premises': 'Коммерческие помещения',
  'elevator': 'Лифт',
  'concierge': 'Консьерж',
  'park_nearby': 'Парк рядом',
};
const unitTypes = {
  'apartment': 'Квартира',
  'office': 'Офис',
  'parking': 'Паркинг',
};
const saleStatuses = {
  'available': 'Свободно',
  'reserved': 'Забронировано',
  'sold': 'Продано',
};
const finishingTypes = {
  'none': 'Без отделки (ПСО)',
  'white_box': 'Предчистовая',
  'turnkey': 'Под ключ',
};
const cities = {
  '00000000-0000-0000-0000-000000000001': 'Бишкек',
  '00000000-0000-0000-0000-000000000002': 'Ош',
  '00000000-0000-0000-0000-000000000003': 'Джалал-Абад',
  '00000000-0000-0000-0000-000000000004': 'Каракол',
  '00000000-0000-0000-0000-000000000005': 'Нарын',
  '00000000-0000-0000-0000-000000000006': 'Талас',
  '00000000-0000-0000-0000-000000000007': 'Баткен',
};
const complexSorts = {
  'newest': 'Сначала новые',
  'price_asc': 'Сначала дешевле',
  'handover_asc': 'По сроку сдачи',
  'readiness_desc': 'По готовности',
};
const unitSorts = {
  '': 'По корпусу, этажу и номеру',
  'price_asc': 'Сначала дешевле',
  'price_desc': 'Сначала дороже',
  'area_asc': 'Площадь по возрастанию',
  'area_desc': 'Площадь по убыванию',
  'price_m2_asc': 'По цене за м²',
  'floor_asc': 'Этаж по возрастанию',
  'floor_desc': 'Этаж по убыванию',
};
const paymentIntervals = {
  1: 'ежемесячно',
  3: 'раз в квартал',
  6: 'раз в полгода',
  12: 'раз в год',
};

DateTime bishkekTime(DateTime time) =>
    time.toUtc().add(const Duration(hours: 6));
bool handoverOverdue(ResidentialComplex item, DateTime now) {
  if (item.completed || item.handoverYear == null) return false;
  final month = (item.handoverQuarter ?? 4) * 3;
  final endExclusive = DateTime.utc(
    item.handoverYear!,
    month + 1,
  ).subtract(const Duration(hours: 6));
  return !now.toUtc().isBefore(endExclusive);
}

bool staleCatalog(ResidentialComplex item, DateTime now) =>
    item.catalogDate != null &&
    now.toUtc().difference(item.catalogDate!.toUtc()).inDays > 30;
bool validPoint(double? lat, double? lng) =>
    lat != null &&
    lng != null &&
    lat.isFinite &&
    lng.isFinite &&
    lat.abs() <= 90 &&
    lng.abs() <= 180 &&
    (lat != 0 || lng != 0);
String phoneDisplay(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 12 && digits.startsWith('996')) {
    return '+996 ${digits.substring(3, 6)} ${digits.substring(6, 9)} ${digits.substring(9)}';
  }
  return raw;
}

class MortgageResult {
  const MortgageResult(this.loan, this.monthly, this.total, this.overpay);
  final int loan, monthly, total, overpay;
}

MortgageResult mortgageCalculation({
  required int price,
  required double downPct,
  required double ratePct,
  required int years,
}) {
  final loan = math.max(0, (price * (1 - downPct / 100)).round());
  final n = years * 12;
  if (loan == 0 || n <= 0) return MortgageResult(loan, 0, 0, 0);
  final r = ratePct / 1200;
  final factor = math.pow(1 + r, n);
  final monthly = r == 0
      ? (loan / n).round()
      : (loan * r * factor / (factor - 1)).round();
  return MortgageResult(loan, monthly, monthly * n, monthly * n - loan);
}

class InstallmentResult {
  const InstallmentResult(this.total, this.down, this.payments, this.payment);
  final int total, down, payments, payment;
}

InstallmentResult installmentCalculation(int price, InstallmentPlan plan) {
  if (plan.interval <= 0 ||
      plan.months <= 0 ||
      plan.months % plan.interval != 0) {
    throw const FormatException('Invalid installment period');
  }
  final total = (price * (1 + plan.markup / 100)).round();
  final down = (total * plan.down / 100).round();
  final payments = plan.months ~/ plan.interval;
  return InstallmentResult(
    total,
    down,
    payments,
    (math.max(total - down, 0) / payments).round(),
  );
}

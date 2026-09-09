import 'package:flutter_test/flutter_test.dart';
import 'package:konush/src/core/ui/kyrgyz_phone_formatter.dart';

void main() {
  const formatter = KyrgyzPhoneFormatter();

  TextEditingValue format(String value) => formatter.formatEditUpdate(
    const TextEditingValue(text: KyrgyzPhoneFormatter.prefix),
    TextEditingValue(text: value),
  );

  test('formats a complete Kyrgyz phone number', () {
    expect(format('+996700123456').text, '+996 700 123 456');
  });

  test('keeps the country prefix and removes non-digits', () {
    expect(format('abc').text, '+996');
    expect(format('+996 555-a').text, '+996 555');
  });

  test('limits the local number to nine digits', () {
    expect(format('+99670012345699').text, '+996 700 123 456');
  });
}

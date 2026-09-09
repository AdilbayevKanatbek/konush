import 'package:flutter/services.dart';

class KyrgyzPhoneFormatter extends TextInputFormatter {
  const KyrgyzPhoneFormatter();

  static const prefix = '+996';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('996')) digits = digits.substring(3);
    if (digits.length > 9) digits = digits.substring(0, 9);

    final buffer = StringBuffer(prefix);
    for (var i = 0; i < digits.length; i++) {
      if (i == 0 || i == 3 || i == 6) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

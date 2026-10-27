import 'package:flutter/services.dart';

/// Formats up to eight date digits as `YYYY-MM-DD` while typing (numeric keypad).
class IsoDateDigitsInput {
  static const int maxDigits = 8;

  static String digitsOnly(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');

  static String formatFromDigits(String digits) {
    final d = digits.length > maxDigits ? digits.substring(0, maxDigits) : digits;
    if (d.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 4 || i == 6) buffer.write('-');
      buffer.write(d[i]);
    }
    return buffer.toString();
  }

  static int digitIndexBeforeOffset(String text, int offset) {
    final end = offset.clamp(0, text.length);
    return digitsOnly(text.substring(0, end)).length;
  }

  static int selectionOffsetForDigitIndex(String formatted, int digitIndex) {
    if (digitIndex <= 0) return 0;
    var digits = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (formatted[i] == '-') continue;
      digits++;
      if (digits == digitIndex) return i + 1;
    }
    return formatted.length;
  }
}

class IsoDateDigitsInputFormatter extends TextInputFormatter {
  const IsoDateDigitsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = IsoDateDigitsInput.digitsOnly(newValue.text);
    final trimmed =
        digits.length > IsoDateDigitsInput.maxDigits
            ? digits.substring(0, IsoDateDigitsInput.maxDigits)
            : digits;
    final formatted = IsoDateDigitsInput.formatFromDigits(trimmed);
    final digitIndex = IsoDateDigitsInput.digitIndexBeforeOffset(
      newValue.text,
      newValue.selection.end,
    );
    final offset = IsoDateDigitsInput.selectionOffsetForDigitIndex(
      formatted,
      digitIndex.clamp(0, trimmed.length),
    );
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

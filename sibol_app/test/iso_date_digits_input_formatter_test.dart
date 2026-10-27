import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/cases/domain/case_date_of_birth.dart';
import 'package:sibol_app/shared/input/iso_date_digits_input_formatter.dart';

void main() {
  const formatter = IsoDateDigitsInputFormatter();

  TextEditingValue apply(String oldText, int oldOffset, String newText, int newOffset) {
    return formatter.formatEditUpdate(
      TextEditingValue(
        text: oldText,
        selection: TextSelection.collapsed(offset: oldOffset),
      ),
      TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      ),
    );
  }

  group('IsoDateDigitsInput.formatFromDigits', () {
    test('progressive formatting examples', () {
      expect(IsoDateDigitsInput.formatFromDigits('2'), '2');
      expect(IsoDateDigitsInput.formatFromDigits('2010'), '2010');
      expect(IsoDateDigitsInput.formatFromDigits('201005'), '2010-05');
      expect(IsoDateDigitsInput.formatFromDigits('20100517'), '2010-05-17');
    });

    test('caps at eight digits', () {
      expect(
        IsoDateDigitsInput.formatFromDigits('2010051799'),
        '2010-05-17',
      );
    });
  });

  group('formatter typing', () {
    test('builds full date from digit entry', () {
      var value = apply('', 0, '2', 1);
      expect(value.text, '2');
      value = apply(value.text, value.selection.end, '20', 2);
      value = apply(value.text, value.selection.end, '2010', 4);
      expect(value.text, '2010');
      value = apply(value.text, value.selection.end, '20100', 5);
      value = apply(value.text, value.selection.end, '201005', 6);
      expect(value.text, '2010-05');
      value = apply(value.text, value.selection.end, '2010051', 8);
      value = apply(value.text, value.selection.end, '20100517', 10);
      expect(value.text, '2010-05-17');
    });

    test('strips alphabetic characters', () {
      final value = apply('', 0, '20a10b05c17', 11);
      expect(value.text, '2010-05-17');
    });

    test('rejects excess digits beyond eight', () {
      final value = apply('2010-05-17', 10, '2010-05-1799', 12);
      expect(value.text, '2010-05-17');
    });

    test('backspace from end removes digits without stray separators', () {
      var value = apply('2010-05-17', 10, '2010-05-1', 9);
      expect(value.text, '2010-05-1');
      value = apply('2010-05-1', 9, '2010-05', 7);
      expect(value.text, '2010-05');
      value = apply('2010-05', 7, '2010-0', 6);
      expect(value.text, '2010-0');
      value = apply('2010-0', 6, '2010', 4);
      expect(value.text, '2010');
    });
  });

  group('calendar validation via CaseDateOfBirth', () {
    test('accepts leap day', () {
      expect(CaseDateOfBirth.parse('2000-02-29'), isNotNull);
      expect(
        CaseDateOfBirth.validateForAdolescentCase('2000-02-29', referenceDate: DateTime(2018, 6, 1)),
        isNull,
      );
    });

    test('rejects February 30', () {
      expect(CaseDateOfBirth.parse('2010-02-30'), isNull);
    });

    test('rejects future birth date', () {
      final future = DateTime.now().add(const Duration(days: 30));
      final raw =
          '${future.year}-${future.month.toString().padLeft(2, '0')}-${future.day.toString().padLeft(2, '0')}';
      expect(
        CaseDateOfBirth.validateForAdolescentCase(raw),
        contains('future'),
      );
    });

    test('preserves storage string for registration', () {
      final parsed = CaseDateOfBirth.parse('2010-05-17');
      expect(parsed!.toStorageString(), '2010-05-17');
    });
  });
}

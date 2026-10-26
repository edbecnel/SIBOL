/// Date-only birth date (YYYY-MM-DD) and adolescent age calculations.
class CaseDateOfBirth {
  const CaseDateOfBirth(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  static final RegExp _pattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  static CaseDateOfBirth? parse(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final match = _pattern.firstMatch(trimmed);
    if (match == null) return null;
    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null || month == null || day == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    try {
      final date = DateTime(year, month, day);
      if (date.year != year || date.month != month || date.day != day) {
        return null;
      }
      return CaseDateOfBirth(year, month, day);
    } catch (_) {
      return null;
    }
  }

  String toStorageString() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  DateTime toLocalDate() => DateTime(year, month, day);

  /// Whole years between birth date and [onDate] (local calendar).
  static int ageOnDate(CaseDateOfBirth dob, DateTime onDate) {
    var age = onDate.year - dob.year;
    final hadBirthday = onDate.month > dob.month ||
        (onDate.month == dob.month && onDate.day >= dob.day);
    if (!hadBirthday) age -= 1;
    return age;
  }

  static int currentAge(CaseDateOfBirth dob, {DateTime? now}) {
    final today = now ?? DateTime.now();
    return ageOnDate(dob, DateTime(today.year, today.month, today.day));
  }

  static String? validateForAdolescentCase(
    String? raw, {
    DateTime? referenceDate,
  }) {
    final parsed = parse(raw);
    if (parsed == null) return 'Enter a valid date of birth (YYYY-MM-DD).';
    final today = referenceDate ?? DateTime.now();
    final onDay = DateTime(today.year, today.month, today.day);
    if (parsed.toLocalDate().isAfter(onDay)) {
      return 'Date of birth cannot be in the future.';
    }
    final age = currentAge(parsed, now: onDay);
    if (age < CaseAdolescentAgeBounds.min || age > CaseAdolescentAgeBounds.max) {
      return 'Age must be between ${CaseAdolescentAgeBounds.min} and '
          '${CaseAdolescentAgeBounds.max} for this case.';
    }
    return null;
  }
}

class CaseAdolescentAgeBounds {
  static const int min = 13;
  static const int max = 19;
}

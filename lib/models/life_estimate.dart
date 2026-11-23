import 'dart:math' as math;

import '../data/countries.dart';
import '../data/lifestyle.dart';
import 'profile.dart';

const double daysPerYear = 365.2425;
const int weeksPerYear = 52;
const double _microsPerYear = daysPerYear * Duration.microsecondsPerDay;

/// Whole years between [from] and [to], counting birthdays on the calendar.
int fullYearsBetween(DateTime from, DateTime to) {
  var years = to.year - from.year;
  if (to.month < from.month || (to.month == from.month && to.day < from.day)) {
    years--;
  }
  return math.max(0, years);
}

/// A line in the "how we got this number" breakdown.
class EstimateFactor {
  const EstimateFactor(this.label, this.years);
  final String label;
  final double years;
}

/// The expected lifespan derived from a [Profile].
class LifeEstimate {
  LifeEstimate._({
    required this.birth,
    required this.country,
    required this.baseYears,
    required this.factors,
    required this.adjustmentYears,
  });

  factory LifeEstimate.fromProfile(Profile profile) {
    final country = countryByCode(profile.countryCode);
    final base = switch (profile.sex) {
      Sex.female => country.female,
      Sex.male => country.male,
      Sex.unspecified => country.average,
    };
    final factors = <EstimateFactor>[];
    var total = 0.0;
    for (final q in lifestyleQuestions) {
      final option = q.option(profile.lifestyle[q.id]);
      if (option == null) continue;
      factors.add(EstimateFactor('${q.title}: ${option.label}', option.years));
      total += option.years;
    }
    return LifeEstimate._(
      birth: profile.birthDate,
      country: country,
      baseYears: base,
      factors: factors,
      adjustmentYears: total.clamp(
        minLifestyleAdjustment,
        maxLifestyleAdjustment,
      ),
    );
  }

  final DateTime birth;
  final CountryLifeExpectancy country;
  final double baseYears;
  final List<EstimateFactor> factors;
  final double adjustmentYears;

  double get expectedYears => baseYears + adjustmentYears;

  DateTime get end => birth.add(
    Duration(microseconds: (expectedYears * _microsPerYear).round()),
  );

  LifeSnapshot at(DateTime now) => LifeSnapshot._(this, now);

  /// An honest range for the end of the estimate, e.g. (2061, 2068).
  /// Population data can't do better than a few years either way.
  (int, int) get endYearRange {
    DateTime at(double years) =>
        birth.add(Duration(microseconds: (years * _microsPerYear).round()));
    return (at(expectedYears - 3.5).year, at(expectedYears + 3.5).year);
  }

  /// "around 2061–2068".
  String get rangeLabel {
    final (from, to) = endYearRange;
    return 'around $from–$to';
  }

  /// 0-based index of the week containing [day] in the life grid.
  int weekIndexOf(DateTime day) => at(day).weeksLived;
}

/// The estimate seen from a particular moment.
class LifeSnapshot {
  LifeSnapshot._(this.estimate, this.now)
    : lived = now.difference(estimate.birth),
      remaining = estimate.end.difference(now);

  final LifeEstimate estimate;
  final DateTime now;
  final Duration lived;

  /// Negative once the user has outlived the estimate.
  final Duration remaining;

  bool get isBonus => remaining.isNegative;

  Duration get remainingClamped => isBonus ? Duration.zero : remaining;

  double get fractionLived {
    final total = estimate.end.difference(estimate.birth).inSeconds;
    if (total <= 0) return 1;
    return (lived.inSeconds / total).clamp(0.0, 1.0);
  }

  int get ageYears => fullYearsBetween(estimate.birth, now);

  /// Week index (0–51) within the current year of life.
  int get weekOfYear {
    final b = estimate.birth;
    final lastBirthday = DateTime(b.year + ageYears, b.month, b.day);
    return (now.difference(lastBirthday).inDays ~/ 7).clamp(
      0,
      weeksPerYear - 1,
    );
  }

  /// Rows (years) in the life-in-weeks grid.
  int get gridYears => math.max(estimate.expectedYears.ceil(), ageYears + 1);

  int get weeksLived => ageYears * weeksPerYear + weekOfYear;

  int get weeksTotal => (estimate.expectedYears * weeksPerYear).round();

  double get remainingYears => remainingClamped.inMicroseconds / _microsPerYear;

  int get remainingDays => remainingClamped.inDays;

  int get remainingWeeks => remainingDays ~/ 7;

  int get remainingMonths => (remainingDays / (daysPerYear / 12)).floor();

  int get remainingHours => remainingClamped.inHours;

  int get remainingSummers => remainingYears.floor();

  int get remainingFullMoons => (remainingDays / 29.53).floor();

  /// Books at about five a year.
  int get remainingBooks => (remainingYears * 5).floor();

  /// Days lived beyond the estimate (bonus time).
  int get bonusDays => isBonus ? -remaining.inDays : 0;
}

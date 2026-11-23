import 'package:flutter_test/flutter_test.dart';
import 'package:lifemeter/data/countries.dart';
import 'package:lifemeter/models/life_estimate.dart';
import 'package:lifemeter/models/profile.dart';

void main() {
  group('fullYearsBetween', () {
    test('counts a birthday only once it has arrived', () {
      final birth = DateTime(2000, 6, 15);
      expect(fullYearsBetween(birth, DateTime(2025, 6, 14)), 24);
      expect(fullYearsBetween(birth, DateTime(2025, 6, 15)), 25);
    });

    test('handles 29 February birthdays', () {
      final birth = DateTime(2000, 2, 29);
      expect(fullYearsBetween(birth, DateTime(2025, 2, 28)), 24);
      expect(fullYearsBetween(birth, DateTime(2025, 3, 1)), 25);
    });
  });

  group('LifeEstimate', () {
    final japan = countryByCode('JP');

    test('uses the sex-specific baseline', () {
      final p = Profile(
        birthDate: DateTime(1990),
        countryCode: 'JP',
        sex: Sex.female,
      );
      expect(LifeEstimate.fromProfile(p).baseYears, japan.female);
      expect(
        LifeEstimate.fromProfile(p.copyWith(sex: Sex.unspecified)).baseYears,
        japan.average,
      );
    });

    test('applies lifestyle adjustments', () {
      final p = Profile(
        birthDate: DateTime(1990),
        countryCode: 'JP',
        sex: Sex.male,
        lifestyle: const {'smoking': 'daily', 'activity': 'active'},
      );
      final e = LifeEstimate.fromProfile(p);
      expect(e.adjustmentYears, -7);
      expect(e.expectedYears, closeTo(japan.male - 7, 1e-9));
      expect(e.factors, hasLength(2));
    });

    test('clamps stacked adjustments', () {
      final p = Profile(
        birthDate: DateTime(1990),
        countryCode: 'JP',
        lifestyle: const {
          'smoking': 'daily',
          'activity': 'rarely',
          'alcohol': 'heavy',
          'weight': 'obese',
          'diet': 'processed',
        },
      );
      expect(LifeEstimate.fromProfile(p).adjustmentYears, -15);
    });

    test('unknown country falls back to the world average', () {
      final p = Profile(birthDate: DateTime(1990), countryCode: 'ZZ');
      expect(LifeEstimate.fromProfile(p).country.code, worldCode);
    });
  });

  group('LifeSnapshot', () {
    test('tracks lived and remaining time', () {
      final e = LifeEstimate.fromProfile(
        Profile(
          birthDate: DateTime(2000, 1, 1),
          countryCode: 'JP',
          sex: Sex.male,
        ),
      );
      final s = e.at(DateTime(2040, 1, 1));
      expect(s.ageYears, 40);
      expect(s.weekOfYear, 0);
      expect(s.weeksLived, 40 * 52);
      expect(s.isBonus, isFalse);
      expect(s.fractionLived, closeTo(40 / e.expectedYears, 0.001));
      expect(s.remainingSummers, (e.expectedYears - 40).floor());
    });

    test('enters bonus time past the estimate', () {
      final e = LifeEstimate.fromProfile(
        Profile(birthDate: DateTime(1920, 1, 1), countryCode: 'NG'),
      );
      final s = e.at(DateTime(2026, 1, 1));
      expect(s.isBonus, isTrue);
      expect(s.remainingDays, 0);
      expect(s.bonusDays, greaterThan(0));
      expect(s.fractionLived, 1);
      expect(s.gridYears, greaterThanOrEqualTo(s.ageYears + 1));
    });
  });

  test('Profile survives a JSON round trip', () {
    final p = Profile(
      name: 'Ada',
      birthDate: DateTime(1991, 3, 4),
      countryCode: 'NP',
      sex: Sex.female,
      lifestyle: const {'diet': 'whole'},
      intention: 'Write the book',
    );
    final back = Profile.fromJson(p.toJson())!;
    expect(back.name, p.name);
    expect(back.birthDate, p.birthDate);
    expect(back.countryCode, p.countryCode);
    expect(back.sex, p.sex);
    expect(back.lifestyle, p.lifestyle);
    expect(back.intention, p.intention);
  });
}

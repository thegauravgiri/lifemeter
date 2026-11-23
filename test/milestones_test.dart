import 'package:flutter_test/flutter_test.dart';
import 'package:lifemeter/models/life_estimate.dart';
import 'package:lifemeter/models/milestones.dart';
import 'package:lifemeter/models/profile.dart';

void main() {
  final e = LifeEstimate.fromProfile(
    Profile(birthDate: DateTime(2000, 1, 1), countryCode: 'JP'),
  );

  test('10,000 days falls on the right date', () {
    final m = milestonesFor(e).firstWhere((m) => m.value == 10000);
    expect(m.date, DateTime(2027, 5, 19));
  });

  test('next milestone and its countdown', () {
    final m = nextMilestone(e, DateTime(2027, 4, 8))!;
    expect(m.title, '10,000 days old');
    expect(m.daysFrom(DateTime(2027, 4, 8)), 41);
    expect(m.countdown(DateTime(2027, 4, 8)), '10,000 days old in 41 days');
    expect(m.countdown(DateTime(2027, 5, 19)), '10,000 days old today');
  });

  test('week milestones use the app week count', () {
    final w = milestonesFor(
      e,
    ).firstWhere((m) => m.kind == MilestoneKind.week && m.value == 1000);
    // Week 1,000 starts 999 weeks in: 19 years and 11 weeks.
    expect(e.at(w.date).weeksLived + 1, 1000);
  });

  test('noon is half way through the estimate', () {
    final noon = milestonesFor(e).firstWhere((m) => m.value == 50);
    expect(e.at(noon.date).fractionLived, closeTo(0.5, 0.001));
  });

  test('includes every landmark, in date order, and runs out', () {
    final all = milestonesFor(e);
    expect(
      all.map((m) => m.value).toSet(),
      containsAll([10000, 12500, 15000, 20000, 1000, 2000, 3000, 50]),
    );
    for (var i = 1; i < all.length; i++) {
      expect(!all[i].date.isBefore(all[i - 1].date), isTrue);
    }
    expect(nextMilestone(e, DateTime(2100)), isNull);
  });
}

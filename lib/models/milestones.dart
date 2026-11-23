import 'package:intl/intl.dart';

import 'life_estimate.dart';

/// First day of week [index] (0-based) as LifeMeter counts weeks: 52 per
/// year of life, restarting on each birthday.
DateTime weekStart(DateTime birth, int index) {
  final year = index ~/ weeksPerYear;
  final week = index % weeksPerYear;
  final birthday = DateTime(birth.year + year, birth.month, birth.day);
  return birthday.add(Duration(days: week * 7));
}

/// Last day of week [index]: the day before the next week (or birthday).
DateTime weekEnd(DateTime birth, int index) =>
    weekStart(birth, index + 1).subtract(const Duration(days: 1));

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

enum MilestoneKind { days, week, fraction }

/// A temporal landmark worth celebrating (and sharing).
class Milestone {
  const Milestone({
    required this.kind,
    required this.value,
    required this.date,
    required this.title,
    required this.unit,
    required this.note,
  });

  final MilestoneKind kind;

  /// The number on the share card (10000, 2000, 50).
  final int value;
  final DateTime date;

  /// "10,000 days old".
  final String title;

  /// The words after the big number on a card ("days old").
  final String unit;

  /// A short, hopeful line for the card.
  final String note;

  /// Whole days from [now] until the milestone (0 on the day).
  int daysFrom(DateTime now) => _day(date).difference(_day(now)).inDays;

  /// "10,000 days old in 41 days" / "… today" / "… tomorrow".
  String countdown(DateTime now) {
    final d = daysFrom(now);
    if (d == 0) return '$title today';
    if (d == 1) return '$title tomorrow';
    return '$title in ${_n.format(d)} days';
  }
}

final _n = NumberFormat.decimalPattern('en_US');

/// Every milestone in a life, in date order.
List<Milestone> milestonesFor(LifeEstimate e) {
  final b = e.birth;
  final total = e.end.difference(b);
  final list = <Milestone>[
    for (final d in const [10000, 12500, 15000, 20000])
      Milestone(
        kind: MilestoneKind.days,
        value: d,
        date: _day(b).add(Duration(days: d)),
        title: '${_n.format(d)} days old',
        unit: 'days old',
        note: d == 10000
            ? 'A second birthday. Worth a cake.'
            : 'Every one of them counts.',
      ),
    for (final w in const [1000, 2000, 3000])
      Milestone(
        kind: MilestoneKind.week,
        value: w,
        date: weekStart(b, w - 1),
        title: 'Week ${_n.format(w)}',
        unit: 'weeks in',
        note: 'A fresh box. A good week to start something.',
      ),
    Milestone(
      kind: MilestoneKind.fraction,
      value: 33,
      date: _day(b.add(total ~/ 3)),
      title: 'A third of the way',
      unit: '8 AM in my life',
      note: 'The morning’s in full swing.',
    ),
    Milestone(
      kind: MilestoneKind.fraction,
      value: 50,
      date: _day(b.add(total ~/ 2)),
      title: 'Noon in your life',
      unit: 'noon in my life',
      note: 'Half the day still ahead, and the light is good.',
    ),
  ]..sort((a, c) => a.date.compareTo(c.date));
  return list;
}

/// The next milestone on or after today, or null if none are left.
Milestone? nextMilestone(LifeEstimate e, DateTime now) {
  for (final m in milestonesFor(e)) {
    if (m.daysFrom(now) >= 0) return m;
  }
  return null;
}

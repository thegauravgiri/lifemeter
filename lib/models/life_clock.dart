/// The Life Clock: the estimated lifespan mapped onto one 24-hour day.
///
/// 0.0 is midnight at birth, 0.5 is noon, 1.0 is the end of the estimate.
/// Most people installing LifeMeter land in the morning, which is the
/// point: most of the day is still ahead.
library;

const _minutesPerDay = 24 * 60;

/// Minutes since midnight for [fraction] of the day (0–1439).
int lifeClockMinutes(double fraction) {
  if (fraction.isNaN || fraction <= 0) return 0;
  if (fraction >= 1) return _minutesPerDay - 1;
  // A hair of tolerance so 0.9 × 1440 doesn't floor to 1295.
  return (fraction * _minutesPerDay + 1e-6).floor().clamp(
    0,
    _minutesPerDay - 1,
  );
}

/// The clock face for [fraction] of the day: hours and minutes, plus AM/PM.
class LifeClock {
  LifeClock(double fraction)
    : bonus = !fraction.isNaN && fraction >= 1,
      minutes = lifeClockMinutes(fraction);

  /// Past the end of the estimate.
  final bool bonus;

  /// Minutes since midnight.
  final int minutes;

  int get hour24 => minutes ~/ 60;
  int get minute => minutes % 60;
  int get hour12 => hour24 % 12 == 0 ? 12 : hour24 % 12;
  String get period => hour24 < 12 ? 'AM' : 'PM';

  /// "10:48".
  String get digits => '$hour12:${minute.toString().padLeft(2, '0')}';

  /// "10:48 AM".
  String get time => '$digits $period';

  /// [phase] in the first person, for share cards ("my day").
  String get phaseMine =>
      phase.replaceAll('your', 'my').replaceAll('Your', 'My');

  /// The hopeful line under the time.
  String get phase {
    if (bonus) return 'Past midnight. Bonus time.';
    final h = minutes / 60;
    if (h < 6) return 'Your day’s barely started.';
    if (h < 12) return 'Most of your day is still ahead.';
    if (h < 17) return 'Afternoon. Plenty of light left.';
    if (h < 20) return 'Golden hour. The best light of the day.';
    return 'Evening. Make it a good one.';
  }
}

/// "h:mm AM/PM" for [fraction] of a life mapped onto one day.
///
/// 0.0 → 12:00 AM, 0.25 → 6:00 AM, 0.45 → 10:48 AM, 0.5 → 12:00 PM,
/// 0.9 → 9:36 PM. At 1.0 or more the clock stops at 11:59 PM; check
/// [LifeClock.bonus] for the bonus-time state.
String lifeClockTime(double fraction) => LifeClock(fraction).time;

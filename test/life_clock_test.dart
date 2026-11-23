import 'package:flutter_test/flutter_test.dart';
import 'package:lifemeter/models/life_clock.dart';

void main() {
  test('maps a fraction of life onto one day', () {
    expect(lifeClockTime(0.0), '12:00 AM');
    expect(lifeClockTime(0.25), '6:00 AM');
    expect(lifeClockTime(0.45), '10:48 AM');
    expect(lifeClockTime(0.5), '12:00 PM');
    expect(lifeClockTime(0.9), '9:36 PM');
  });

  test('past the estimate is bonus time, never negative', () {
    for (final f in [1.0, 1.2, 5.0]) {
      final c = LifeClock(f);
      expect(c.bonus, isTrue);
      expect(c.minutes, inInclusiveRange(0, 1439));
      expect(c.phase, contains('Bonus'));
    }
    expect(lifeClockTime(-0.3), '12:00 AM');
    expect(lifeClockTime(double.nan), '12:00 AM');
  });

  test('hopeful phase copy by time of day', () {
    expect(LifeClock(0.1).phase, contains('barely started'));
    expect(LifeClock(0.45).phase, contains('still ahead'));
    expect(LifeClock(0.6).phase, contains('Afternoon'));
    expect(LifeClock(0.75).phase, contains('Golden hour'));
    expect(LifeClock(0.9).phase, contains('Evening'));
    expect(LifeClock(0.45).phaseMine, 'Most of my day is still ahead.');
  });
}

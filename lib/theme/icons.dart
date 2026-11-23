import 'package:flutter/widgets.dart';

/// The Phosphor icons LifeMeter uses (MIT; fonts bundled in assets/fonts).
/// Bold weight throughout; Fill for the pinned star and week stamps.
abstract final class LMIcons {
  static const _bold = 'PhosphorBold';
  static const _fill = 'PhosphorFill';

  static const arrowCounterClockwise = IconData(0xe038, fontFamily: _bold);
  static const arrowLeft = IconData(
    0xe058,
    fontFamily: _bold,
    matchTextDirection: true,
  );
  static const arrowRight = IconData(
    0xe06c,
    fontFamily: _bold,
    matchTextDirection: true,
  );
  static const caretRight = IconData(
    0xe13a,
    fontFamily: _bold,
    matchTextDirection: true,
  );
  static const caretDown = IconData(0xe136, fontFamily: _bold);
  static const caretUpDown = IconData(0xe140, fontFamily: _bold);
  static const calendarPlus = IconData(0xe714, fontFamily: _bold);
  static const check = IconData(0xe182, fontFamily: _bold);
  static const checkCircle = IconData(0xe184, fontFamily: _bold);
  static const download = IconData(0xe20c, fontFamily: _bold);
  static const export = IconData(0xeaf0, fontFamily: _bold);
  static const gearSix = IconData(0xe272, fontFamily: _bold);
  static const globe = IconData(0xe288, fontFamily: _bold);
  static const image = IconData(0xe2ca, fontFamily: _bold);
  static const info = IconData(0xe2ce, fontFamily: _bold);
  static const lockSimple = IconData(0xe308, fontFamily: _bold);
  static const magnifyingGlass = IconData(0xe30c, fontFamily: _bold);
  static const minus = IconData(0xe32a, fontFamily: _bold);
  static const pencilSimple = IconData(0xe3b4, fontFamily: _bold);
  static const plus = IconData(0xe3d4, fontFamily: _bold);
  static const star = IconData(0xe46a, fontFamily: _bold);
  static const starFill = IconData(0xe46a, fontFamily: _fill);
  static const sunHorizon = IconData(0xe5b6, fontFamily: _bold);
  static const trash = IconData(0xe4a6, fontFamily: _bold);
  static const userPlus = IconData(0xe4d0, fontFamily: _bold);
  static const x = IconData(0xe4f6, fontFamily: _bold);
}

/// Stamps a week memory can carry, in place of emoji (which don't render
/// the same everywhere). Stored by [id].
class WeekStamp {
  const WeekStamp(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;

  static const all = [
    WeekStamp('heart', 'Love', IconData(0xe2a8, fontFamily: 'PhosphorFill')),
    WeekStamp('sun', 'Good day', IconData(0xe472, fontFamily: 'PhosphorFill')),
    WeekStamp('trip', 'Trip', IconData(0xe5d6, fontFamily: 'PhosphorFill')),
    WeekStamp(
      'peak',
      'Big moment',
      IconData(0xe7ae, fontFamily: 'PhosphorFill'),
    ),
    WeekStamp(
      'party',
      'Celebration',
      IconData(0xe81a, fontFamily: 'PhosphorFill'),
    ),
    WeekStamp('book', 'Learned', IconData(0xe0e6, fontFamily: 'PhosphorFill')),
    WeekStamp(
      'food',
      'Good food',
      IconData(0xe262, fontFamily: 'PhosphorFill'),
    ),
    WeekStamp('music', 'Music', IconData(0xe340, fontFamily: 'PhosphorFill')),
  ];

  static WeekStamp? byId(String? id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}

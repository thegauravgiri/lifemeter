import 'package:flutter/material.dart';

import '../models/life_clock.dart';
import '../models/life_estimate.dart';
import '../models/milestones.dart';
import '../data/site.dart';
import '../theme/theme.dart';
import 'controls.dart';
import 'logo_mark.dart';
import 'riso.dart';
import 'weeks_grid.dart';

/// What a share card may show. Deliberately small: never the birth date,
/// country or habit answers, and the first name only when asked.
class ShareData {
  const ShareData({
    required this.snapshot,
    this.name = '',
    this.marked = const {},
    this.milestone,
    this.personLabel,
    this.personVisits,
  });

  final LifeSnapshot snapshot;
  final String name;
  final Set<int> marked;
  final Milestone? milestone;
  final String? personLabel;
  final int? personVisits;

  bool get hasPerson => personLabel != null && personVisits != null;
}

enum ShareTemplate {
  clock('Life clock'),
  weeks('Life in weeks'),
  milestone('Milestone'),
  person('People'),
  lockScreen('Lock screen');

  const ShareTemplate(this.label);
  final String label;

  /// Logical size; rendered at 3x (1080 wide).
  Size get size =>
      this == lockScreen ? const Size(360, 780) : const Size(360, 640);
}

/// A 9:16 card designed for the feed: a cobalt block with grain, a huge
/// number with a pink misregistration, one line of context, and the
/// wordmark with "What time is it in your life?".
///
/// Always drawn with the light palette so a card looks the same whichever
/// theme the sender uses.
class ShareCard extends StatelessWidget {
  const ShareCard({
    super.key,
    required this.template,
    required this.data,
    this.showName = false,
    this.cobalt = true,
  });

  final ShareTemplate template;
  final ShareData data;
  final bool showName;

  /// Cobalt block (default) or light paper.
  final bool cobalt;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildTheme(LMPalette.light),
      child: Builder(builder: _card),
    );
  }

  Widget _card(BuildContext context) {
    final p = context.lm;
    final size = template.size;
    final c = _CardColors(p, cobalt);
    return MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: SizedBox.fromSize(
        size: size,
        child: RisoBlock(
          radius: 0,
          color: c.bg,
          grain: cobalt,
          padding: EdgeInsets.fromLTRB(
            28,
            template == ShareTemplate.lockScreen ? 250 : 36,
            28,
            28,
          ),
          child: DefaultTextStyle(
            style: context.type.body.copyWith(color: c.fg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: switch (template) {
                    ShareTemplate.clock => _clock(context, c),
                    ShareTemplate.weeks => _weeks(context, c),
                    ShareTemplate.milestone => _milestone(context, c),
                    ShareTemplate.person => _person(context, c),
                    ShareTemplate.lockScreen => _lock(context, c),
                  },
                ),
                if (template != ShareTemplate.lockScreen) _footer(context, c),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _first => data.name.trim().split(RegExp(r'\s+')).first;

  bool get _named => showName && _first.isNotEmpty;

  TextStyle _line(BuildContext context, _CardColors c, [double size = 30]) =>
      context.type.headline.copyWith(fontSize: size, color: c.fg, height: 1.1);

  Widget _big(BuildContext context, _CardColors c, String text, double size) =>
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Misregistered(
          text,
          // Full line height (not the tight 0.86 used in the UI) so the
          // numeral's ascent clears the headline above it.
          style: context.type.display.copyWith(
            fontSize: size,
            color: c.number,
            height: 1.0,
            leadingDistribution: TextLeadingDistribution.even,
          ),
          shadow: c.shadow,
          offset: 4,
        ),
      );

  Widget _clock(BuildContext context, _CardColors c) {
    final s = data.snapshot;
    final clock = LifeClock(s.isBonus ? 1 : s.fractionLived);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('It’s', style: _line(context, c, 34)),
        const SizedBox(height: 14),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: clock.bonus
              ? Misregistered(
                  'BONUS',
                  style: context.type.display.copyWith(
                    fontSize: 150,
                    color: c.number,
                  ),
                  shadow: c.shadow,
                  offset: 4,
                )
              : ClockFace(
                  digits: clock.digits,
                  period: clock.period,
                  size: 160,
                  color: c.number,
                  shadow: c.shadow,
                ),
        ),
        const SizedBox(height: 16),
        Text(
          _named ? 'in $_first’s life.' : 'in my life.',
          style: _line(context, c, 34),
        ),
        const SizedBox(height: 10),
        Text(
          clock.phaseMine,
          style: context.type.bodyLarge.copyWith(color: c.muted, fontSize: 19),
        ),
        const Spacer(),
        LifeProgress(
          fraction: s.fractionLived,
          line: c.fg,
          sun: c.shadow,
          years: s.estimate.expectedYears,
          badge: '${(s.fractionLived * 100).round()}% lived',
          height: 96,
          animate: false,
        ),
        const SizedBox(height: 14),
        if (!s.isBonus)
          Text(
            '${formatCount(s.remainingWeeks)} weeks ahead · about ${formatCount(s.remainingSummers)} summers',
            style: context.type.label.copyWith(color: c.muted, fontSize: 16),
          ),
        const SizedBox(height: 22),
      ],
    );
  }

  Widget _weeks(BuildContext context, _CardColors c) {
    final s = data.snapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _named ? '$_first’s life in weeks' : 'My life in weeks',
          style: _line(context, c, 32),
        ),
        const SizedBox(height: 8),
        Text(
          s.isBonus
              ? 'Week ${formatCount(s.weeksLived + 1)}. Every one a bonus.'
              : 'Week ${formatCount(s.weeksLived + 1)}. ${formatCount(s.remainingWeeks)} fresh boxes to go.',
          style: context.type.bodyLarge.copyWith(color: c.muted, fontSize: 18),
        ),
        const SizedBox(height: 22),
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: QuiltPainter(
              colors: c.grid,
              snapshot: s,
              marked: data.marked,
              gap: 0.26,
            ),
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  Widget _milestone(BuildContext context, _CardColors c) {
    final m = data.milestone;
    if (m == null) return _clock(context, c);
    final big = switch (m.kind) {
      MilestoneKind.fraction => m.value == 50 ? '12:00' : '8:00',
      _ => formatCount(m.value),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_milestoneKicker(m), style: _line(context, c, 34)),
        const SizedBox(height: 16),
        _big(context, c, big, 170),
        const SizedBox(height: 16),
        Text(
          m.kind == MilestoneKind.week ? 'weeks in.' : '${m.unit}.',
          style: _line(context, c, 34),
        ),
        const SizedBox(height: 10),
        Text(
          m.note,
          style: context.type.bodyLarge.copyWith(color: c.muted, fontSize: 19),
        ),
        const Spacer(),
        LifeProgress(
          fraction: data.snapshot.fractionLived,
          line: c.fg,
          sun: c.shadow,
          years: data.snapshot.estimate.expectedYears,
          badge: '${(data.snapshot.fractionLived * 100).round()}% lived',
          height: 96,
          animate: false,
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  String _milestoneKicker(Milestone m) {
    final d = m.daysFrom(DateTime.now());
    final who = _named ? '$_first is' : 'I’m';
    if (d <= 0) return m.kind == MilestoneKind.days ? 'Today $who' : 'Today:';
    return 'In ${formatCount(d)} ${d == 1 ? 'day' : 'days'}:';
  }

  Widget _person(BuildContext context, _CardColors c) {
    if (!data.hasPerson) return _clock(context, c);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About', style: _line(context, c, 34)),
        const SizedBox(height: 16),
        _big(context, c, formatCount(data.personVisits!), 190),
        const SizedBox(height: 4),
        Text(
          'more visits with ${data.personLabel}.',
          style: _line(context, c, 34),
        ),
        const SizedBox(height: 10),
        Text(
          'Going to make every one count.',
          style: context.type.bodyLarge.copyWith(color: c.muted, fontSize: 19),
        ),
        const Spacer(),
      ],
    );
  }

  /// Phone wallpaper: the clock time small, the grid below the lock-screen
  /// clock area.
  Widget _lock(BuildContext context, _CardColors c) {
    final s = data.snapshot;
    final clock = LifeClock(s.isBonus ? 1 : s.fractionLived);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          clock.bonus ? 'Bonus time' : clock.time,
          textAlign: TextAlign.center,
          style: context.type.display.copyWith(
            fontSize: 64,
            color: c.fg,
            letterSpacing: 0,
          ),
        ),
        Text(
          'in my life',
          textAlign: TextAlign.center,
          style: context.type.title.copyWith(color: c.fg, fontSize: 22),
        ),
        const SizedBox(height: 4),
        Text(
          'Week ${formatCount(s.weeksLived + 1)} · make it count',
          textAlign: TextAlign.center,
          style: context.type.label.copyWith(color: c.muted, fontSize: 15),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: CustomPaint(
            size: Size.infinite,
            painter: QuiltPainter(
              colors: c.grid,
              snapshot: s,
              marked: data.marked,
              gap: 0.26,
            ),
          ),
        ),
        const SizedBox(height: 90),
      ],
    );
  }

  Widget _footer(BuildContext context, _CardColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(height: 1.5, color: c.fg.withValues(alpha: 0.35)),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox.square(
              dimension: 30,
              child: CustomPaint(
                painter: LogoPainter(LogoMark.cobalt, drawTile: !cobalt),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'LifeMeter',
              style: context.type.title.copyWith(color: c.fg, fontSize: 19),
            ),
            const Spacer(),
            Text(
              Site.host,
              style: context.type.small.copyWith(color: c.muted, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'What time is it in your life?',
          style: context.type.title.copyWith(color: c.fg, fontSize: 22),
        ),
      ],
    );
  }
}

class _CardColors {
  _CardColors(LMPalette p, bool cobalt)
    : bg = cobalt ? p.brand : p.bg,
      fg = cobalt ? p.onBrand : p.ink,
      muted = cobalt ? p.onBrandMuted : p.inkMuted,
      number = cobalt ? p.onBrand : p.brand,
      shadow = p.accent,
      grid = cobalt ? GridColors.onBrand(p) : GridColors.of(p);

  final Color bg;
  final Color fg;
  final Color muted;
  final Color number;
  final Color shadow;
  final GridColors grid;
}

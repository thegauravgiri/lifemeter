import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/life_clock.dart';
import '../../models/life_estimate.dart';
import '../../models/profile.dart';
import '../../theme/icons.dart';
import '../../theme/theme.dart';
import '../../widgets/controls.dart';
import '../../widgets/inputs.dart';
import '../../widgets/riso.dart';
import '../../widgets/weeks_grid.dart';

/// The reveal, the moment people screenshot:
///  1. The grid fills row by row (a light tick each decade).
///  2. This week's pink square pulses once.
///  3. The cobalt slab slides up and the clock counts up to "10:48 AM"
///     while the sun climbs its arc.
///  4. Name (optional), then "Make them count" or "Share my time".
/// Tap anywhere to skip the animation.
class RevealStep extends StatefulWidget {
  const RevealStep({
    super.key,
    required this.profile,
    required this.name,
    required this.onContinue,
    required this.onShare,
  });

  final Profile profile;
  final TextEditingController name;
  final VoidCallback onContinue;
  final VoidCallback onShare;

  @override
  State<RevealStep> createState() => _RevealStepState();
}

class _RevealStepState extends State<RevealStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..addListener(_tick);

  late final LifeSnapshot _s = LifeEstimate.fromProfile(
    widget.profile,
  ).at(DateTime.now());

  static const _fillEnd = 0.52;
  int _decade = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.value = 1;
    } else if (_c.value == 0 && !_c.isAnimating) {
      _c.forward();
    }
  }

  /// A light haptic tick each decade as the grid fills.
  void _tick() {
    final fill = (_c.value / _fillEnd).clamp(0.0, 1.0);
    final rows = (Curves.easeOut.transform(fill) * _s.ageYears).floor();
    final decade = rows ~/ 10;
    if (decade > _decade) {
      _decade = decade;
      HapticFeedback.lightImpact();
    }
  }

  Animation<double> _interval(
    double begin,
    double end, [
    Curve curve = Curves.easeOut,
  ]) => CurvedAnimation(
    parent: _c,
    curve: Interval(begin, end, curve: curve),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final p = context.lm;
    final fill = _interval(0, _fillEnd, Curves.easeOut);
    final pulse = _interval(_fillEnd, 0.64);
    final slab = _interval(0.56, 0.72, Curves.easeOutCubic);
    final count = _interval(0.6, 0.86, Curves.easeOutCubic);
    final cta = _interval(0.82, 1.0);
    final s = _s;

    return AnimatedBuilder(
      animation: Listenable.merge([_c, widget.name]),
      builder: (context, _) {
        final name = widget.name.text.trim();
        final f = s.isBonus ? 1.0 : s.fractionLived * count.value;
        final clock = LifeClock(s.isBonus ? 1 : f);
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _c.isAnimating ? () => _c.value = 1 : null,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                LMSpace.gutter,
                LMSpace.md,
                LMSpace.gutter,
                LMSpace.md,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - LMSpace.md * 2,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Your life, in weeks. You are week ${formatCount(s.weeksLived + 1)}.',
                        style: t.small,
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 130),
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: QuiltPainter(
                              colors: GridColors.of(p),
                              snapshot: s,
                              fill: fill.value,
                              showNow: pulse.value > 0,
                              pulseValue: () => pulse.value,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: LMSpace.md),
                      Opacity(
                        opacity: slab.value,
                        child: Transform.translate(
                          offset: Offset(0, 40 * (1 - slab.value)),
                          child: _slab(context, clock, name, f),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: cta.value,
                        child: IgnorePointer(
                          ignoring: cta.value < 0.5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: widget.name,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.done,
                                maxLength: 30,
                                style: t.label.copyWith(fontSize: 17),
                                decoration: lmInputDecoration(
                                  context,
                                  hint: 'What should we call you? (optional)',
                                ).copyWith(counterText: ''),
                              ),
                              const SizedBox(height: 12),
                              PrimaryButton(
                                label: 'Make them count',
                                onPressed: widget.onContinue,
                              ),
                              const SizedBox(height: 8),
                              PrimaryButton(
                                label: 'Share my time',
                                icon: LMIcons.export,
                                tone: ButtonTone.outline,
                                onPressed: widget.onShare,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'An estimate from population data, not a prediction.',
                                textAlign: TextAlign.center,
                                style: t.caption,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _slab(BuildContext context, LifeClock clock, String name, double f) {
    final t = context.type;
    final p = context.lm;
    final s = _s;
    final who = name.isEmpty ? 'in your life.' : 'in your life, $name.';
    return RisoBlock(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('It’s', style: t.title.copyWith(color: p.onBrand)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: clock.bonus
                ? Misregistered(
                    'Bonus time',
                    style: t.display.copyWith(fontSize: 96, color: p.onBrand),
                    shadow: p.accent,
                  )
                : ClockFace(
                    digits: clock.digits,
                    period: clock.period,
                    size: 108,
                    color: p.onBrand,
                    shadow: p.accent,
                  ),
          ),
          const SizedBox(height: 8),
          Text(who, style: t.title.copyWith(color: p.onBrand)),
          const SizedBox(height: 2),
          Text(
            LifeClock(s.isBonus ? 1 : s.fractionLived).phase,
            style: t.body.copyWith(color: p.onBrandMuted),
          ),
          const SizedBox(height: 10),
          LifeProgress(
            fraction: f,
            line: p.onBrand,
            sun: p.accent,
            years: _s.estimate.expectedYears,
            badge: '${(f * 100).round()}% lived',
            height: 88,
            animate: false,
          ),
          const SizedBox(height: 8),
          Text(
            s.isBonus
                ? 'Every week from here is a gift.'
                : '${formatCount(s.remainingWeeks)} weeks · about ${formatCount(s.remainingSummers)} summers',
            style: t.label.copyWith(color: p.onBrand, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

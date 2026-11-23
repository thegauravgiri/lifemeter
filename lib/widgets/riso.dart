import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Riso grain: fine light and dark specks at about 6% coverage, painted
/// over cobalt blocks and share cards only. Deterministic, so it doesn't
/// shimmer between frames.
class GrainPainter extends CustomPainter {
  const GrainPainter({this.seed = 7, this.strength = 1});

  final int seed;

  /// 1 is the standard riso grain.
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final count = (size.width * size.height / 9).round().clamp(0, 120000);
    var state = seed * 2654435761 & 0x7fffffff;
    double next() {
      state = (state * 1103515245 + 12345) & 0x7fffffff;
      return state / 0x7fffffff;
    }

    Float32List points() {
      final list = Float32List(count * 2);
      for (var i = 0; i < count; i++) {
        list[i * 2] = next() * size.width;
        list[i * 2 + 1] = next() * size.height;
      }
      return list;
    }

    final light = Paint()
      ..color = Colors.white.withValues(alpha: 0.10 * strength)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.square;
    final dark = Paint()
      ..color = Colors.black.withValues(alpha: 0.10 * strength)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.square;
    canvas.drawRawPoints(ui.PointMode.points, points(), light);
    canvas.drawRawPoints(ui.PointMode.points, points(), dark);
  }

  @override
  bool shouldRepaint(GrainPainter old) =>
      old.seed != seed || old.strength != strength;
}

/// A flat cobalt block with riso grain: the hero slab, the welcome field,
/// share cards.
class RisoBlock extends StatelessWidget {
  const RisoBlock({
    super.key,
    required this.child,
    this.color,
    this.radius = LMRadius.slab,
    this.padding = EdgeInsets.zero,
    this.grain = true,
  });

  final Widget child;
  final Color? color;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool grain;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(
        color: color ?? context.lm.brand,
        child: Stack(
          children: [
            if (grain)
              const Positioned.fill(
                child: RepaintBoundary(
                  child: IgnorePointer(
                    child: CustomPaint(painter: GrainPainter()),
                  ),
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// Text with a pink copy printed 3px right and 3px down beneath it: the
/// riso misregistration. Only for the biggest numerals.
class Misregistered extends StatelessWidget {
  const Misregistered(
    this.text, {
    super.key,
    required this.style,
    required this.shadow,
    this.offset = 3,
  });

  final String text;
  final TextStyle style;
  final Color shadow;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Transform.translate(
          offset: Offset(offset, offset),
          child: ExcludeSemantics(
            child: Text(text, style: style.copyWith(color: shadow)),
          ),
        ),
        Text(text, style: style),
      ],
    );
  }
}

/// "10:48 AM" set as a poster: huge digits, a smaller AM/PM beside them.
class ClockFace extends StatelessWidget {
  const ClockFace({
    super.key,
    required this.digits,
    required this.period,
    required this.size,
    required this.color,
    this.shadow,
  });

  final String digits;
  final String period;
  final double size;
  final Color color;

  /// Pink misregistration under the digits (reveal and share cards).
  final Color? shadow;

  @override
  Widget build(BuildContext context) {
    final big = context.type.display.copyWith(fontSize: size, color: color);
    final small = big.copyWith(fontSize: size * 0.4, letterSpacing: 0);
    Widget text(String s, TextStyle style) => shadow == null
        ? Text(s, style: style)
        : Misregistered(s, style: style, shadow: shadow!);
    return Semantics(
      label: '$digits $period',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            text(digits, big),
            SizedBox(width: size * 0.06),
            text(period, small),
          ],
        ),
      ),
    );
  }
}

/// The life meter: a thick rounded bar of life lived, a tall pink "now"
/// knob with a glow, a "45% lived" badge riding above it, and decade ticks
/// underneath. The fill sweeps in when it first appears.
class LifeProgress extends StatelessWidget {
  const LifeProgress({
    super.key,
    required this.fraction,
    required this.line,
    required this.sun,
    this.years,
    this.badge,
    this.badgeInk = const Color(0xFF15161D),
    this.height = 76,
    this.animate = true,
  });

  final double fraction;

  /// Track and fill colour (the fill is solid, the track is faint).
  final Color line;

  /// The "now" knob and badge.
  final Color sun;

  /// Expected lifespan in years, for a tick every decade.
  final double? years;

  /// Text in the badge above the knob, e.g. "45% lived".
  final String? badge;
  final Color badgeInk;
  final double height;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final target = fraction.clamp(0.0, 1.0);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final type = context.type;
    return Semantics(
      label: '${(target * 100).round()} percent of your life lived',
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: animate && !reduce ? 0 : target, end: target),
        duration: const Duration(milliseconds: 1600),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: LifeProgressPainter(
              fraction: v,
              line: line,
              sun: sun,
              years: years,
              badge: badge,
              badgeStyle: type.label.copyWith(
                color: badgeInk,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LifeProgressPainter extends CustomPainter {
  LifeProgressPainter({
    required this.fraction,
    required this.line,
    required this.sun,
    this.years,
    this.badge,
    this.badgeStyle,
  });

  final double fraction;
  final Color line;
  final Color sun;
  final double? years;
  final String? badge;
  final TextStyle? badgeStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final bar = math.min(26.0, size.height * 0.34);
    const tickH = 6.0;
    final barBottom = size.height - tickH - 4;
    final barTop = barBottom - bar;
    final r = Radius.circular(bar / 2);
    final x = (w * fraction).clamp(bar / 2, w - bar / 2);

    // Track and fill.
    canvas.drawRRect(
      RRect.fromLTRBR(0, barTop, w, barBottom, r),
      Paint()..color = line.withValues(alpha: line.a * 0.18),
    );
    if (fraction > 0) {
      canvas.drawRRect(
        RRect.fromLTRBR(0, barTop, math.max(bar, x), barBottom, r),
        Paint()..color = line,
      );
    }

    // Decade ticks under the bar.
    final y = years;
    if (y != null && y > 10) {
      final tick = Paint()
        ..color = line.withValues(alpha: line.a * 0.55)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      for (var d = 10; d < y; d += 10) {
        final tx = w * d / y;
        canvas.drawLine(
          Offset(tx, barBottom + 4),
          Offset(tx, barBottom + 4 + tickH),
          tick,
        );
      }
    }

    // The "now" knob: taller than the bar, ringed, glowing.
    final knobW = bar * 0.62;
    final knob = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(x, (barTop + barBottom) / 2),
        width: knobW,
        height: bar + 16,
      ),
      Radius.circular(knobW / 2),
    );
    canvas.drawRRect(
      knob.inflate(4),
      Paint()
        ..color = sun.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawRRect(knob.inflate(3), Paint()..color = line);
    canvas.drawRRect(knob, Paint()..color = sun);

    // Badge above the knob.
    final text = badge;
    if (text != null && badgeStyle != null) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: badgeStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      const padH = 10.0, padV = 4.0;
      final bw = tp.width + padH * 2;
      final bh = tp.height + padV * 2;
      final top = knob.top - 8 - bh;
      if (top >= 0) {
        final left = (x - bw / 2).clamp(0.0, w - bw);
        canvas.drawRRect(
          RRect.fromLTRBR(
            left,
            top,
            left + bw,
            top + bh,
            Radius.circular(bh / 2),
          ),
          Paint()..color = sun,
        );
        // A small pointer down to the knob.
        final px = x.clamp(left + 8, left + bw - 8);
        canvas.drawPath(
          Path()
            ..moveTo(px - 5, top + bh - 0.5)
            ..lineTo(px + 5, top + bh - 0.5)
            ..lineTo(px, top + bh + 5)
            ..close(),
          Paint()..color = sun,
        );
        tp.paint(canvas, Offset(left + padH, top + padV));
      }
    }
  }

  @override
  bool shouldRepaint(LifeProgressPainter old) =>
      old.fraction != fraction ||
      old.line != line ||
      old.sun != sun ||
      old.years != years ||
      old.badge != badge ||
      old.badgeStyle != badgeStyle;
}

/// The brand mark's sun: a pink half-disc rising on a white horizon made of
/// week squares. Used on the welcome screen.
class SunriseArt extends StatelessWidget {
  const SunriseArt({super.key, required this.rise});

  /// 0 = below the horizon, 1 = half risen.
  final double rise;

  @override
  Widget build(BuildContext context) {
    final p = context.lm;
    return CustomPaint(
      painter: _SunrisePainter(rise: rise, sun: p.accent, line: p.onBrand),
    );
  }
}

class _SunrisePainter extends CustomPainter {
  _SunrisePainter({required this.rise, required this.sun, required this.line});

  final double rise;
  final Color sun;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    const cols = 26;
    final cell = size.width / cols;
    final side = cell * 0.72;
    final horizon = size.height - cell * 2;
    final r = size.width * 0.34;
    final centre = Offset(size.width * 0.5, horizon + r * (1 - rise));
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, horizon - cell * 0.3));
    canvas.drawCircle(centre, r, Paint()..color = sun);
    canvas.restore();
    final paint = Paint()..color = line;
    for (var row = 0; row < 2; row++) {
      for (var i = 0; i < cols; i++) {
        final x = i * cell + (cell - side) / 2;
        final y = horizon + row * cell + (cell - side) / 2;
        paint.color = row == 0 ? line : line.withValues(alpha: 0.32);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, side, side),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SunrisePainter old) => old.rise != rise;
}

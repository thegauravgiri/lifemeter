import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/life_estimate.dart';
import '../theme/theme.dart';

/// The four cell states, and the colours they take.
class GridColors {
  const GridColors({
    required this.lived,
    required this.future,
    required this.now,
    required this.marked,
    required this.ring,
  });

  /// On the page background.
  factory GridColors.of(LMPalette p) => GridColors(
    lived: p.weekLived,
    future: p.weekFuture,
    now: p.weekNow,
    marked: p.weekMarked,
    ring: p.nowRing,
  );

  /// On a cobalt block: white lived weeks, faint white ahead.
  factory GridColors.onBrand(LMPalette p) => GridColors(
    lived: p.onBrand,
    future: p.onBrand.withValues(alpha: 0.24),
    now: p.accent,
    marked: p.accent,
    ring: p.brand,
  );

  final Color lived;
  final Color future;
  final Color now;
  final Color marked;
  final Color ring;

  @override
  bool operator ==(Object other) =>
      other is GridColors &&
      other.lived == lived &&
      other.future == future &&
      other.now == now &&
      other.marked == marked &&
      other.ring == ring;

  @override
  int get hashCode => Object.hash(lived, future, now, marked, ring);
}

/// Text labels in the left margin: where each decade starts.
String gridRowLabel(int year) => year == 0 ? 'Born' : '${year}s';

/// "Your life in weeks": one row per year, 52 squares per row. Lived weeks
/// are cobalt, weeks ahead are pale, weeks with a memory are pink, and this
/// week is a larger pink square with a ring. Tap a square to open it.
class WeeksGrid extends StatefulWidget {
  const WeeksGrid({
    super.key,
    required this.snapshot,
    this.marked = const {},
    this.onTapWeek,
  });

  final LifeSnapshot snapshot;

  /// Week indexes with a memory.
  final Set<int> marked;
  final ValueChanged<int>? onTapWeek;

  @override
  State<WeeksGrid> createState() => _WeeksGridState();
}

class _WeeksGridState extends State<WeeksGrid> with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final AnimationController _stamp = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );
  int? _stamped;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _pulse.value = 1;
    } else if (!_pulse.isAnimating && _pulse.value == 0) {
      _pulse.forward();
    }
  }

  @override
  void didUpdateWidget(WeeksGrid old) {
    super.didUpdateWidget(old);
    final added = widget.marked.difference(old.marked);
    if (added.length == 1) {
      _stamped = added.single;
      final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (!reduce) _stamp.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _stamp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.snapshot;
    final p = context.lm;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cell = (width - QuiltPainter.labelGutter) / weeksPerYear;
        final size = Size(width, cell * s.gridYears);
        return Semantics(
          label:
              'Life in weeks. ${s.weeksLived} weeks lived of about ${s.weeksTotal}. '
              '${widget.marked.length} weeks with a memory.',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: widget.onTapWeek == null
                ? null
                : (d) {
                    final x = d.localPosition.dx - QuiltPainter.labelGutter;
                    if (x < 0) return;
                    final col = (x / cell).floor().clamp(0, weeksPerYear - 1);
                    final row = (d.localPosition.dy / cell).floor().clamp(
                      0,
                      s.gridYears - 1,
                    );
                    widget.onTapWeek!(row * weeksPerYear + col);
                  },
            child: RepaintBoundary(
              child: CustomPaint(
                size: size,
                painter: QuiltPainter(
                  colors: GridColors.of(p),
                  snapshot: s,
                  marked: widget.marked,
                  labelStyle: context.type.small.copyWith(
                    fontSize: 10,
                    color: p.inkMuted,
                  ),
                  pulse: Listenable.merge([_pulse, _stamp]),
                  pulseValue: () => _pulse.value,
                  stamped: _stamped,
                  stampValue: () => _stamp.value,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Paints the life grid. Shared by home (with margin labels), the reveal
/// (filling in row by row over [fill]) and the share cards.
class QuiltPainter extends CustomPainter {
  QuiltPainter({
    required this.colors,
    required this.snapshot,
    this.marked = const {},
    this.labelStyle,
    Listenable? pulse,
    this.pulseValue,
    this.stamped,
    this.stampValue,
    this.fill = 1,
    this.showNow = true,
    this.gap = 0.22,
  }) : super(repaint: pulse);

  static const labelGutter = 32.0;

  final GridColors colors;
  final LifeSnapshot snapshot;
  final Set<int> marked;

  /// Decade labels in the margin; null hides the label column.
  final TextStyle? labelStyle;

  /// The one-off ring pulse around this week (0 → 1).
  final double Function()? pulseValue;

  /// A freshly marked week, scaled by [stampValue] (0 → 1).
  final int? stamped;
  final double Function()? stampValue;

  /// Fraction of lived weeks filled in, row by row (the reveal).
  final double fill;
  final bool showNow;

  /// Space between squares, as a fraction of the cell.
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final s = snapshot;
    final years = s.gridYears;
    final gutter = labelStyle == null ? 0.0 : labelGutter;
    final cell = math.min(
      (size.width - gutter) / weeksPerYear,
      size.height / years,
    );
    final gridWidth = cell * weeksPerYear + gutter;
    final ox = (size.width - gridWidth) / 2 + gutter;
    final side = cell * (1 - gap);
    final radius = math.min(LMRadius.cell, side * 0.3);
    final age = s.ageYears;
    final week = s.weekOfYear;
    final nowIndex = age * weeksPerYear + week;
    final filled = (s.weeksLived * fill).round();

    final lived = Paint()..color = colors.lived;
    final future = Paint()..color = colors.future;
    final beyond = Paint()
      ..color = colors.future.withValues(alpha: colors.future.a * 0.5);
    final mark = Paint()..color = colors.marked;

    RRect cellAt(int index, [double scale = 1]) {
      final y = index ~/ weeksPerYear, w = index % weeksPerYear;
      return RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(ox + w * cell + cell / 2, y * cell + cell / 2),
          width: side * scale,
          height: side * scale,
        ),
        Radius.circular(radius * scale),
      );
    }

    for (var y = 0; y < years; y++) {
      if (labelStyle != null && y % 10 == 0) {
        _label(canvas, gridRowLabel(y), y * cell + cell / 2, ox - gutter);
      }
      for (var w = 0; w < weeksPerYear; w++) {
        final index = y * weeksPerYear + w;
        if (index == nowIndex && showNow) continue;
        if (index == stamped) continue;
        final isLived = index < s.weeksLived;
        final Paint paint;
        if (isLived && index >= filled) {
          paint = future;
        } else if (marked.contains(index) && index <= nowIndex) {
          paint = mark;
        } else if (isLived) {
          paint = lived;
        } else {
          paint = y + w / weeksPerYear > s.estimate.expectedYears
              ? beyond
              : future;
        }
        canvas.drawRRect(
          cellAt(index, identical(paint, mark) ? 1.3 : 1),
          paint,
        );
      }
    }

    final st = stamped;
    if (st != null && st != nowIndex && marked.contains(st)) {
      final t = Curves.easeOut.transform(stampValue?.call() ?? 1);
      canvas.drawRRect(cellAt(st, 1.6 - 0.6 * t), mark);
    }

    if (!showNow || age >= years) return;

    // This week: larger, pink, with a ring that separates it from its
    // neighbours (≥3:1), pulsing in once.
    final t = Curves.easeOut.transform(pulseValue?.call() ?? 1);
    final nowScale = 1.5 + (1 - t) * 0.8;
    canvas.drawRRect(
      cellAt(nowIndex, nowScale + 2 * 2 / side),
      Paint()..color = colors.ring,
    );
    canvas.drawRRect(cellAt(nowIndex, nowScale), Paint()..color = colors.now);
  }

  void _label(Canvas canvas, String text, double cy, double x) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: labelGutter - 4);
    tp.paint(canvas, Offset(x, cy - tp.height / 2));
  }

  @override
  bool shouldRepaint(QuiltPainter old) =>
      old.colors != colors ||
      old.fill != fill ||
      old.showNow != showNow ||
      old.stamped != stamped ||
      old.marked.length != marked.length ||
      !old.marked.containsAll(marked) ||
      old.snapshot.weeksLived != snapshot.weeksLived ||
      old.snapshot.gridYears != snapshot.gridYears ||
      old.snapshot.estimate.expectedYears != snapshot.estimate.expectedYears;
}

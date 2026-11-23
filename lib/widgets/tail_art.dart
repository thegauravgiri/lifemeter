import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Pictograms for the "tail end" cards, drawn in one ink like a riso print.
enum TailArt { sun, weekend, moon, books, fireworks, sunrise }

class TailPictogram extends StatelessWidget {
  const TailPictogram(
    this.art, {
    super.key,
    required this.color,
    this.size = 48,
  });

  final TailArt art;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _TailPainter(art, color)),
    ),
  );
}

class _TailPainter extends CustomPainter {
  const _TailPainter(this.art, this.color);

  final TailArt art;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(s / 2, s / 2);
    final fill = Paint()
      ..color = color
      ..isAntiAlias = true;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.07
      ..strokeCap = StrokeCap.round;
    // Cut-outs show the card colour through the ink.
    final cut = Paint()..blendMode = BlendMode.dstOut;

    switch (art) {
      case TailArt.sun:
        canvas.drawCircle(c, s * 0.2, fill);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          final d = Offset(math.cos(a), math.sin(a));
          canvas.drawLine(c + d * s * 0.31, c + d * s * 0.45, stroke);
        }
      case TailArt.weekend:
        // A calendar page: weekdays are dots, Saturday and Sunday are
        // filled squares.
        final page = RRect.fromLTRBR(
          s * 0.02,
          s * 0.1,
          s * 0.98,
          s * 0.94,
          Radius.circular(s * 0.1),
        );
        canvas.drawRRect(
          page,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.06,
        );
        canvas.save();
        canvas.clipRRect(page);
        canvas.drawRect(Rect.fromLTRB(0, 0, s, s * 0.3), fill);
        canvas.restore();
        final cell = s * 0.84 / 7;
        for (var row = 0; row < 3; row++) {
          for (var i = 0; i < 7; i++) {
            final centre = Offset(
              s * 0.08 + cell * (i + 0.5),
              s * 0.42 + row * cell * 1.25,
            );
            if (i >= 5) {
              canvas.drawRRect(
                RRect.fromRectAndRadius(
                  Rect.fromCenter(
                    center: centre,
                    width: cell * 0.82,
                    height: cell * 0.82,
                  ),
                  Radius.circular(cell * 0.18),
                ),
                fill,
              );
            } else {
              canvas.drawCircle(centre, cell * 0.16, fill);
            }
          }
        }
      case TailArt.moon:
        canvas.saveLayer(Offset.zero & size, Paint());
        canvas.drawCircle(c, s * 0.4, fill);
        cut.color = const Color(0x66000000);
        canvas.drawCircle(c + Offset(-s * 0.13, -s * 0.1), s * 0.09, cut);
        canvas.drawCircle(c + Offset(s * 0.14, s * 0.02), s * 0.06, cut);
        canvas.drawCircle(c + Offset(-s * 0.02, s * 0.18), s * 0.07, cut);
        canvas.drawCircle(c + Offset(s * 0.08, -s * 0.2), s * 0.04, cut);
        canvas.restore();
      case TailArt.books:
        canvas.saveLayer(Offset.zero & size, Paint());
        final base = s * 0.9;
        final spines = [
          (s * 0.06, s * 0.16, s * 0.62),
          (s * 0.25, s * 0.15, s * 0.72),
          (s * 0.43, s * 0.18, s * 0.56),
        ];
        for (final (x, w, h) in spines) {
          canvas.drawRRect(
            RRect.fromLTRBR(
              x,
              base - h,
              x + w,
              base,
              Radius.circular(s * 0.025),
            ),
            fill,
          );
          cut.color = const Color(0xFF000000);
          canvas.drawRect(Rect.fromLTWH(x, base - h * 0.78, w, s * 0.035), cut);
        }
        // One book leaning on the stack.
        canvas.save();
        canvas.translate(s * 0.66, base);
        canvas.rotate(0.32);
        canvas.drawRRect(
          RRect.fromLTRBR(0, -s * 0.6, s * 0.16, 0, Radius.circular(s * 0.025)),
          fill,
        );
        canvas.restore();
        canvas.drawRect(Rect.fromLTWH(0, base, s, s * 0.05), fill);
        canvas.restore();
      case TailArt.fireworks:
        canvas.drawCircle(c, s * 0.06, fill);
        for (var i = 0; i < 12; i++) {
          final a = i * math.pi / 6;
          final d = Offset(math.cos(a), math.sin(a));
          final long = i.isEven;
          canvas.drawLine(
            c + d * s * 0.14,
            c + d * s * (long ? 0.36 : 0.28),
            Paint()
              ..color = color
              ..strokeWidth = s * 0.05
              ..strokeCap = StrokeCap.round,
          );
          canvas.drawCircle(c + d * s * (long ? 0.44 : 0.35), s * 0.035, fill);
        }
      case TailArt.sunrise:
        final horizon = s * 0.62;
        canvas.drawArc(
          Rect.fromCircle(center: Offset(s / 2, horizon), radius: s * 0.3),
          math.pi,
          math.pi,
          true,
          fill,
        );
        canvas.drawLine(
          Offset(s * 0.04, horizon + s * 0.06),
          Offset(s * 0.96, horizon + s * 0.06),
          stroke,
        );
        canvas.drawLine(
          Offset(s * 0.2, horizon + s * 0.2),
          Offset(s * 0.8, horizon + s * 0.2),
          stroke,
        );
        canvas.drawLine(
          Offset(s * 0.36, horizon + s * 0.33),
          Offset(s * 0.64, horizon + s * 0.33),
          stroke,
        );
    }
  }

  @override
  bool shouldRepaint(_TailPainter old) => old.art != art || old.color != color;
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/countries.dart';
import '../../data/lifestyle.dart';
import '../../data/site.dart';
import '../../models/profile.dart';
import '../../state/life_controller.dart';
import '../../theme/theme.dart';

/// Explains exactly how the number was produced, with sources.
class AboutEstimateScreen extends StatelessWidget {
  const AboutEstimateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final controller = context.watch<LifeController>();
    final estimate = controller.estimate;
    final profile = controller.profile;

    String signed(double y) =>
        '${y >= 0 ? '+' : '−'}${y.abs().toStringAsFixed(1)} yrs';

    return Scaffold(
      appBar: AppBar(title: const Text('How we estimate')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          LMSpace.gutter,
          LMSpace.md,
          LMSpace.gutter,
          LMSpace.xxl,
        ),
        children: [
          Text(
            'LifeMeter starts from the average lifespan where you live, then nudges it '
            'for a few habits with strong evidence behind them.',
            style: t.bodyLarge,
          ),
          if (estimate != null && profile != null) ...[
            const SizedBox(height: LMSpace.xl),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: context.lm.line),
                ),
              ),
              child: Column(
                children: [
                  _Line(
                    '${estimate.country.name} · ${profile.sex == Sex.unspecified ? 'average' : profile.sex.label.toLowerCase()}',
                    '${estimate.baseYears.toStringAsFixed(1)} yrs',
                  ),
                  for (final f in estimate.factors)
                    if (f.years != 0) _Line(f.label, signed(f.years)),
                  if (estimate.factors.fold<double>(0, (a, f) => a + f.years) !=
                      estimate.adjustmentYears)
                    const _Line('Capped to a plausible range', ''),
                  const Divider(height: 28),
                  _Line(
                    'Your estimate',
                    '${estimate.expectedYears.toStringAsFixed(1)} yrs',
                    strong: true,
                  ),
                  _Line('As a range', estimate.rangeLabel),
                ],
              ),
            ),
          ],
          const SizedBox(height: LMSpace.xl),
          Text('What this is not', style: t.title),
          const SizedBox(height: LMSpace.sm),
          Text(
            'This is a population average, not a forecast of when anyone will die, and it '
            'is never a death date. LifeMeter shows it as a range on purpose. Genes, healthcare, '
            'relationships, luck and many other things matter. Life expectancy at birth '
            'also understates how long older people typically live, because they have '
            'already survived the earlier risks. Treat the number as a prompt, not a verdict.',
            style: t.body,
          ),
          const SizedBox(height: LMSpace.xl),
          Text('Sources', style: t.title),
          const SizedBox(height: LMSpace.sm),
          const _Source('Country & sex averages', lifeExpectancySource),
          for (final q in lifestyleQuestions) _Source(q.title, q.source),
          const _Source(
            'Life in weeks',
            'Inspired by Tim Urban, “Your Life in Weeks”, and Oliver Burkeman, “Four Thousand Weeks”',
          ),
          const SizedBox(height: LMSpace.md),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => openSite(context, Site.method),
              child: const Text('Read the full method online'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value, {this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final style = strong
        ? t.title.copyWith(fontSize: 20)
        : t.body.copyWith(color: context.lm.ink);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(
            value,
            style: (strong ? style : t.label).copyWith(
              fontFeatures: LMText.tnum,
            ),
          ),
        ],
      ),
    );
  }
}

class _Source extends StatelessWidget {
  const _Source(this.topic, this.citation);

  final String topic;
  final String citation;

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(topic, style: t.label.copyWith(fontSize: 15)),
          const SizedBox(height: 2),
          Text(citation, style: t.caption),
        ],
      ),
    );
  }
}

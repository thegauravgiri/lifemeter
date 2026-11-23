/// Optional lifestyle questions asked during onboarding.
///
/// Each option carries a conservative adjustment (in years) relative to the
/// population average. These are coarse, evidence-informed nudges, not a
/// clinical model — the app presents the result as an estimate.
class LifestyleOption {
  const LifestyleOption(this.id, this.label, this.years, {this.detail});

  final String id;
  final String label;
  final String? detail;
  final double years;
}

class LifestyleQuestion {
  const LifestyleQuestion({
    required this.id,
    required this.title,
    required this.prompt,
    required this.why,
    required this.source,
    required this.options,
  });

  /// Stable key used for persistence.
  final String id;

  /// Short label for settings rows ("Smoking").
  final String title;

  /// The question as asked during onboarding.
  final String prompt;

  /// One-line explanation of why it matters.
  final String why;

  /// Citation shown under the question.
  final String source;

  final List<LifestyleOption> options;

  LifestyleOption? option(String? id) {
    for (final o in options) {
      if (o.id == id) return o;
    }
    return null;
  }
}

/// Bounds on the total lifestyle adjustment, so stacked answers never
/// produce an implausible estimate.
const minLifestyleAdjustment = -15.0;
const maxLifestyleAdjustment = 8.0;

const lifestyleQuestions = <LifestyleQuestion>[
  LifestyleQuestion(
    id: 'smoking',
    title: 'Smoking',
    prompt: 'Do you smoke?',
    why:
        'Smoking is the single largest lifestyle factor. Quitting — at any age — wins most of it back.',
    source: 'Jha et al., NEJM 2013',
    options: [
      LifestyleOption('never', 'Never', 0),
      LifestyleOption(
        'former',
        'I quit',
        -2,
        detail: 'Most of the loss is recovered',
      ),
      LifestyleOption('sometimes', 'Occasionally', -5),
      LifestyleOption('daily', 'Daily', -10),
    ],
  ),
  LifestyleQuestion(
    id: 'activity',
    title: 'Movement',
    prompt: 'How much do you move each week?',
    why:
        '150 minutes of brisk activity a week is linked to several extra years of life.',
    source: 'Moore et al., PLOS Medicine 2012',
    options: [
      LifestyleOption('rarely', 'Rarely', -2, detail: 'Mostly sitting'),
      LifestyleOption('some', 'Some', 0, detail: 'Under 150 minutes'),
      LifestyleOption(
        'active',
        'Active',
        3,
        detail: '150+ minutes of brisk activity',
      ),
    ],
  ),
  LifestyleQuestion(
    id: 'alcohol',
    title: 'Alcohol',
    prompt: 'How many drinks in a typical week?',
    why:
        'Above roughly 7 drinks a week, each extra drink shortens life a little.',
    source: 'Wood et al., The Lancet 2018',
    options: [
      LifestyleOption('none', 'None or rarely', 0),
      LifestyleOption('light', '1 – 7', 0),
      LifestyleOption('moderate', '8 – 14', -1),
      LifestyleOption('heavy', 'More than 14', -4),
    ],
  ),
  LifestyleQuestion(
    id: 'weight',
    title: 'Body weight',
    prompt: 'How would you describe your weight?',
    why: 'Obesity is associated with a loss of a few years on average.',
    source: 'Prospective Studies Collaboration, The Lancet 2009',
    options: [
      LifestyleOption('healthy', 'Healthy range', 0, detail: 'BMI 18.5 – 25'),
      LifestyleOption('over', 'A bit over', -1, detail: 'BMI 25 – 30'),
      LifestyleOption('obese', 'Well over', -3, detail: 'BMI 30+'),
      LifestyleOption('unsure', "I'm not sure", 0),
    ],
  ),
  LifestyleQuestion(
    id: 'diet',
    title: 'Diet',
    prompt: 'What does most of your food look like?',
    why:
        'Diets rich in whole foods, legumes and vegetables are linked to longer lives.',
    source: 'Fadnes et al., PLOS Medicine 2022',
    options: [
      LifestyleOption(
        'whole',
        'Mostly whole foods',
        2,
        detail: 'Vegetables, legumes, grains',
      ),
      LifestyleOption('mixed', 'A mix', 0),
      LifestyleOption(
        'processed',
        'Mostly processed',
        -2,
        detail: 'Fast food, sugary drinks',
      ),
    ],
  ),
];

LifestyleQuestion? lifestyleQuestion(String id) {
  for (final q in lifestyleQuestions) {
    if (q.id == id) return q;
  }
  return null;
}

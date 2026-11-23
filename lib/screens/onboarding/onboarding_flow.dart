import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/lifestyle.dart';
import '../../models/life_clock.dart';
import '../../models/life_estimate.dart';
import '../../models/profile.dart';
import '../../state/life_controller.dart';
import '../../theme/icons.dart';
import '../../theme/theme.dart';
import '../../widgets/controls.dart';
import '../../widgets/inputs.dart';
import '../../widgets/logo_mark.dart';
import '../../widgets/riso.dart';
import '../../widgets/share_card.dart';
import '../share/share_sheet.dart';
import 'reveal_step.dart';

enum _Kind { welcome, birth, country, sex, reveal, lifestyle, intention }

class _Step {
  const _Step(this.kind, [this.question]);
  final _Kind kind;
  final LifestyleQuestion? question;
}

/// Welcome → birthday → country → sex → reveal, in about 30 seconds. The
/// habit questions ("Sharpen your estimate") and the one thing come after
/// the payoff, and both can be skipped.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  static final _steps = [
    const _Step(_Kind.welcome),
    const _Step(_Kind.birth),
    const _Step(_Kind.country),
    const _Step(_Kind.sex),
    const _Step(_Kind.reveal),
    for (final q in lifestyleQuestions) _Step(_Kind.lifestyle, q),
    const _Step(_Kind.intention),
  ];

  static const _questions = [_Kind.birth, _Kind.country, _Kind.sex];

  int _index = 0;
  bool _forward = true;
  Timer? _advanceTimer;

  final _name = TextEditingController();
  final _intention = TextEditingController();
  DateTime _birth = DateTime(1995, 6, 15);
  String? _country;
  Sex? _sex;
  final Map<String, String> _lifestyle = {};

  _Step get _step => _steps[_index];

  @override
  void initState() {
    super.initState();
    _intention.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _name.dispose();
    _intention.dispose();
    super.dispose();
  }

  Profile _draft({bool habits = true}) => Profile(
    name: _name.text.trim(),
    birthDate: _birth,
    countryCode: _country ?? 'XX',
    sex: _sex ?? Sex.unspecified,
    lifestyle: habits ? Map.of(_lifestyle) : const {},
    intention: _intention.text.trim(),
  );

  void _go(int index) {
    _advanceTimer?.cancel();
    FocusScope.of(context).unfocus();
    setState(() {
      _forward = index > _index;
      _index = index.clamp(0, _steps.length - 1);
    });
  }

  void _next() => _go(_index + 1);

  void _back() => _go(_index - 1);

  /// Gives the selection a beat to register before moving on.
  void _advanceSoon() {
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 320), () {
      if (mounted) _next();
    });
  }

  void _skipLifestyle() =>
      _go(_steps.indexWhere((s) => s.kind == _Kind.intention));

  Future<void> _finish() async {
    final controller = context.read<LifeController>();
    final draft = _draft();
    await controller.save(draft);
    // The one thing is the pinned top of the bucket list.
    await controller.addBucketItem(draft.intention);
  }

  void _share() {
    final snapshot = LifeEstimate.fromProfile(_draft()).at(DateTime.now());
    showShareSheet(
      context,
      ShareData(snapshot: snapshot, name: _name.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.lm;
    final kind = _step.kind;
    final welcome = kind == _Kind.welcome;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle(p, onBrand: welcome),
      child: PopScope(
        canPop: _index == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: welcome ? p.brand : p.bg,
          body: welcome
              ? RisoBlock(
                  radius: 0,
                  child: SafeArea(child: _Welcome(onBegin: _next)),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      if (_questions.contains(kind))
                        _TopBar(
                          index: _questions.indexOf(kind),
                          count: _questions.length,
                          onBack: _back,
                        )
                      else if (kind == _Kind.lifestyle)
                        _TopBar(
                          index: lifestyleQuestions.indexOf(_step.question!),
                          count: lifestyleQuestions.length,
                          onBack: _back,
                          onSkip: _skipLifestyle,
                        )
                      else if (kind == _Kind.intention)
                        _TopBar(onBack: _back),
                      Expanded(child: _animated()),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _animated() => AnimatedSwitcher(
    duration: const Duration(milliseconds: 280),
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    transitionBuilder: (child, anim) {
      final incoming = child.key == ValueKey(_index);
      final dx = (incoming == _forward) ? 0.05 : -0.05;
      return FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(anim),
          child: child,
        ),
      );
    },
    child: KeyedSubtree(key: ValueKey(_index), child: _buildStep()),
  );

  Widget _buildStep() {
    switch (_step.kind) {
      case _Kind.welcome:
        return const SizedBox.shrink();
      case _Kind.birth:
        return _QuestionLayout(
          title: 'When did your day begin?',
          subtitle: 'Your birthday is midnight on your life clock.',
          action: PrimaryButton(label: 'Continue', onPressed: _next),
          child: BirthDatePicker(
            value: _birth,
            onChanged: (d) => setState(() => _birth = d),
          ),
        );
      case _Kind.country:
        return _QuestionLayout(
          title: 'Where do you live?',
          subtitle: 'It shapes the estimate more than anything else.',
          expand: true,
          action: PrimaryButton(
            label: 'Continue',
            onPressed: _country == null ? null : _next,
          ),
          child: CountryPicker(
            selected: _country,
            onSelected: (c) => setState(() => _country = c),
          ),
        );
      case _Kind.sex:
        return _QuestionLayout(
          title: 'Sex at birth',
          subtitle:
              'Why we ask: life expectancy tables differ by sex at birth.',
          child: SexChoice(
            value: _sex,
            onChanged: (s) {
              setState(() => _sex = s);
              _advanceSoon();
            },
          ),
        );
      case _Kind.reveal:
        return RevealStep(
          profile: _draft(habits: false),
          name: _name,
          onContinue: _next,
          onShare: _share,
        );
      case _Kind.lifestyle:
        final q = _step.question!;
        final number = lifestyleQuestions.indexOf(q) + 1;
        return _QuestionLayout(
          header: _SharpenHeader(
            base: _draft(habits: false),
            current: _draft(),
          ),
          eyebrow:
              'Sharpen your estimate · $number of ${lifestyleQuestions.length}',
          title: q.prompt,
          child: LifestyleChoice(
            question: q,
            value: _lifestyle[q.id],
            onChanged: (id) {
              setState(() => _lifestyle[q.id] = id);
              _advanceSoon();
            },
          ),
        );
      case _Kind.intention:
        return _IntentionStep(
          controller: _intention,
          profile: _draft(),
          onDone: _finish,
        );
    }
  }
}

/// Back button, progress as week squares (done cobalt, now pink), and an
/// optional Skip.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, this.index, this.count, this.onSkip});

  final int? index;
  final int? count;
  final VoidCallback onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final p = context.lm;
    final i = index, n = count;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            RoundIconButton(
              onPressed: onBack,
              tooltip: 'Back',
              icon: LMIcons.arrowLeft,
            ),
            const SizedBox(width: 8),
            if (i != null && n != null)
              Semantics(
                label: 'Step ${i + 1} of $n',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var k = 0; k < n; k++)
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: k < i
                                ? p.weekLived
                                : (k == i ? p.accent : p.weekFuture),
                            borderRadius: BorderRadius.circular(LMRadius.cell),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const Spacer(),
            if (onSkip != null) LinkButton(label: 'Skip', onPressed: onSkip),
          ],
        ),
      ),
    );
  }
}

class _QuestionLayout extends StatelessWidget {
  const _QuestionLayout({
    required this.title,
    required this.child,
    this.subtitle,
    this.eyebrow,
    this.header,
    this.action,
    this.expand = false,
  });

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final Widget? header;
  final Widget child;
  final Widget? action;

  /// Let [child] fill remaining height (for scrolling lists).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final top = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ?header,
        if (eyebrow != null) ...[Kicker(eyebrow!), const SizedBox(height: 8)],
        Text(title, style: t.headline),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: t.body),
        ],
        const SizedBox(height: LMSpace.lg),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LMSpace.gutter,
        LMSpace.md,
        LMSpace.gutter,
        LMSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (expand) ...[
            top,
            Expanded(child: child),
          ] else
            Expanded(
              child: SingleChildScrollView(
                clipBehavior: Clip.none,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [top, child],
                ),
              ),
            ),
          if (action != null) ...[const SizedBox(height: LMSpace.md), action!],
        ],
      ),
    );
  }
}

/// The life clock as it moves with each habit answer, with the change in
/// years. Cobalt or ink, never red: habits are levers, not verdicts.
class _SharpenHeader extends StatelessWidget {
  const _SharpenHeader({required this.base, required this.current});

  final Profile base;
  final Profile current;

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final p = context.lm;
    final now = DateTime.now();
    final before = LifeEstimate.fromProfile(base);
    final after = LifeEstimate.fromProfile(current);
    final delta = after.expectedYears - before.expectedYears;
    final fraction = after.at(now).fractionLived;
    final deltaText = delta.abs() < 0.05 ? '±0 yrs' : _years(delta);
    return Padding(
      padding: const EdgeInsets.only(bottom: LMSpace.lg),
      child: RisoBlock(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your life clock',
                    style: t.small.copyWith(color: p.onBrandMuted),
                  ),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: fraction),
                    duration: Duration(
                      milliseconds: reduceMotion(context) ? 0 : 600,
                    ),
                    curve: Curves.easeOutCubic,
                    builder: (context, f, _) {
                      final clock = LifeClock(f);
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: ClockFace(
                          digits: clock.digits,
                          period: clock.period,
                          size: 52,
                          color: p.onBrand,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Container(
                key: ValueKey(deltaText),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: p.onBrand,
                  borderRadius: BorderRadius.circular(LMRadius.chip),
                ),
                child: Text(
                  deltaText,
                  style: t.button.copyWith(color: p.brand, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntentionStep extends StatelessWidget {
  const _IntentionStep({
    required this.controller,
    required this.profile,
    required this.onDone,
  });

  final TextEditingController controller;
  final Profile profile;
  final Future<void> Function() onDone;

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final p = context.lm;
    final s = LifeEstimate.fromProfile(profile).at(DateTime.now());
    final empty = controller.text.trim().isEmpty;
    return _QuestionLayout(
      title: 'If you only did one thing with the time ahead, what would it be?',
      action: PrimaryButton(
        label: empty ? 'Skip' : 'Start my clock',
        onPressed: onDone,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntentionField(controller: controller),
          if (!s.isBonus) ...[
            const SizedBox(height: LMSpace.lg),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.pinkSoft,
                borderRadius: BorderRadius.circular(LMRadius.slab),
              ),
              child: Row(
                children: [
                  WeekSquare(color: p.accent, size: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'About ${formatCount(s.remainingDays)} days to do it. Today is one of them.',
                      style: t.label.copyWith(color: p.ink),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Welcome extends StatefulWidget {
  const _Welcome({required this.onBegin});

  final VoidCallback onBegin;

  @override
  State<_Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<_Welcome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rise = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _rise.value = 1;
    } else if (_rise.value == 0 && !_rise.isAnimating) {
      _rise.forward();
    }
  }

  @override
  void dispose() {
    _rise.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fills the screen on tall phones; scrolls on short ones.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(child: _content(context)),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final t = context.type;
    final p = context.lm;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LMSpace.gutter,
        LMSpace.lg,
        LMSpace.gutter,
        LMSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          AspectRatio(
            aspectRatio: 1.9,
            child: AnimatedBuilder(
              animation: _rise,
              builder: (context, _) =>
                  SunriseArt(rise: Curves.easeOutCubic.transform(_rise.value)),
            ),
          ),
          const SizedBox(height: LMSpace.xl),
          Text(
            'What time is it in your life?',
            style: t.display.copyWith(
              fontSize: 74,
              height: 0.9,
              letterSpacing: -0.5,
              color: p.onBrand,
            ),
          ),
          const SizedBox(height: LMSpace.md),
          Text(
            'You get about 4,000 weeks. Let’s see where you are, and make the rest count.',
            style: t.bodyLarge.copyWith(fontSize: 18, color: p.onBrandMuted),
          ),
          const Spacer(),
          const SizedBox(height: LMSpace.xl),
          PrimaryButton(
            label: 'Count mine',
            tone: ButtonTone.inverse,
            icon: LMIcons.arrowRight,
            onPressed: widget.onBegin,
          ),
          const SizedBox(height: LMSpace.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LMIcons.lockSimple, size: 15, color: p.onBrandMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Takes 30 seconds. Nothing leaves your phone.',
                  style: t.caption.copyWith(color: p.onBrandMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: LMSpace.lg),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 22,
                  child: CustomPaint(
                    painter: LogoPainter(LogoMark.cobalt, drawTile: false),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'LifeMeter',
                  style: t.title.copyWith(color: p.onBrand, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "+3 yrs", "−1 yr", "+1.8 yrs": whole numbers without a decimal.
String _years(double delta) {
  final a = (delta.abs() * 10).round() / 10;
  final v = a == a.roundToDouble()
      ? a.toStringAsFixed(0)
      : a.toStringAsFixed(1);
  return '${delta > 0 ? '+' : '−'}$v ${v == '1' ? 'yr' : 'yrs'}';
}

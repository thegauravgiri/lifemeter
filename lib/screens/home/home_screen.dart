import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/life_clock.dart';
import '../../data/site.dart';
import '../../models/life_estimate.dart';
import '../../models/milestones.dart';
import '../../services/widget_sync.dart';
import '../../services/quote_service.dart';
import '../../state/life_controller.dart';
import '../../theme/icons.dart';
import '../../theme/theme.dart';
import '../../widgets/bucket.dart';
import '../../widgets/clock.dart';
import '../../widgets/controls.dart';
import '../../widgets/logo_mark.dart';
import '../../widgets/riso.dart';
import '../../widgets/tail_art.dart';
import '../../widgets/share_card.dart';
import '../../widgets/weeks_grid.dart';
import '../bucket/bucket_list_screen.dart';
import '../people/people_sheets.dart';
import '../settings/about_estimate_screen.dart';
import '../settings/edit_sheets.dart';
import '../settings/settings_screen.dart';
import '../share/share_sheet.dart';
import 'week_sheet.dart';

/// Milestones show on home from this many days out.
const milestoneLeadDays = 60;

/// The share payload for the current moment.
ShareData shareDataFor(LifeController c, DateTime now) {
  final s = c.estimate!.at(now);
  final m = nextMilestone(c.estimate!, now);
  // The first person you added gets a card too, unless People is hidden.
  final person = c.showPeople && c.people.isNotEmpty ? c.people.first : null;
  return ShareData(
    snapshot: s,
    name: c.profile?.name ?? '',
    marked: c.memories.keys.toSet(),
    milestone: m != null && m.daysFrom(now) <= milestoneLeadDays ? m : null,
    personLabel: person?.label,
    personVisits: person == null ? null : visitsWith(c, person, now),
  );
}

/// Widest the home column gets on large screens.
const double _maxContentWidth = 720;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LifeController>();
    if (controller.estimate == null || controller.profile == null) {
      return const Scaffold();
    }
    return Scaffold(
      body: Stack(
        children: [
          Clock(
            interval: const Duration(minutes: 1),
            builder: (context, now) => _content(context, controller, now),
          ),
          const _StatusBarBand(),
        ],
      ),
    );
  }

  Widget _content(
    BuildContext context,
    LifeController controller,
    DateTime now,
  ) {
    final profile = controller.profile!;
    final s = controller.estimate!.at(now);
    final milestone = nextMilestone(controller.estimate!, now);
    final showMilestone =
        milestone != null && milestone.daysFrom(now) <= milestoneLeadDays;
    // On tablets and unfolded foldables, keep a readable centred column.
    final width = MediaQuery.sizeOf(context).width;
    final side = math.max(LMSpace.gutter, (width - _maxContentWidth) / 2);
    return CustomScrollView(
      slivers: [
        SliverSafeArea(
          sliver: SliverPadding(
            padding: EdgeInsets.fromLTRB(side, 0, side, LMSpace.xxl),
            sliver: SliverList.list(
              children: [
                const _TopBar(),
                const SizedBox(height: LMSpace.sm),
                _Hero(
                  snapshot: s,
                  unit: controller.unit,
                  name: profile.name,
                  showSeconds: controller.showSeconds,
                  slideshow: controller.slideshow,
                ),
                const SizedBox(height: LMSpace.sm),
                _ThisWeek(snapshot: s),
                if (showMilestone)
                  _MilestoneRow(milestone: milestone, now: now),
                const SizedBox(height: LMSpace.lg),
                _OneThing(intention: profile.intention, snapshot: s),
                const SizedBox(height: LMSpace.section),
                _BucketSection(snapshot: s),
                const SizedBox(height: LMSpace.section),
                _GridSection(snapshot: s),
                if (controller.showPeople) ...[
                  const SizedBox(height: LMSpace.section),
                  const _PeopleSection(),
                ],
                if (!s.isBonus) ...[
                  const SizedBox(height: LMSpace.section),
                  _TailEnd(snapshot: s),
                ],
                const _WidgetPromo(),
                const SizedBox(height: LMSpace.section),
                const _DailyQuote(),
                const SizedBox(height: LMSpace.section),
                const _Footer(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A solid band under the transparent status bar.
class _StatusBarBand extends StatelessWidget {
  const _StatusBarBand();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: top,
      child: IgnorePointer(child: ColoredBox(color: context.lm.bg)),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: LMSpace.xs),
      child: Row(
        children: [
          const Wordmark(size: 20),
          const Spacer(),
          RoundIconButton(
            icon: LMIcons.gearSix,
            tooltip: 'Settings',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }
}

/// A gentle note for temporal landmarks: Mondays and birthdays.
String? freshStartNote(LifeSnapshot s) {
  final now = s.now;
  final birth = s.estimate.birth;
  if (now.month == birth.month && now.day == birth.day) {
    return 'Happy birthday. A new row starts today.';
  }
  if (now.weekday == DateTime.monday) return 'New week. Fresh box.';
  return null;
}

class _Hero extends StatefulWidget {
  const _Hero({
    required this.snapshot,
    required this.unit,
    required this.name,
    required this.showSeconds,
    required this.slideshow,
  });

  final LifeSnapshot snapshot;
  final HeroUnit unit;
  final String name;
  final bool showSeconds;

  /// Rotate through the time views on a timer.
  final bool slideshow;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  static const _interval = Duration(seconds: 5);

  late HeroUnit _shown = widget.unit;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(_Hero old) {
    super.didUpdateWidget(old);
    if (old.slideshow != widget.slideshow) _restart();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _restart() {
    _timer?.cancel();
    if (!widget.slideshow) return;
    _timer = Timer.periodic(_interval, (_) {
      if (mounted) setState(() => _shown = _shown.next);
    });
  }

  /// A tap jumps to the next view and remembers it as the starting view.
  void _advance() {
    setState(() => _shown = _shown.next);
    context.read<LifeController>().setUnit(_shown);
    _restart();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final p = context.lm;
    final s = widget.snapshot;
    final name = widget.name;
    final showSeconds = widget.showSeconds;
    final clock = LifeClock(s.isBonus ? 1 : s.fractionLived);
    final week = formatCount(s.weeksLived + 1);
    final greeting = name.isEmpty ? 'Week $week' : '$name · week $week';
    final note = freshStartNote(s);
    final reduce = reduceMotion(context);
    final unit = s.isBonus ? HeroUnit.clock : _shown;
    final controller = context.read<LifeController>();

    final (String big, String? period, String label) = switch (unit) {
      _ when s.isBonus => ('Bonus', null, 'time, past the estimate'),
      HeroUnit.clock => (clock.digits, clock.period, 'in your life'),
      HeroUnit.weeks => (formatCount(s.remainingWeeks), null, 'weeks left'),
      HeroUnit.days => (formatCount(s.remainingDays), null, 'days left'),
      HeroUnit.hours => (formatCount(s.remainingHours), null, 'hours left'),
      // Replaced below by a live, per-second count.
      HeroUnit.seconds => (
        formatCount(s.remainingClamped.inSeconds),
        null,
        'seconds left',
      ),
      HeroUnit.summers => (
        formatCount(s.remainingSummers),
        null,
        'summers left',
      ),
      HeroUnit.percent => (
        '${(s.fractionLived * 100).round()}%',
        null,
        'of the day behind you',
      ),
    };
    final secondary = unit == HeroUnit.clock
        ? (s.isBonus
              ? 'Every week from here is a gift.'
              : '${formatCount(s.remainingWeeks)} weeks ahead · about ${formatCount(s.remainingSummers)} summers')
        : 'It’s ${clock.time} in your life.';

    return RisoBlock(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 18),
      child: Semantics(
        button: !s.isBonus,
        hint: 'Tap to change unit',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: s.isBonus ? null : _advance,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      greeting,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.label.copyWith(
                        color: p.onBrandMuted,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  RoundIconButton(
                    icon: LMIcons.export,
                    tooltip: 'Share my time',
                    foreground: p.onBrand,
                    onPressed: () => showShareSheet(
                      context,
                      shareDataFor(controller, s.now),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRect(
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: reduce ? 0 : 560),
                        // Out first, then in, so two big numbers never
                        // overlap mid-transition.
                        switchInCurve: const Interval(
                          0.5,
                          1,
                          curve: Curves.easeOutCubic,
                        ),
                        switchOutCurve: const Interval(
                          0.5,
                          1,
                          curve: Curves.easeIn,
                        ),
                        transitionBuilder: (child, anim) {
                          final incoming = child.key == ValueKey(unit);
                          return FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: Offset(0, incoming ? 0.4 : -0.4),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          );
                        },
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.bottomLeft,
                          children: [...previous, ?current],
                        ),
                        child: SizedBox(
                          key: ValueKey(unit),
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.bottomLeft,
                            child: unit == HeroUnit.seconds
                                ? Clock(
                                    interval: const Duration(seconds: 1),
                                    builder: (context, now) => Text(
                                      formatCount(
                                        s.estimate.end
                                            .difference(now)
                                            .inSeconds
                                            .clamp(0, 1 << 52),
                                      ),
                                      style: t.display.copyWith(
                                        color: p.onBrand,
                                        fontSize: 120,
                                        fontFeatures: LMText.tnum,
                                      ),
                                    ),
                                  )
                                : period == null
                                ? Text(
                                    big,
                                    style: t.display.copyWith(
                                      color: p.onBrand,
                                      fontSize: 120,
                                    ),
                                  )
                                : ClockFace(
                                    digits: big,
                                    period: period,
                                    size: 120,
                                    color: p.onBrand,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            style: t.title.copyWith(
                              color: p.onBrand,
                              fontSize: 22,
                            ),
                          ),
                        ),
                        if (!s.isBonus) ...[
                          const SizedBox(width: 6),
                          Icon(
                            LMIcons.caretUpDown,
                            size: 18,
                            color: p.onBrandMuted,
                          ),
                        ],
                      ],
                    ),
                    if (!s.isBonus) ...[
                      const SizedBox(height: 8),
                      // Where the slideshow is: one dot per time view.
                      Row(
                        children: [
                          for (final u in HeroUnit.values)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              margin: const EdgeInsets.only(right: 5),
                              width: u == unit ? 18 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: u == unit
                                    ? p.accent
                                    : p.onBrand.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(clock.phase, style: t.body.copyWith(color: p.onBrand)),
                    Text(
                      secondary,
                      style: t.caption.copyWith(color: p.onBrandMuted),
                    ),
                    if (showSeconds && !s.isBonus)
                      _SecondsLeft(estimate: s.estimate),
                    if (note != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          WeekSquare(color: p.accent, size: 10),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              note,
                              style: t.small.copyWith(color: p.onBrand),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    LifeProgress(
                      fraction: s.fractionLived,
                      line: p.onBrand,
                      sun: p.accent,
                      years: s.estimate.expectedYears,
                      badge: '${(s.fractionLived * 100).round()}% lived',
                      height: 84,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'born ${s.estimate.birth.year}',
                          style: t.small.copyWith(color: p.onBrandMuted),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s.estimate.rangeLabel,
                            style: t.small.copyWith(color: p.onBrandMuted),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opt-in: the only part of the screen that ticks every second.
class _SecondsLeft extends StatelessWidget {
  const _SecondsLeft({required this.estimate});

  final LifeEstimate estimate;

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final p = context.lm;
    return Clock(
      interval: const Duration(seconds: 1),
      builder: (context, now) {
        final secs = estimate.end.difference(now).inSeconds;
        if (secs <= 0) return const SizedBox.shrink();
        return Text(
          '${formatCount(secs)} seconds',
          style: t.ticker.copyWith(color: p.onBrandMuted),
        );
      },
    );
  }
}

/// This week's box: a fresh one every Monday, with room for one memory.
class _ThisWeek extends StatelessWidget {
  const _ThisWeek({required this.snapshot});

  final LifeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final p = context.lm;
    final index = snapshot.weeksLived;
    final memory = context.watch<LifeController>().memories[index];
    final stamp = WeekStamp.byId(memory?.stamp);
    return Semantics(
      button: true,
      label: memory == null ? 'Add a memory to this week' : null,
      child: InkWell(
        onTap: () => showWeekSheet(context, index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Stamp(
                stamped: memory != null,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: memory != null ? p.accent : p.surface,
                    borderRadius: BorderRadius.circular(LMRadius.chip),
                    border: memory != null
                        ? null
                        : Border.all(color: p.brandText, width: 2),
                  ),
                  child: memory != null
                      ? (stamp == null
                            ? null
                            : Icon(stamp.icon, size: 20, color: p.onAccent))
                      : Icon(LMIcons.plus, size: 20, color: p.brandText),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memory == null
                          ? 'Week ${formatCount(index + 1)} · a fresh box · add a memory'
                          : 'Week ${formatCount(index + 1)} · this week',
                      style: t.small,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      memory?.text ?? 'What will make it count?',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.label.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
              if (memory != null)
                Icon(LMIcons.pencilSimple, size: 20, color: p.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.milestone, required this.now});

  final Milestone milestone;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final p = context.lm;
    final today = milestone.daysFrom(now) == 0;
    return Column(
      children: [
        const Hairline(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Icon(LMIcons.sunHorizon, color: p.brandText, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  milestone.countdown(now),
                  style: t.label.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              LinkButton(
                label: today ? 'Share it' : 'Preview',
                onPressed: () => showShareSheet(
                  context,
                  shareDataFor(context.read<LifeController>(), now),
                  initial: ShareTemplate.milestone,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OneThing extends StatelessWidget {
  const _OneThing({required this.intention, required this.snapshot});

  final String intention;
  final LifeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final p = context.lm;
    final controller = context.watch<LifeController>();
    final empty = intention.isEmpty;
    final done =
        !empty && controller.bucket.any((i) => i.isDone && i.text == intention);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 14),
      decoration: BoxDecoration(
        color: p.pinkSoft,
        borderRadius: BorderRadius.circular(LMRadius.slab),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              WeekSquare(color: p.accent, size: 10),
              const SizedBox(width: 8),
              Text(
                done ? 'You did your one thing' : 'Your one thing',
                style: t.small.copyWith(color: p.ink),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              empty ? 'What would you regret not doing?' : intention,
              style: t.headline.copyWith(fontSize: 26),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              empty
                  ? 'Name it. It sits here, and on your widget.'
                  : done
                  ? 'That’s one for the story. What’s the next one thing?'
                  : snapshot.isBonus
                  ? 'Today is a good day for it.'
                  : 'About ${formatCount(snapshot.remainingDays)} days to do it. Today is one of them.',
              style: t.body.copyWith(color: p.ink, fontSize: 15),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (empty)
                Expanded(
                  child: _Left(
                    PillButton(
                      label: 'Choose one',
                      icon: LMIcons.plus,
                      onPressed: () => editIntention(context),
                    ),
                  ),
                )
              else if (done)
                Expanded(
                  child: _Left(
                    PillButton(
                      label: 'Pick the next one',
                      icon: LMIcons.arrowRight,
                      onPressed: () => editIntention(context),
                    ),
                  ),
                )
              else
                Expanded(
                  child: _Left(
                    PillButton(
                      label: 'Done!',
                      icon: LMIcons.check,
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.maybeOf(context);
                        final before = controller.bucket.toList();
                        await controller.completeIntention();
                        messenger
                          ?..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Done. That’s one for the story.',
                              ),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () =>
                                    controller.restoreBucket(before),
                              ),
                            ),
                          );
                      },
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              if (!empty)
                RoundIconButton(
                  icon: LMIcons.pencilSimple,
                  tooltip: 'Edit',
                  onPressed: () => editIntention(context),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BucketSection extends StatelessWidget {
  const _BucketSection({required this.snapshot});

  final LifeSnapshot snapshot;

  static const _preview = 3;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LifeController>();
    final items = controller.bucket;
    final open = items.where((i) => !i.isDone).toList();
    final pinnedText = controller.profile?.intention;
    final shown = open.where((i) => i.text != pinnedText).take(_preview);

    void openList() => Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BucketListScreen()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Bucket list',
          subtitle: bucketSummary(items.length, open.length, snapshot),
        ),
        const SizedBox(height: LMSpace.sm),
        for (final item in shown) ...[
          const Hairline(),
          BucketTile(item: item, dense: true),
        ],
        const Hairline(),
        const SizedBox(height: 4),
        Row(
          children: [
            LinkButton(
              label: 'Add',
              icon: LMIcons.plus,
              onPressed: () => showAddBucketItem(context),
            ),
            const Spacer(),
            if (items.isNotEmpty)
              LinkButton(
                label: 'See all ${items.length}',
                icon: LMIcons.arrowRight,
                onPressed: openList,
              ),
          ],
        ),
      ],
    );
  }
}

/// "4 to go · about 37 summers".
String bucketSummary(int total, int open, LifeSnapshot s) {
  if (total == 0) {
    return 'Name the things you want to have done.';
  }
  if (open == 0) return 'All done. Time to dream up the next one.';
  if (s.isBonus) return '$open to go.';
  return '$open to go · about ${formatCount(s.remainingSummers)} summers';
}

class _GridSection extends StatelessWidget {
  const _GridSection({required this.snapshot});

  final LifeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final memories = context.watch<LifeController>().memories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Your life in weeks',
          subtitle: memories.isEmpty
              ? 'Each row is a year. Tap a week to remember it.'
              : 'Pink weeks hold a memory. Tap any week.',
          action: LinkButton(
            label: 'Add a moment',
            onPressed: () => addMomentByDate(context),
          ),
        ),
        const SizedBox(height: LMSpace.md),
        WeeksGrid(
          snapshot: snapshot,
          marked: memories.keys.toSet(),
          onTapWeek: (i) => showWeekSheet(context, i),
        ),
      ],
    );
  }
}

class _PeopleSection extends StatelessWidget {
  const _PeopleSection();

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final p = context.lm;
    final c = context.watch<LifeController>();
    final now = DateTime.now();
    final people = c.people;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Your people',
          subtitle: people.isEmpty
              ? 'Who do you want more time with?'
              : 'Time together, counted kindly.',
          action: people.isEmpty
              ? null
              : LinkButton(
                  label: 'Add',
                  icon: LMIcons.plus,
                  onPressed: () => showPersonEditor(context),
                ),
        ),
        const SizedBox(height: LMSpace.sm),
        if (people.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: PillButton(
              label: 'Add someone',
              icon: LMIcons.userPlus,
              onPressed: () => showPersonEditor(context),
            ),
          )
        else ...[
          for (final person in people.take(3)) ...[
            const Hairline(),
            InkWell(
              onTap: () => showPersonSheet(context, person),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            person.label,
                            style: t.label.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'about '),
                                TextSpan(
                                  text: formatCount(visitsWith(c, person, now)),
                                  style: t.stat.copyWith(fontSize: 24),
                                ),
                                const TextSpan(text: ' more visits'),
                              ],
                            ),
                            style: t.caption,
                          ),
                        ],
                      ),
                    ),
                    LinkButton(
                      label: 'Plan a visit',
                      onPressed: () {
                        c.addBucketItem('Visit ${person.label}');
                        toast(
                          context,
                          'Added “Visit ${person.label}” to your list.',
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Hairline(),
          if (people.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'And ${people.length - 3} more in Settings.',
                style: t.caption.copyWith(color: p.inkMuted),
              ),
            ),
        ],
      ],
    );
  }
}

class _TailEnd extends StatelessWidget {
  const _TailEnd({required this.snapshot});

  final LifeSnapshot snapshot;

  // Each moment gets its own riso ink. Text is ink-dark or white, whichever
  // reads at AA on that ink.
  static const _ink = Color(0xFF15161D);
  static const _white = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final s = snapshot;
    // Concrete moments, not abstract time (Tim Urban, "The Tail End").
    final cards = [
      (
        s.remainingSummers,
        'summers',
        'One a year. Spend them well.',
        TailArt.sun,
        const Color(0xFFFFD23F),
        _ink,
      ),
      (
        s.remainingWeeks,
        'weekends',
        'Fewer than it feels like.',
        TailArt.weekend,
        const Color(0xFFFF48B0),
        _ink,
      ),
      (
        s.remainingFullMoons,
        'full moons',
        'Go outside for the next one.',
        TailArt.moon,
        const Color(0xFF5B3CC4),
        _white,
      ),
      (
        s.remainingBooks,
        'books',
        'At five a year. Pick good ones.',
        TailArt.books,
        const Color(0xFF00A6A0),
        _ink,
      ),
      (
        s.remainingSummers,
        'New Year’s Eves',
        'Who do you want there?',
        TailArt.fireworks,
        const Color(0xFFFF7A1A),
        _ink,
      ),
      (
        s.remainingDays,
        'sunrises',
        'Try to catch a few.',
        TailArt.sunrise,
        const Color(0xFF2340F5),
        _white,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'The tail end',
          subtitle: 'What’s ahead, counted in things worth showing up for.',
        ),
        const SizedBox(height: LMSpace.md),
        SizedBox(
          height: 214,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final (value, label, note, art, bg, fg) = cards[i];
              return SizedBox(
                width: 156,
                child: RisoBlock(
                  color: bg,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TailPictogram(art, color: fg, size: 46),
                      const Spacer(),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatCount(value),
                          style: t.stat.copyWith(fontSize: 48, color: fg),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          label,
                          maxLines: 1,
                          style: t.label.copyWith(color: fg),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.caption.copyWith(
                          color: fg.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WidgetPromo extends StatefulWidget {
  const _WidgetPromo();

  @override
  State<_WidgetPromo> createState() => _WidgetPromoState();
}

class _WidgetPromoState extends State<_WidgetPromo>
    with WidgetsBindingObserver {
  late Future<bool> _canPin = _check();

  Future<bool> _check() =>
      context.read<LifeController>().widgets.shouldPromote();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _canPin = _check());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    return FutureBuilder<bool>(
      future: _canPin,
      builder: (context, snap) {
        if (snap.data != true) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: LMSpace.section),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Keep it in sight',
                subtitle:
                    'Your life clock on your home screen. A glance a day is enough. Free, always.',
              ),
              const SizedBox(height: LMSpace.md),
              PillButton(
                label: 'Add the Life Clock widget',
                icon: LMIcons.plus,
                onPressed: () => context
                    .read<LifeController>()
                    .widgets
                    .requestPin(HomeWidgetKind.clock),
              ),
              const SizedBox(height: 4),
              Text('Or the weeks grid, in Settings.', style: t.caption),
            ],
          ),
        );
      },
    );
  }
}

/// Quote of the day (ZenQuotes, with a bundled fallback offline).
class _DailyQuote extends StatefulWidget {
  const _DailyQuote();

  @override
  State<_DailyQuote> createState() => _DailyQuoteState();
}

class _DailyQuoteState extends State<_DailyQuote> {
  late final Future<Quote> _quote = QuoteService().today();

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final p = context.lm;
    return FutureBuilder<Quote>(
      future: _quote,
      initialData: QuoteService.fallbackFor(DateTime.now()),
      builder: (context, snap) {
        final q = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('For today', style: t.small),
            const SizedBox(height: 10),
            Text(
              '“${q.text}”',
              style: t.title.copyWith(fontSize: 24, height: 1.25),
            ),
            const SizedBox(height: 10),
            Text('— ${q.author}', style: t.caption),
            if (q.fromZenQuotes) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => openSite(context, Uri.https('zenquotes.io', '/')),
                child: Text(
                  'Inspirational quotes provided by ZenQuotes API',
                  style: t.small.copyWith(
                    color: p.inkMuted,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    return Column(
      children: [
        const LogoMark(size: 28),
        const SizedBox(height: LMSpace.md),
        Text(
          'An estimate from population data, not a prediction and not medical advice.',
          textAlign: TextAlign.center,
          style: t.caption,
        ),
        LinkButton(
          label: 'How is this calculated?',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AboutEstimateScreen()),
          ),
        ),
      ],
    );
  }
}

/// Left-aligns a button inside an Expanded.
class _Left extends StatelessWidget {
  const _Left(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Align(alignment: Alignment.centerLeft, child: child);
}

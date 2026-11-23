import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/countries.dart';
import '../../services/widget_sync.dart';
import '../../state/life_controller.dart';
import '../../theme/icons.dart';
import '../../theme/theme.dart';
import '../../widgets/controls.dart';
import '../../widgets/logo_mark.dart';
import '../bucket/bucket_list_screen.dart';
import '../home/home_screen.dart';
import '../people/people_sheets.dart';
import '../share/share_sheet.dart';
import 'about_estimate_screen.dart';
import 'edit_sheets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LifeController>();
    final profile = controller.profile;
    if (profile == null) return const Scaffold();
    final country = countryByCode(profile.countryCode);
    final answered = profile.lifestyle.length;
    final t = context.type;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        leading: RoundIconButton(
          icon: LMIcons.arrowLeft,
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          LMSpace.gutter,
          0,
          LMSpace.gutter,
          LMSpace.xxl,
        ),
        children: [
          Text('Settings', style: t.headline.copyWith(fontSize: 34)),
          _Group('You', [
            _Row(
              label: 'Name',
              value: profile.name.isEmpty ? 'Not set' : profile.name,
              onTap: () => editName(context),
            ),
            _Row(
              label: 'Birthday',
              value: DateFormat.yMMMd().format(profile.birthDate),
              onTap: () => editBirthDate(context),
            ),
            _Row(
              label: 'Country',
              value: country.name,
              onTap: () => editCountry(context),
            ),
            _Row(
              label: 'Sex at birth',
              value: profile.sex.label,
              onTap: () => editSex(context),
            ),
            _Row(
              label: 'Sharpen your estimate',
              value: answered == 0
                  ? 'Five optional habit questions'
                  : '$answered of 5 answered',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LifestyleEditScreen()),
              ),
            ),
            _Row(
              label: 'Your one thing',
              value: profile.intention.isEmpty ? 'Not set' : profile.intention,
              onTap: () => editIntention(context),
            ),
            _Row(
              label: 'Bucket list',
              value: controller.bucket.isEmpty
                  ? 'Empty'
                  : '${controller.bucket.where((i) => i.isDone).length} of ${controller.bucket.length} done',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BucketListScreen()),
              ),
            ),
          ]),
          _Group('People', [
            for (final person in controller.people)
              _Row(
                label: person.label,
                value:
                    'About ${formatCount(visitsWith(controller, person, now))} more visits',
                onTap: () => showPersonSheet(context, person),
              ),
            _Row(
              label: 'Add someone',
              value: 'See how many visits are ahead, and plan one',
              onTap: () => showPersonEditor(context),
            ),
            _SwitchRow(
              label: 'Show people on home',
              value: 'Hide the section if it isn’t for you',
              on: controller.showPeople,
              onChanged: controller.setShowPeople,
            ),
          ]),
          _Group('Display', [
            _SegmentRow<AppTheme>(
              label: 'Theme',
              value: controller.theme,
              options: {for (final o in AppTheme.values) o: o.label},
              onChanged: controller.setTheme,
            ),
            _SegmentRow<HeroUnit>(
              label: 'Home opens on',
              value: controller.unit == HeroUnit.clock
                  ? HeroUnit.clock
                  : HeroUnit.weeks,
              options: const {
                HeroUnit.clock: 'Life clock',
                HeroUnit.weeks: 'Weeks',
              },
              onChanged: controller.setUnit,
            ),
            _SwitchRow(
              label: 'Slideshow',
              value:
                  'The hero rotates through clock, weeks, days, hours and more',
              on: controller.slideshow,
              onChanged: controller.setSlideshow,
            ),
            _SwitchRow(
              label: 'Show live seconds',
              value: 'A ticking count under the hero. Off by default.',
              on: controller.showSeconds,
              onChanged: controller.setShowSeconds,
            ),
          ]),
          _Group('Widgets and lock screen', [
            _Row(
              label: 'Add the Life Clock widget',
              value: '10:48 AM in your life, with the sun',
              onTap: () =>
                  _addWidget(context, controller, HomeWidgetKind.clock),
            ),
            _Row(
              label: 'Add the weeks widget',
              value: 'Every week of your life, memories in pink',
              onTap: () =>
                  _addWidget(context, controller, HomeWidgetKind.weeks),
            ),
            _Row(
              label: 'Add the countdown widget',
              value: 'Your count and your one thing',
              onTap: () =>
                  _addWidget(context, controller, HomeWidgetKind.countdown),
            ),
            _Row(
              label: 'Countdown widget shows',
              value: controller.widgetUnit == WidgetUnit.clock
                  ? 'Life clock'
                  : '${controller.widgetUnit.label} left',
              onTap: () => editWidgetUnit(context),
            ),
            _Row(
              label: 'Set as lock screen',
              value: 'Your life in weeks as your wallpaper',
              onTap: () =>
                  showLockScreenSheet(context, shareDataFor(controller, now)),
            ),
          ]),
          _Group('About the estimate', [
            _Row(
              label: 'How we estimate',
              value: controller.estimate == null
                  ? 'The method and sources'
                  : 'Your range: ${controller.estimate!.rangeLabel}',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutEstimateScreen()),
              ),
            ),
            _Row(
              label: 'Privacy',
              value: 'Everything stays on this device',
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Your data stays here'),
                  content: const Text(
                    'LifeMeter has no account and no servers. Your answers are stored only on '
                    'this device and are erased when you start over or uninstall. Share cards '
                    'never include your birth date, country or health answers.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),
            ),
            _Row(
              label: 'Licences',
              value: 'Fonts, icons and open-source packages',
              onTap: () => showLicensePage(
                context: context,
                applicationName: 'LifeMeter',
              ),
            ),
          ]),
          const SizedBox(height: LMSpace.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: LinkButton(
              label: 'Start over',
              color: context.lm.ink,
              onPressed: () => _confirmReset(context, controller),
            ),
          ),
          const SizedBox(height: LMSpace.xl),
          const Center(child: LogoMark(size: 32)),
          const SizedBox(height: LMSpace.sm),
          Center(child: Text('What time is it in your life?', style: t.small)),
        ],
      ),
    );
  }

  Future<void> _addWidget(
    BuildContext context,
    LifeController controller,
    HomeWidgetKind kind,
  ) async {
    if (await controller.widgets.canPin()) {
      await controller.widgets.requestPin(kind);
      return;
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add the widget'),
        content: const Text(
          'Long-press an empty spot on your home screen, tap Widgets, '
          'then find LifeMeter and drag it into place.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    LifeController controller,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start over?'),
        content: const Text(
          'This erases your answers, memories and people from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Erase'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    await controller.reset();
  }
}

/// A titled group of plain rows divided by hairlines.
class _Group extends StatelessWidget {
  const _Group(this.title, this.rows);

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, LMSpace.xl, 0, LMSpace.xs),
          child: Text(
            title,
            style: context.type.small.copyWith(
              color: context.lm.brandText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) const Hairline(),
          row,
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.lm;
    final t = context.type;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: t.label),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.caption,
                  ),
                ],
              ),
            ),
            Icon(LMIcons.caretRight, size: 18, color: p.inkMuted),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.on,
    required this.onChanged,
  });

  final String label;
  final String value;
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    return InkWell(
      onTap: () => onChanged(!on),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: t.label),
                  const SizedBox(height: 2),
                  Text(value, style: t.caption),
                ],
              ),
            ),
            Switch(value: on, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _SegmentRow<T> extends StatelessWidget {
  const _SegmentRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: context.type.label)),
          SegmentedChoice<T>(
            value: value,
            options: options,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

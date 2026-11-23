import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/person.dart';
import '../../state/life_controller.dart';
import '../../theme/icons.dart';
import '../../theme/theme.dart';
import '../../widgets/bucket.dart';
import '../../widgets/controls.dart';
import '../../widgets/inputs.dart';
import '../../widgets/share_card.dart';
import '../share/share_sheet.dart';

/// "About N more visits" for [person], from the user's own estimate and
/// the same country table.
int visitsWith(LifeController c, Person person, DateTime now) {
  final estimate = c.estimate;
  if (estimate == null) return 0;
  return visitsLeft(
    personRemainingYears: personRemainingYears(person, estimate.country, now),
    userRemainingYears: estimate.at(now).remainingYears,
    visitsPerYear: person.visitsPerYear,
  );
}

const _labels = ['Mum', 'Dad', 'Grandma', 'Grandpa', 'Best friend'];

/// Add (or edit) someone you want more time with.
Future<void> showPersonEditor(BuildContext context, {Person? person}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<LifeController>(),
      child: PersonEditor(person: person),
    ),
  );
}

class PersonEditor extends StatefulWidget {
  const PersonEditor({super.key, this.person});

  final Person? person;

  @override
  State<PersonEditor> createState() => _PersonEditorState();
}

class _PersonEditorState extends State<PersonEditor> {
  late final TextEditingController _label = TextEditingController(
    text: widget.person?.label ?? '',
  );
  late int _year = widget.person?.birthYear ?? DateTime.now().year - 60;
  late int _visits = widget.person?.visitsPerYear ?? 4;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  void _save() {
    final c = context.read<LifeController>();
    final label = _label.text.trim();
    if (label.isEmpty) return;
    final existing = widget.person;
    if (existing == null) {
      c.addPerson(
        Person.create(label: label, birthYear: _year, visitsPerYear: _visits),
      );
    } else {
      c.updatePerson(
        existing.copyWith(
          label: label,
          birthYear: _year,
          visitsPerYear: _visits,
        ),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final thisYear = DateTime.now().year;
    return ListenableBuilder(
      listenable: _label,
      builder: (context, _) => sheetBody(context, [
        Text(
          widget.person == null ? 'Who do you want more time with?' : 'Edit',
          style: t.title,
        ),
        const SizedBox(height: LMSpace.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final l in _labels)
              SuggestionChip(
                label: l,
                selected: _label.text.trim() == l,
                onTap: () => _label.text = l,
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _label,
          maxLength: 24,
          textCapitalization: TextCapitalization.words,
          style: t.label.copyWith(fontSize: 18),
          decoration: lmInputDecoration(context, hint: 'Or a name'),
        ),
        NumberStepper(
          label: 'Born in',
          value: _year,
          format: (v) => '$v',
          min: thisYear - 110,
          max: thisYear,
          onChanged: (v) => setState(() => _year = v),
        ),
        const Hairline(),
        NumberStepper(
          label: 'Times a year you see them',
          value: _visits,
          format: (v) => '$v',
          min: 1,
          max: 365,
          onChanged: (v) => setState(() => _visits = v),
        ),
        const SizedBox(height: LMSpace.lg),
        PrimaryButton(
          label: 'Save',
          onPressed: _label.text.trim().isEmpty ? null : _save,
        ),
      ]),
    );
  }
}

/// A label with − / + around a poster number.
class NumberStepper extends StatelessWidget {
  const NumberStepper({
    super.key,
    required this.label,
    required this.value,
    required this.format,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final String Function(int) format;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final p = context.lm;
    Widget button(IconData icon, String tip, int to) => RoundIconButton(
      icon: icon,
      tooltip: tip,
      background: p.surfaceSunk,
      size: 44,
      onPressed: () => onChanged(to.clamp(min, max)),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: t.label)),
          button(LMIcons.minus, 'Less', value - 1),
          SizedBox(
            width: 72,
            child: Text(
              format(value),
              textAlign: TextAlign.center,
              style: t.stat.copyWith(fontSize: 32, color: p.ink),
            ),
          ),
          button(LMIcons.plus, 'More', value + 1),
        ],
      ),
    );
  }
}

/// One person: visits left, and something to do about it.
Future<void> showPersonSheet(BuildContext context, Person person) {
  final c = context.read<LifeController>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final t = sheetContext.type;
      final p = sheetContext.lm;
      final now = DateTime.now();
      final visits = visitsWith(c, person, now);
      final more = visitsWith(
        c,
        person.copyWith(visitsPerYear: person.visitsPerYear + 1),
        now,
      );
      return sheetBody(sheetContext, [
        Text(person.label, style: t.small),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('About ', style: t.title),
            Text(
              formatCount(visits),
              style: t.display.copyWith(fontSize: 72, color: p.brandText),
            ),
            Flexible(child: Text(' more visits', style: t.title)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'At ${person.visitsPerYear} ${person.visitsPerYear == 1 ? 'visit' : 'visits'} a year. '
          'One more a year adds about ${formatCount(more - visits)}.',
          style: t.body,
        ),
        const SizedBox(height: LMSpace.lg),
        PrimaryButton(
          label: 'Plan a visit',
          icon: LMIcons.calendarPlus,
          onPressed: () {
            c.addBucketItem('Visit ${person.label}');
            Navigator.pop(sheetContext);
            toast(context, 'Added “Visit ${person.label}” to your list.');
          },
        ),
        const SizedBox(height: 10),
        PrimaryButton(
          label: 'Share',
          icon: LMIcons.export,
          tone: ButtonTone.outline,
          onPressed: () {
            Navigator.pop(sheetContext);
            showShareSheet(
              context,
              ShareData(
                snapshot: c.estimate!.at(now),
                name: c.profile?.name ?? '',
                marked: c.memories.keys.toSet(),
                personLabel: person.label,
                personVisits: visits,
              ),
              initial: ShareTemplate.person,
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LinkButton(
              label: 'Edit',
              onPressed: () {
                Navigator.pop(sheetContext);
                showPersonEditor(context, person: person);
              },
            ),
            LinkButton(
              label: 'Remove',
              color: p.inkMuted,
              onPressed: () {
                Navigator.pop(sheetContext);
                c.removePerson(person.id);
                showRemovedSnackBar(
                  ScaffoldMessenger.maybeOf(context),
                  () => c.addPerson(person),
                  message: 'Removed ${person.label}.',
                );
              },
            ),
          ],
        ),
      ]);
    },
  );
}

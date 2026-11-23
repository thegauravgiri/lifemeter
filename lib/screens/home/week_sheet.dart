import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/milestones.dart';
import '../../models/week_memory.dart';
import '../../state/life_controller.dart';
import '../../theme/icons.dart';
import '../../theme/theme.dart';
import '../../widgets/bucket.dart';
import '../../widgets/controls.dart';
import '../../widgets/inputs.dart';

/// "Nov 17–23, 2026" or "Nov 28 – Dec 4, 2026".
String weekRangeLabel(DateTime start, DateTime end) {
  if (start.year != end.year) {
    return '${DateFormat.yMMMd().format(start)} – ${DateFormat.yMMMd().format(end)}';
  }
  if (start.month == end.month) {
    return '${DateFormat.MMMd().format(start)}–${end.day}, ${end.year}';
  }
  return '${DateFormat.MMMd().format(start)} – ${DateFormat.MMMd().format(end)}, ${end.year}';
}

/// Opens week [index] (0-based): add or edit its memory, or, for a week
/// still ahead, just say so.
Future<void> showWeekSheet(BuildContext context, int index) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<LifeController>(),
      child: WeekSheet(index: index),
    ),
  );
}

/// Pick a past date, then add a moment to that week.
Future<void> addMomentByDate(BuildContext context) async {
  final controller = context.read<LifeController>();
  final estimate = controller.estimate;
  if (estimate == null) return;
  final today = DateUtils.dateOnly(DateTime.now());
  final picked = await showDatePicker(
    context: context,
    firstDate: estimate.birth,
    lastDate: today,
    initialDate: today,
    helpText: 'When did it happen?',
  );
  if (picked == null || !context.mounted) return;
  await showWeekSheet(context, estimate.weekIndexOf(picked));
}

class WeekSheet extends StatefulWidget {
  const WeekSheet({super.key, required this.index});

  final int index;

  @override
  State<WeekSheet> createState() => _WeekSheetState();
}

class _WeekSheetState extends State<WeekSheet> {
  late final LifeController _c = context.read<LifeController>();
  late final WeekMemory? _existing = _c.memories[widget.index];
  late final TextEditingController _text = TextEditingController(
    text: _existing?.text ?? '',
  );
  late String? _stamp = _existing?.stamp;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await _c.saveMemory(
      WeekMemory(week: widget.index, text: _text.text, stamp: _stamp),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final p = context.lm;
    final estimate = _c.estimate!;
    final now = estimate.at(DateTime.now()).weeksLived;
    final start = weekStart(estimate.birth, widget.index);
    final end = weekEnd(estimate.birth, widget.index);
    final number = formatCount(widget.index + 1);
    final ahead = widget.index > now;
    final isNow = widget.index == now;

    final header = [
      Text(
        isNow ? 'This week' : (ahead ? 'A week ahead' : 'A week you lived'),
        style: t.small,
      ),
      const SizedBox(height: 4),
      Text('Week $number · ${weekRangeLabel(start, end)}', style: t.title),
      const SizedBox(height: LMSpace.md),
    ];

    if (ahead) {
      final away = widget.index - now;
      return sheetBody(context, [
        ...header,
        Text(
          'Still a fresh box, ${away == 1 ? 'next week' : '${formatCount(away)} weeks away'}. '
          'Something to look forward to?',
          style: t.body,
        ),
        const SizedBox(height: LMSpace.lg),
        PrimaryButton(
          label: 'Plan something',
          icon: LMIcons.plus,
          tone: ButtonTone.outline,
          onPressed: () {
            Navigator.pop(context);
            showAddBucketItem(context);
          },
        ),
      ]);
    }

    return ListenableBuilder(
      listenable: _text,
      builder: (context, _) => sheetBody(context, [
        ...header,
        TextField(
          controller: _text,
          autofocus: _existing == null,
          maxLength: WeekMemory.maxLength,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          style: t.title,
          decoration: lmInputDecoration(
            context,
            hint: isNow ? 'What made this week?' : 'What happened?',
            hintStyle: t.title.copyWith(color: p.inkMuted),
          ),
        ),
        Text('Add a stamp', style: t.small),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in WeekStamp.all)
              Semantics(
                label: s.label,
                selected: _stamp == s.id,
                button: true,
                child: Pressable(
                  onTap: () =>
                      setState(() => _stamp = _stamp == s.id ? null : s.id),
                  child: Stamp(
                    stamped: _stamp == s.id,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _stamp == s.id ? p.accent : p.surface,
                        borderRadius: BorderRadius.circular(LMRadius.chip),
                        border: Border.all(
                          color: _stamp == s.id ? p.accent : p.line,
                        ),
                      ),
                      child: Icon(
                        s.icon,
                        size: 22,
                        color: _stamp == s.id ? p.onAccent : p.ink,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: LMSpace.lg),
        PrimaryButton(
          label: 'Save',
          onPressed: _text.text.trim().isEmpty ? null : _save,
        ),
        if (_existing != null) ...[
          const SizedBox(height: 8),
          Center(
            child: LinkButton(
              label: 'Remove this memory',
              color: p.inkMuted,
              onPressed: () {
                _c.removeMemory(widget.index);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ]),
    );
  }
}

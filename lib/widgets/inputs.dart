import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/icons.dart';

import '../data/countries.dart';
import '../data/lifestyle.dart';
import '../models/life_estimate.dart';
import '../models/profile.dart';
import '../theme/theme.dart';
import 'controls.dart';

/// Outlined input: white surface, 1px hairline, 4px radius; cobalt 2px
/// when focused.
InputDecoration lmInputDecoration(
  BuildContext context, {
  String? hint,
  TextStyle? hintStyle,
  Widget? prefixIcon,
}) {
  final p = context.lm;
  OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(LMRadius.chip),
    borderSide: BorderSide(color: c, width: w),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: hintStyle ?? context.type.body.copyWith(color: p.inkMuted),
    prefixIcon: prefixIcon,
    filled: true,
    fillColor: p.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    counterStyle: context.type.small,
    border: border(p.line, 1),
    enabledBorder: border(p.line, 1),
    focusedBorder: border(p.brandText, 2),
  );
}

/// Wheel date picker for date of birth, with a sun selection band.
class BirthDatePicker extends StatelessWidget {
  const BirthDatePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.showDate = true,
  });

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  /// The big poster date above the wheel.
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final p = context.lm;
    final t = context.type;
    final today = DateUtils.dateOnly(DateTime.now());
    final age = fullYearsBetween(value, today);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDate) ...[
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              DateFormat('d MMM yyyy').format(value).toUpperCase(),
              style: t.display.copyWith(fontSize: 76, color: p.brandText),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            age == 1 ? 'That makes you 1 year old.' : 'That makes you $age.',
            style: t.body,
          ),
          const SizedBox(height: LMSpace.lg),
        ],
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(LMRadius.chip),
            border: Border.all(color: p.line),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: 8,
                right: 8,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: p.surfaceSunk,
                    borderRadius: BorderRadius.circular(LMRadius.chip),
                  ),
                ),
              ),
              CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: p.brightness,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      fontFamily: LMFont.sans,
                      fontWeight: FontWeight.w500,
                      fontSize: 20,
                      color: p.ink,
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  dateOrder: DatePickerDateOrder.dmy,
                  initialDateTime: value.isAfter(today) ? today : value,
                  minimumDate: DateTime(1900),
                  maximumDate: today,
                  selectionOverlayBuilder:
                      (
                        context, {
                        required selectedIndex,
                        required columnCount,
                      }) => null,
                  onDateTimeChanged: (d) => onChanged(DateUtils.dateOnly(d)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Searchable country list.
class CountryPicker extends StatefulWidget {
  const CountryPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  State<CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<CountryPicker> {
  String _query = '';

  /// The device's region, offered first.
  static String? get _localeCountry => WidgetsBinding
      .instance
      .platformDispatcher
      .locale
      .countryCode
      ?.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final p = context.lm;
    final q = _query.trim().toLowerCase();
    final local = _localeCountry;
    final suggested = q.isEmpty
        ? countries
              .where((c) => c.code == local && c.code != worldCode)
              .toList()
        : const <CountryLifeExpectancy>[];
    final list = [
      ...suggested,
      ...countries.where(
        (c) =>
            !suggested.contains(c) &&
            (q.isEmpty ||
                c.name.toLowerCase().contains(q) ||
                c.code == worldCode),
      ),
    ];
    return Column(
      children: [
        TextField(
          onChanged: (v) => setState(() => _query = v),
          style: context.type.label.copyWith(fontSize: 17),
          decoration: lmInputDecoration(
            context,
            hint: 'Search countries',
            prefixIcon: Icon(
              LMIcons.magnifyingGlass,
              color: p.inkMuted,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: LMSpace.md),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            padding: const EdgeInsets.only(bottom: LMSpace.lg, top: 2),
            itemBuilder: (context, i) {
              final c = list[i];
              final selected = widget.selected == c.code;
              return ChoiceTile(
                label: c.name,
                detail: suggested.contains(c)
                    ? 'Suggested from your phone'
                    : null,
                selected: selected,
                leading: c.code == worldCode
                    ? Container(
                        width: 40,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: p.surfaceSunk,
                          borderRadius: BorderRadius.circular(LMRadius.chip),
                        ),
                        child: Icon(LMIcons.globe, size: 18, color: p.ink),
                      )
                    : CodeBadge(c.code),
                trailing: Text(
                  '${c.average.toStringAsFixed(1)} yrs',
                  style: context.type.small,
                ),
                onTap: () => widget.onSelected(c.code),
              );
            },
          ),
        ),
      ],
    );
  }
}

class SexChoice extends StatelessWidget {
  const SexChoice({super.key, required this.value, required this.onChanged});

  final Sex? value;
  final ValueChanged<Sex> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final s in Sex.values)
          ChoiceTile(
            label: s.label,
            detail: s == Sex.unspecified
                ? 'We’ll use the average of both'
                : null,
            selected: value == s,
            onTap: () => onChanged(s),
          ),
      ],
    );
  }
}

class LifestyleChoice extends StatelessWidget {
  const LifestyleChoice({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final LifestyleQuestion question;
  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final p = context.lm;
    String delta(double y) {
      if (y == 0) return '±0';
      final v = y.abs() == y.abs().roundToDouble()
          ? y.abs().toStringAsFixed(0)
          : y.abs().toStringAsFixed(1);
      return '${y > 0 ? '+' : '−'}$v ${v == '1' ? 'yr' : 'yrs'}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final o in question.options)
          ChoiceTile(
            label: o.label,
            detail: o.detail,
            selected: value == o.id,
            trailing: Text(delta(o.years), style: t.small),
            onTap: () => onChanged(o.id),
          ),
        const SizedBox(height: LMSpace.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(LMIcons.info, size: 16, color: p.inkMuted),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${question.why} ${question.source}.',
                style: t.caption.copyWith(fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Ideas for the one thing, offered as chips.
const intentionSuggestions = [
  'See the northern lights',
  'Learn to surf',
  'Write a book',
  'Run a marathon',
  'Visit Japan',
  'Call Grandma more',
];

/// Free-text "one thing", with suggestion chips.
class IntentionField extends StatelessWidget {
  const IntentionField({
    super.key,
    required this.controller,
    this.autofocus = false,
    this.suggestions = true,
  });

  final TextEditingController controller;
  final bool autofocus;
  final bool suggestions;

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          autofocus: autofocus,
          maxLength: 80,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          style: t.title,
          decoration: lmInputDecoration(
            context,
            hint: 'Type it here',
            hintStyle: t.title.copyWith(color: context.lm.inkMuted),
          ),
        ),
        if (suggestions) ...[
          const SizedBox(height: LMSpace.sm),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final idea in intentionSuggestions)
                  SuggestionChip(
                    label: idea,
                    selected: controller.text.trim() == idea,
                    onTap: () => controller.text = idea,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

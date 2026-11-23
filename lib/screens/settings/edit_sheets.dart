import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/lifestyle.dart';
import '../../state/life_controller.dart';
import '../../theme/theme.dart';
import '../../widgets/controls.dart';
import '../../widgets/inputs.dart';

/// Bottom sheets for editing individual profile fields.

Future<void> _sheet(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext context, StateSetter setState) builder,
  bool tall = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      final media = MediaQuery.of(context);
      return Padding(
        padding: EdgeInsets.fromLTRB(
          LMSpace.gutter,
          0,
          LMSpace.gutter,
          media.viewInsets.bottom + LMSpace.lg,
        ),
        child: SizedBox(
          height: tall ? media.size.height * 0.8 : null,
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: context.type.title),
                const SizedBox(height: LMSpace.lg),
                if (tall)
                  Expanded(child: builder(context, setState))
                else
                  builder(context, setState),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> editIntention(BuildContext context) {
  final controller = context.read<LifeController>();
  final text = TextEditingController(text: controller.profile?.intention ?? '');
  return _sheet(
    context,
    title: 'Your one thing',
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntentionField(controller: text, autofocus: true),
        const SizedBox(height: LMSpace.lg),
        PrimaryButton(
          label: 'Save',
          onPressed: () {
            final value = text.text.trim();
            controller.update((p) => p.copyWith(intention: value));
            controller.addBucketItem(value);
            Navigator.pop(context);
          },
        ),
      ],
    ),
  ).whenComplete(text.dispose);
}

Future<void> editName(BuildContext context) {
  final controller = context.read<LifeController>();
  final text = TextEditingController(text: controller.profile?.name ?? '');
  return _sheet(
    context,
    title: 'Your name',
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: text,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: context.type.title,
          decoration: lmInputDecoration(context, hint: 'Optional'),
        ),
        const SizedBox(height: LMSpace.lg),
        PrimaryButton(
          label: 'Save',
          onPressed: () {
            controller.update((p) => p.copyWith(name: text.text.trim()));
            Navigator.pop(context);
          },
        ),
      ],
    ),
  ).whenComplete(text.dispose);
}

Future<void> editBirthDate(BuildContext context) {
  final controller = context.read<LifeController>();
  var value = controller.profile!.birthDate;
  return _sheet(
    context,
    title: 'Date of birth',
    builder: (context, setState) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BirthDatePicker(
          value: value,
          onChanged: (d) => setState(() => value = d),
        ),
        const SizedBox(height: LMSpace.lg),
        PrimaryButton(
          label: 'Save',
          onPressed: () {
            controller.update((p) => p.copyWith(birthDate: value));
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}

Future<void> editCountry(BuildContext context) {
  final controller = context.read<LifeController>();
  return _sheet(
    context,
    title: 'Country',
    tall: true,
    builder: (context, _) => CountryPicker(
      selected: controller.profile?.countryCode,
      onSelected: (code) {
        controller.update((p) => p.copyWith(countryCode: code));
        Navigator.pop(context);
      },
    ),
  );
}

Future<void> editSex(BuildContext context) {
  final controller = context.read<LifeController>();
  return _sheet(
    context,
    title: 'Sex at birth',
    builder: (context, _) => SexChoice(
      value: controller.profile?.sex,
      onChanged: (s) {
        controller.update((p) => p.copyWith(sex: s));
        Navigator.pop(context);
      },
    ),
  );
}

Future<void> editWidgetUnit(BuildContext context) {
  final controller = context.read<LifeController>();
  return _sheet(
    context,
    title: 'Countdown widget shows',
    builder: (context, _) => Column(
      children: [
        for (final u in WidgetUnit.values)
          ChoiceTile(
            label: u == WidgetUnit.clock ? u.label : '${u.label} left',
            detail: u.detail,
            selected: controller.widgetUnit == u,
            onTap: () {
              controller.setWidgetUnit(u);
              Navigator.pop(context);
            },
          ),
      ],
    ),
  );
}

/// Full-screen editor for all lifestyle answers.
class LifestyleEditScreen extends StatelessWidget {
  const LifestyleEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final controller = context.watch<LifeController>();
    final answers = controller.profile?.lifestyle ?? const <String, String>{};

    void set(String questionId, String optionId) {
      controller.update((p) {
        final next = Map.of(p.lifestyle);
        if (next[questionId] == optionId) {
          next.remove(questionId); // Tap again to clear.
        } else {
          next[questionId] = optionId;
        }
        return p.copyWith(lifestyle: next);
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Sharpen your estimate')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          LMSpace.gutter,
          LMSpace.md,
          LMSpace.gutter,
          LMSpace.xxl,
        ),
        children: [
          Text(
            'Five habits with strong evidence behind them. All optional; tap a selected answer again to clear it.',
            style: t.body,
          ),
          for (final q in lifestyleQuestions) ...[
            const SizedBox(height: LMSpace.xl),
            Text(q.prompt, style: t.title.copyWith(fontSize: 22)),
            const SizedBox(height: LMSpace.md),
            LifestyleChoice(
              question: q,
              value: answers[q.id],
              onChanged: (id) => set(q.id, id),
            ),
          ],
        ],
      ),
    );
  }
}

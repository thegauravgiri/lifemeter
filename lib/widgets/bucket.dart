import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/bucket_item.dart';
import '../state/life_controller.dart';
import '../theme/icons.dart';
import '../theme/theme.dart';
import 'controls.dart';
import 'inputs.dart';

/// One bucket-list row: a round check, the text, and a star for the one
/// thing. Tapping the text opens [showBucketItemActions].
class BucketTile extends StatelessWidget {
  const BucketTile({super.key, required this.item, this.dense = false});

  final BucketItem item;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final p = context.lm;
    final t = context.type;
    final controller = context.watch<LifeController>();
    final pinned = !item.isDone && controller.profile?.intention == item.text;
    return InkWell(
      onTap: () => showBucketItemActions(context, item),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: dense ? 4 : 8),
        child: Row(
          children: [
            BucketCheck(item: item),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.text,
                    style: t.label.copyWith(
                      fontSize: 17,
                      color: item.isDone ? p.inkMuted : p.ink,
                    ),
                  ),
                  if (item.isDone) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Done ${DateFormat.yMMMd().format(item.doneAt!)}',
                      style: t.small,
                    ),
                  ],
                ],
              ),
            ),
            if (!item.isDone)
              RoundIconButton(
                icon: pinned ? LMIcons.starFill : LMIcons.star,
                tooltip: pinned ? 'Your one thing' : 'Make it my one thing',
                foreground: pinned ? p.brandText : p.control,
                onPressed: () {
                  if (!pinned) controller.pinBucketItem(item.id);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// A round check that stamps pink when ticked.
class BucketCheck extends StatelessWidget {
  const BucketCheck({super.key, required this.item});

  final BucketItem item;

  @override
  Widget build(BuildContext context) {
    final p = context.lm;
    final done = item.isDone;
    return Semantics(
      checked: done,
      label: item.text,
      child: Pressable(
        scale: 0.85,
        haptic: false,
        onTap: () => toggleBucketItem(context, item),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Stamp(
            stamped: done,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? p.accent : Colors.transparent,
                border: done ? null : Border.all(color: p.control, width: 2),
              ),
              child: done
                  ? Icon(LMIcons.check, size: 15, color: p.onAccent)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Ticks an item off (haptic + toast) or un-ticks it.
Future<void> toggleBucketItem(BuildContext context, BucketItem item) async {
  final controller = context.read<LifeController>();
  final messenger = ScaffoldMessenger.maybeOf(context);
  await controller.toggleBucketItem(item.id);
  if (item.isDone) return;
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      const SnackBar(content: Text('Done. That’s one for the story.')),
    );
}

Widget sheetBody(BuildContext context, List<Widget> children) => Padding(
  padding: EdgeInsets.fromLTRB(
    LMSpace.gutter,
    0,
    LMSpace.gutter,
    MediaQuery.of(context).viewInsets.bottom + LMSpace.lg,
  ),
  child: SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  ),
);

/// Bottom sheet to add a new bucket-list item, with ideas.
Future<void> showAddBucketItem(BuildContext context) {
  final controller = context.read<LifeController>();
  final text = TextEditingController();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      final t = context.type;
      void submit() {
        controller.addBucketItem(text.text);
        Navigator.pop(context);
      }

      return ListenableBuilder(
        listenable: text,
        builder: (context, _) => sheetBody(context, [
          Text('What do you want to have done?', style: t.title),
          const SizedBox(height: LMSpace.md),
          TextField(
            controller: text,
            autofocus: true,
            maxLength: 80,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => submit(),
            style: t.title,
            decoration: lmInputDecoration(
              context,
              hint: 'Something you want to do',
              hintStyle: t.title.copyWith(color: context.lm.inkMuted),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final idea in intentionSuggestions)
                if (!controller.bucket.any((i) => i.text == idea))
                  SuggestionChip(label: idea, onTap: () => text.text = idea),
            ],
          ),
          const SizedBox(height: LMSpace.lg),
          PrimaryButton(
            label: 'Add to the list',
            onPressed: text.text.trim().isEmpty ? null : submit,
          ),
        ]),
      );
    },
  ).whenComplete(text.dispose);
}

/// Actions for one item: done, pin as the one thing, edit, delete.
Future<void> showBucketItemActions(BuildContext context, BucketItem item) {
  final controller = context.read<LifeController>();
  final messenger = ScaffoldMessenger.maybeOf(context);
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) {
      final t = sheetContext.type;
      final p = sheetContext.lm;
      Widget action(IconData icon, String label, VoidCallback onTap) =>
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: LMSpace.gutter,
            ),
            leading: Icon(icon, color: p.ink),
            title: Text(label, style: t.label),
            onTap: () {
              Navigator.pop(sheetContext);
              onTap();
            },
          );
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              LMSpace.gutter,
              0,
              LMSpace.gutter,
              LMSpace.sm,
            ),
            child: Text(item.text, style: t.title),
          ),
          action(
            item.isDone ? LMIcons.arrowCounterClockwise : LMIcons.checkCircle,
            item.isDone ? 'Mark as not done' : 'Mark as done',
            () => toggleBucketItem(context, item),
          ),
          if (!item.isDone)
            action(
              LMIcons.star,
              'Make it my one thing',
              () => controller.pinBucketItem(item.id),
            ),
          action(
            LMIcons.pencilSimple,
            'Edit',
            () => _editBucketItem(context, item),
          ),
          action(LMIcons.trash, 'Delete', () {
            controller.removeBucketItem(item.id);
            showRemovedSnackBar(
              messenger,
              () => controller.restoreBucketItem(item),
            );
          }),
          const SizedBox(height: LMSpace.md),
        ],
      );
    },
  );
}

/// "Removed" toast with undo.
void showRemovedSnackBar(
  ScaffoldMessengerState? messenger,
  VoidCallback onUndo, {
  String message = 'Removed from your list.',
}) {
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(label: 'Undo', onPressed: onUndo),
      ),
    );
}

Future<void> _editBucketItem(BuildContext context, BucketItem item) {
  final controller = context.read<LifeController>();
  final text = TextEditingController(text: item.text);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      final t = context.type;
      return sheetBody(context, [
        Text('Edit', style: t.title),
        const SizedBox(height: LMSpace.md),
        TextField(
          controller: text,
          autofocus: true,
          maxLength: 80,
          textCapitalization: TextCapitalization.sentences,
          style: t.title,
          decoration: lmInputDecoration(context),
        ),
        const SizedBox(height: LMSpace.md),
        PrimaryButton(
          label: 'Save',
          onPressed: () {
            controller.editBucketItem(item.id, text.text);
            Navigator.pop(context);
          },
        ),
      ]);
    },
  ).whenComplete(text.dispose);
}

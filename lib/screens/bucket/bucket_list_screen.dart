import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/bucket_item.dart';
import '../../state/life_controller.dart';
import '../../theme/icons.dart';
import '../../theme/theme.dart';
import '../../widgets/bucket.dart';
import '../../widgets/controls.dart';
import '../../widgets/inputs.dart';

/// The full bucket list: your one thing pinned on top, the rest as a plain
/// list, and a collapsible "Done" section. Swipe an item away to delete it.
class BucketListScreen extends StatefulWidget {
  const BucketListScreen({super.key});

  @override
  State<BucketListScreen> createState() => _BucketListScreenState();
}

class _BucketListScreenState extends State<BucketListScreen> {
  final _text = TextEditingController();
  bool _showDone = true;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _add(LifeController c) {
    c.addBucketItem(_text.text);
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final p = context.lm;
    final controller = context.watch<LifeController>();
    final items = controller.bucket;
    final pinnedText = controller.profile?.intention ?? '';
    final open = items.where((i) => !i.isDone).toList();
    final pinned = open.where((i) => i.text == pinnedText).firstOrNull;
    final rest = open.where((i) => i != pinned).toList();
    final done = items.where((i) => i.isDone).toList();
    final summers = controller.estimate?.at(DateTime.now()).remainingSummers;

    final String summary;
    if (items.isEmpty) {
      summary = 'Tick things off as you do them.';
    } else if (open.isEmpty) {
      summary = 'All ${items.length} done. What’s next?';
    } else {
      summary =
          '${open.length} to go'
          '${summers != null && summers > 0 ? ' · about ${formatCount(summers)} summers to do ${open.length == 1 ? 'it' : 'them'} in' : ''}';
    }

    return Scaffold(
      appBar: AppBar(
        leading: RoundIconButton(
          icon: LMIcons.arrowLeft,
          tooltip: 'Back',
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  LMSpace.gutter,
                  0,
                  LMSpace.gutter,
                  LMSpace.xl,
                ),
                children: [
                  Text('Bucket list', style: t.headline.copyWith(fontSize: 34)),
                  const SizedBox(height: 4),
                  Text(summary, style: t.bodyLarge),
                  const SizedBox(height: LMSpace.lg),
                  if (pinned != null) ...[
                    Container(
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                      decoration: BoxDecoration(
                        color: p.pinkSoft,
                        borderRadius: BorderRadius.circular(LMRadius.slab),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 0, 0),
                            child: Text(
                              'Your one thing',
                              style: t.small.copyWith(color: p.ink),
                            ),
                          ),
                          BucketTile(item: pinned),
                        ],
                      ),
                    ),
                    const SizedBox(height: LMSpace.sm),
                  ],
                  for (final i in rest) ...[
                    _Dismissible(item: i),
                    const Hairline(),
                  ],
                  if (done.isNotEmpty) ...[
                    const SizedBox(height: LMSpace.lg),
                    InkWell(
                      onTap: () => setState(() => _showDone = !_showDone),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Text(
                              'Done · ${done.length}',
                              style: t.title.copyWith(fontSize: 19),
                            ),
                            const SizedBox(width: 6),
                            AnimatedRotation(
                              turns: _showDone ? 0 : -0.25,
                              duration: const Duration(milliseconds: 160),
                              child: Icon(
                                LMIcons.caretDown,
                                size: 18,
                                color: p.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showDone)
                      for (final i in done) ...[
                        _Dismissible(item: i),
                        const Hairline(),
                      ],
                  ],
                ],
              ),
            ),
            const Hairline(),
            ListenableBuilder(
              listenable: _text,
              builder: (context, _) => Padding(
                padding: const EdgeInsets.fromLTRB(
                  LMSpace.gutter,
                  LMSpace.sm,
                  LMSpace.gutter,
                  LMSpace.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _text,
                            maxLength: 80,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _add(controller),
                            style: t.label.copyWith(fontSize: 17),
                            decoration: lmInputDecoration(
                              context,
                              hint: 'Add a dream',
                            ).copyWith(counterText: ''),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PillButton(
                          label: 'Add',
                          icon: LMIcons.plus,
                          onPressed: _text.text.trim().isEmpty
                              ? null
                              : () => _add(controller),
                          background: _text.text.trim().isEmpty
                              ? p.surfaceSunk
                              : p.brand,
                          foreground: _text.text.trim().isEmpty
                              ? p.inkMuted
                              : p.onBrand,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dismissible extends StatelessWidget {
  const _Dismissible({required this.item});

  final BucketItem item;

  @override
  Widget build(BuildContext context) {
    final p = context.lm;
    final controller = context.read<LifeController>();
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: LMSpace.lg),
        color: p.ink,
        child: Icon(LMIcons.trash, color: p.bg),
      ),
      onDismissed: (_) {
        controller.removeBucketItem(item.id);
        showRemovedSnackBar(
          ScaffoldMessenger.of(context),
          () => controller.restoreBucketItem(item),
        );
      },
      child: BucketTile(item: item),
    );
  }
}

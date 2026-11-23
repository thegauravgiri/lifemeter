import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../services/device_actions.dart';
import '../../theme/icons.dart';
import '../../theme/theme.dart';
import '../../widgets/controls.dart';
import '../../widgets/share_card.dart';

/// Renders the [RepaintBoundary] under [key] to a PNG [width] pixels wide
/// (1080 for a 1080×1920 card).
Future<Uint8List?> renderPng(GlobalKey key, {double width = 1080}) async {
  final boundary = key.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) return null;
  final image = await boundary.toImage(pixelRatio: width / boundary.size.width);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes?.buffer.asUint8List();
}

/// The card preview: swipe between templates, choose name and background,
/// then share or save.
Future<void> showShareSheet(
  BuildContext context,
  ShareData data, {
  ShareTemplate initial = ShareTemplate.clock,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ShareSheet(data: data, initial: initial),
  );
}

class ShareSheet extends StatefulWidget {
  const ShareSheet({
    super.key,
    required this.data,
    this.initial = ShareTemplate.clock,
    this.actions = const DeviceActions(),
  });

  final ShareData data;
  final ShareTemplate initial;
  final DeviceActions actions;

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  late final List<ShareTemplate> _templates = [
    ShareTemplate.clock,
    ShareTemplate.weeks,
    if (widget.data.milestone != null) ShareTemplate.milestone,
    if (widget.data.hasPerson) ShareTemplate.person,
  ];
  late final Map<ShareTemplate, GlobalKey> _keys = {
    for (final t in _templates) t: GlobalKey(),
  };
  late int _page = _templates.contains(widget.initial)
      ? _templates.indexOf(widget.initial)
      : 0;
  late final PageController _pages = PageController(
    initialPage: _page,
    viewportFraction: 0.8,
  );
  bool _showName = false;
  bool _cobalt = true;
  bool _busy = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function(Uint8List png) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final png = await renderPng(_keys[_templates[_page]]!);
      if (png != null) await action(png);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    final p = context.lm;
    final media = MediaQuery.of(context);
    final cardHeight = (media.size.height * 0.5).clamp(300.0, 470.0);
    final hasName = widget.data.name.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: LMSpace.md),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: LMSpace.gutter),
              child: Text('Share your time', style: t.title),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: LMSpace.gutter),
              child: Text(
                'No birth date, country or health answers. Ever.',
                style: t.caption,
              ),
            ),
            const SizedBox(height: LMSpace.md),
            SizedBox(
              height: cardHeight,
              child: PageView.builder(
                controller: _pages,
                itemCount: _templates.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final template = _templates[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Center(
                      child: FittedBox(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: p.line, width: 2),
                          ),
                          child: RepaintBoundary(
                            key: _keys[template],
                            child: ShareCard(
                              template: template,
                              data: widget.data,
                              showName: _showName,
                              cobalt: _cobalt,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _templates.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: WeekSquare(
                      color: i == _page ? p.accent : p.weekFuture,
                      size: 8,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Center(child: Text(_templates[_page].label, style: t.small)),
            const SizedBox(height: LMSpace.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: LMSpace.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Background', style: t.label)),
                      SegmentedChoice<bool>(
                        value: _cobalt,
                        options: const {true: 'Cobalt', false: 'Light'},
                        onChanged: (v) => setState(() => _cobalt = v),
                      ),
                    ],
                  ),
                  if (hasName)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Show my first name', style: t.label),
                      value: _showName,
                      onChanged: (v) => setState(() => _showName = v),
                    ),
                  const SizedBox(height: LMSpace.sm),
                  PrimaryButton(
                    label: 'Share',
                    icon: LMIcons.export,
                    onPressed: _busy
                        ? null
                        : () => _run(widget.actions.sharePng),
                  ),
                  const SizedBox(height: 10),
                  PrimaryButton(
                    label: 'Save image',
                    icon: LMIcons.download,
                    tone: ButtonTone.outline,
                    onPressed: _busy
                        ? null
                        : () => _run((png) async {
                            final messenger = ScaffoldMessenger.maybeOf(
                              context,
                            );
                            final ok = await widget.actions.savePng(png);
                            messenger?.showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'Saved to Pictures/LifeMeter.'
                                      : 'Couldn’t save here. Try Share instead.',
                                ),
                              ),
                            );
                          }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small segmented control in cobalt (theme, card background).
class SegmentedChoice<T> extends StatelessWidget {
  const SegmentedChoice({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.lm;
    final t = context.type;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.surfaceSunk,
        borderRadius: BorderRadius.circular(LMRadius.chip + 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final MapEntry(key: option, value: label) in options.entries)
            Semantics(
              selected: option == value,
              button: true,
              child: GestureDetector(
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  constraints: const BoxConstraints(minHeight: 36),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: option == value ? p.brand : Colors.transparent,
                    borderRadius: BorderRadius.circular(LMRadius.chip),
                  ),
                  child: Text(
                    label,
                    style: t.small.copyWith(
                      color: option == value ? p.onBrand : p.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Preview the life grid as a lock-screen wallpaper, then set or save it.
Future<void> showLockScreenSheet(
  BuildContext context,
  ShareData data, {
  DeviceActions actions = const DeviceActions(),
}) {
  final key = GlobalKey();
  var busy = false;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setState) {
        final t = sheetContext.type;
        final p = sheetContext.lm;
        final height = (MediaQuery.sizeOf(sheetContext).height * 0.5).clamp(
          300.0,
          480.0,
        );
        Future<void> run(
          Future<bool> Function(Uint8List) action,
          String ok,
        ) async {
          if (busy) return;
          setState(() => busy = true);
          final messenger = ScaffoldMessenger.maybeOf(context);
          final png = await renderPng(key, width: 1080);
          final done = png != null && await action(png);
          if (sheetContext.mounted) setState(() => busy = false);
          messenger?.showSnackBar(
            SnackBar(
              content: Text(
                done ? ok : 'That didn’t work here. Try Save image.',
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            LMSpace.gutter,
            0,
            LMSpace.gutter,
            LMSpace.md,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Your life on your lock screen', style: t.title),
                const SizedBox(height: 4),
                Text(
                  'Every glance at your phone, a quiet nudge. Refresh it any week.',
                  style: t.caption,
                ),
                const SizedBox(height: LMSpace.md),
                SizedBox(
                  height: height,
                  child: Center(
                    child: FittedBox(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: p.line, width: 2),
                        ),
                        child: RepaintBoundary(
                          key: key,
                          child: ShareCard(
                            template: ShareTemplate.lockScreen,
                            data: data,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: LMSpace.md),
                PrimaryButton(
                  label: 'Set as lock screen',
                  icon: LMIcons.lockSimple,
                  onPressed: busy
                      ? null
                      : () => run(actions.setLockScreen, 'Lock screen set.'),
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: 'Save image',
                  icon: LMIcons.download,
                  tone: ButtonTone.outline,
                  onPressed: busy
                      ? null
                      : () => run(
                          (png) => actions.savePng(png, name: 'lifemeter-lock'),
                          'Saved to Pictures/LifeMeter.',
                        ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../theme/icons.dart';
import '../theme/theme.dart';

final _numberFormat = NumberFormat.decimalPattern();

String formatCount(num value) => _numberFormat.format(value);

bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Press feedback: scales down a touch while held.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.97,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTap: enabled
          ? () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _down && !reduceMotion(context) ? widget.scale : 1,
        duration: Duration(milliseconds: _down ? 80 : 160),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

enum ButtonTone {
  /// Cobalt fill, white label.
  primary,

  /// White fill, cobalt label: for use on the cobalt slab.
  inverse,

  /// 1.5px ink outline, ink label.
  outline,
}

/// Full-width pill button. Flat: no shadow, no lift.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = ButtonTone.primary,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonTone tone;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final p = context.lm;
    final enabled = onPressed != null;
    final (bg, fg, border) = switch (tone) {
      ButtonTone.primary => (p.brand, p.onBrand, null),
      ButtonTone.inverse => (p.onBrand, p.brand, null),
      ButtonTone.outline => (Colors.transparent, p.ink, p.ink),
    };
    final fill = enabled ? bg : p.surfaceSunk;
    final text = enabled ? fg : p.inkMuted;
    return Semantics(
      button: true,
      enabled: enabled,
      child: Pressable(
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                onPressed!();
              }
            : null,
        haptic: false,
        child: Container(
          width: expand ? double.infinity : null,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: ShapeDecoration(
            color: fill,
            shape: StadiumBorder(
              side: border == null || !enabled
                  ? BorderSide.none
                  : BorderSide(color: border, width: 1.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: text),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.button.copyWith(
                    color: text,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small button with a 4px radius (e.g. "Add", "Done").
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.background,
    this.foreground,
    this.outline,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? background;
  final Color? foreground;
  final Color? outline;

  @override
  Widget build(BuildContext context) {
    final p = context.lm;
    final fg = foreground ?? p.onBrand;
    return Semantics(
      button: true,
      child: Pressable(
        onTap: onPressed,
        scale: 0.95,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: EdgeInsets.fromLTRB(icon == null ? 16 : 12, 0, 16, 0),
          decoration: BoxDecoration(
            color: background ?? p.brand,
            borderRadius: BorderRadius.circular(LMRadius.chip),
            border: outline == null
                ? null
                : Border.all(color: outline!, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.button.copyWith(color: fg, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A text-only action in cobalt ("See all 5", "Skip").
class LinkButton extends StatelessWidget {
  const LinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.lm.brandText;
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: context.type.button.copyWith(color: c, fontSize: 15),
    );
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: icon == null
          ? text
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: text),
                const SizedBox(width: 6),
                Icon(icon, size: 17, color: c),
              ],
            ),
    );
  }
}

/// A round icon button.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.background,
    this.foreground,
    this.size = 48,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? background;
  final Color? foreground;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.lm;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Pressable(
          onTap: onPressed,
          scale: 0.9,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: background ?? Colors.transparent,
            ),
            child: Icon(icon, size: 22, color: foreground ?? p.ink),
          ),
        ),
      ),
    );
  }
}

/// A single-choice answer row: white surface, 1px line, 4px radius.
/// Selected rows get a 2px cobalt border and a check.
class ChoiceTile extends StatelessWidget {
  const ChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.detail,
    this.leading,
    this.trailing,
  });

  final String label;
  final String? detail;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.lm;
    final t = context.type;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        selected: selected,
        button: true,
        child: Pressable(
          onTap: onTap,
          scale: 0.985,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 58),
            padding: EdgeInsets.symmetric(
              horizontal: selected ? 15 : 16,
              vertical: selected ? 9 : 10,
            ),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(LMRadius.chip),
              border: Border.all(
                color: selected ? p.brandText : p.line,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 14)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: t.label.copyWith(fontSize: 17)),
                      if (detail != null) ...[
                        const SizedBox(height: 2),
                        Text(detail!, style: t.caption),
                      ],
                    ],
                  ),
                ),
                if (trailing != null)
                  DefaultTextStyle.merge(
                    style: TextStyle(color: p.inkMuted),
                    child: trailing!,
                  ),
                if (selected)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Icon(LMIcons.check, size: 22, color: p.brandText),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small sentence-case kicker above a title.
class Kicker extends StatelessWidget {
  const Kicker(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: context.type.small.copyWith(color: color));
}

/// A section title with an optional line under it and an optional action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: Text(title, style: t.title)),
            ?action,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: t.caption.copyWith(fontSize: 15)),
        ],
      ],
    );
  }
}

/// A hairline that runs the width of its parent.
class Hairline extends StatelessWidget {
  const Hairline({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, indent: indent, color: context.lm.line);
}

/// A week square, the app's visual motif (2px radius).
class WeekSquare extends StatelessWidget {
  const WeekSquare({super.key, required this.color, this.size = 10, this.ring});

  final Color color;
  final double size;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(LMRadius.cell),
        border: ring == null ? null : Border.all(color: ring!, width: 2),
      ),
    );
  }
}

/// A two-letter country code badge (emoji flags don't render everywhere).
class CodeBadge extends StatelessWidget {
  const CodeBadge(this.code, {super.key});

  final String code;

  @override
  Widget build(BuildContext context) {
    final p = context.lm;
    return Container(
      width: 40,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.surfaceSunk,
        borderRadius: BorderRadius.circular(LMRadius.chip),
      ),
      child: Text(
        code,
        style: context.type.small.copyWith(
          color: p.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A tappable suggestion chip (4px radius, hairline outline).
class SuggestionChip extends StatelessWidget {
  const SuggestionChip({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = context.lm;
    return Semantics(
      button: true,
      selected: selected,
      child: Pressable(
        onTap: onTap,
        scale: 0.95,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? p.brand : p.surface,
            borderRadius: BorderRadius.circular(LMRadius.chip),
            border: Border.all(color: selected ? p.brand : p.line),
          ),
          child: Text(
            label,
            style: context.type.label.copyWith(
              fontSize: 15,
              color: selected ? p.onBrand : p.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// A single pink "stamp": scales 1.2 → 1 over 180ms whenever [stamped]
/// turns true. Honours reduce-motion.
class Stamp extends StatelessWidget {
  const Stamp({super.key, required this.stamped, required this.child});

  final bool stamped;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!stamped || reduceMotion(context)) return child;
    return TweenAnimationBuilder<double>(
      key: const ValueKey('stamped'),
      tween: Tween(begin: 1.2, end: 1),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      builder: (context, s, child) => Transform.scale(scale: s, child: child),
      child: child,
    );
  }
}

/// Shows a brief ink toast.
void toast(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: actionLabel == null
            ? null
            : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
      ),
    );
}

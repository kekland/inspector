import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inspector/src/widgets/color_picker/utils.dart';

/// Declarative spec for a single info chip; rendered by [PropSection].
typedef PropSpec = ({IconData icon, String subtitle, Widget child});

// ─── Primitives ──────────────────────────────────────────────────────────────

/// Small color square used inline in info chips.
class ColorDot extends StatelessWidget {
  const ColorDot(this.color, {super.key});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
      );
}

/// Color dot + hex label. Tapping copies the hex value to the clipboard.
///
/// Named with a `Chip` suffix to avoid colliding with Flutter's
/// [ColorSwatch] generic palette type from `material.dart`.
class ColorHexChip extends StatelessWidget {
  const ColorHexChip(this.color, {super.key});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hex = '#${colorToHexString(color, withAlpha: true)}';
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: hex));
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              spacing: 8,
              children: [ColorDot(color), Text('Copied $hex')],
            ),
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4.0,
        children: [ColorDot(color), Text(hex)],
      ),
    );
  }
}

/// Text that truncates with ellipsis when it would outgrow its chip.
///
/// Used for values of potentially unbounded length (URLs, `toString()` dumps
/// of ImageFilter/ColorFilter, Offset/Alignment representations).
class EllipsizedText extends StatelessWidget {
  const EllipsizedText(this.value, {super.key});
  final String value;

  @override
  Widget build(BuildContext context) => Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
      );
}

// ─── Chip + section ──────────────────────────────────────────────────────────

/// Single labelled info chip: leading icon, value, subtitle.
///
/// [expandChild] controls sizing:
/// - `false` (default) — chip shrink-wraps to its content and lives inside a
///   [PropSection] (a [Wrap] of chips capped at 260 px each).
/// - `true` — chip takes the full available width, used for wide preview rows
///   like paragraph text previews.
class PropChip extends StatelessWidget {
  const PropChip({
    super.key,
    required this.icon,
    required this.subtitle,
    required this.child,
    this.iconColor,
    this.backgroundColor,
    this.expandChild = false,
  });

  final IconData icon;
  final String subtitle;
  final Widget child;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.0),
        ),
      ],
    );
    Widget content = Row(
      mainAxisSize: expandChild ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20.0,
          color: iconColor ?? theme.textTheme.bodySmall?.color,
        ),
        const SizedBox(width: 12.0),
        if (expandChild)
          Expanded(child: column)
        else
          // Cap column width so long child text honours maxLines/ellipsis
          // instead of forcing the whole chip past the parent ConstrainedBox.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 208),
            child: column,
          ),
      ],
    );
    if (backgroundColor != null) {
      content = Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: content,
      );
    }
    return content;
  }
}

/// A [Wrap] of [PropChip]s. Each chip is capped at 260 px so the row never
/// overflows the panel on narrow screens.
class PropSection extends StatelessWidget {
  const PropSection({super.key, required this.props});
  final List<PropSpec> props;

  @override
  Widget build(BuildContext context) {
    if (props.isEmpty) return const SizedBox.shrink();
    final bg = Theme.of(context).chipTheme.backgroundColor;
    return Wrap(
      spacing: 12.0,
      runSpacing: 8.0,
      children: [
        for (final p in props)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: PropChip(
              icon: p.icon,
              subtitle: p.subtitle,
              backgroundColor: bg,
              child: p.child,
            ),
          ),
      ],
    );
  }
}

// ─── Composite chip contents ─────────────────────────────────────────────────

/// Visual list of [BoxShadow]s: color swatch + blur/spread/offset line.
class ShadowsView extends StatelessWidget {
  const ShadowsView(this.shadows, {super.key});
  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    String f(double v) => v.toStringAsFixed(1);
    String line(BoxShadow s) => [
          'blur:${f(s.blurRadius)}',
          if (s.spreadRadius != 0) 'spread:${f(s.spreadRadius)}',
          '(${f(s.offset.dx)},${f(s.offset.dy)})',
        ].join(' ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final s in shadows)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [ColorHexChip(s.color), Text(line(s))],
          ),
      ],
    );
  }
}

/// Visual preview strip of a [Gradient].
class GradientPreview extends StatelessWidget {
  const GradientPreview(this.gradient, {super.key});
  final Gradient gradient;

  @override
  Widget build(BuildContext context) => Container(
        width: 64,
        height: 14,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
      );
}

/// Full gradient breakdown: preview, type label, color stops, and
/// shape-specific details (begin/end, center/radius, angles).
class GradientView extends StatelessWidget {
  const GradientView(this.gradient, {super.key});
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final g = gradient;
    final type = switch (g) {
      LinearGradient() => 'linear',
      RadialGradient() => 'radial',
      SweepGradient() => 'sweep',
      _ => g.runtimeType.toString(),
    };

    final stops = g.stops;
    final detail = switch (g) {
      LinearGradient(:final begin, :final end, :final tileMode) => [
          'begin:$begin',
          'end:$end',
          if (tileMode != TileMode.clamp) 'tile:${tileMode.name}',
        ],
      RadialGradient(:final center, :final radius, :final tileMode) => [
          'center:$center',
          'r:${radius.toStringAsFixed(2)}',
          if (tileMode != TileMode.clamp) 'tile:${tileMode.name}',
        ],
      SweepGradient(
        :final center,
        :final startAngle,
        :final endAngle,
        :final tileMode,
      ) =>
        [
          'center:$center',
          'start:${startAngle.toStringAsFixed(2)}',
          'end:${endAngle.toStringAsFixed(2)}',
          if (tileMode != TileMode.clamp) 'tile:${tileMode.name}',
        ],
      _ => <String>[],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [GradientPreview(g), Text(type)],
        ),
        for (var i = 0; i < g.colors.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              ColorHexChip(g.colors[i]),
              if (stops != null && i < stops.length)
                Text('@${stops[i].toStringAsFixed(2)}'),
            ],
          ),
        for (final d in detail) Text(d, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:inspector/src/widgets/color_picker/utils.dart';
import 'package:inspector/src/widgets/inspector/box_info.dart';
import 'package:inspector/src/widgets/inspector/compare_distances.dart';
import 'package:inspector/src/widgets/inspector/render_box_extension.dart';

/// Declarative spec for a single info chip.
typedef _PropSpec = ({IconData icon, String subtitle, Widget child});

List<TextStyle> _extractTextStyles(InlineSpan span, [List<TextStyle>? styles]) {
  styles ??= [];
  if (span.style != null) styles.add(span.style!);
  if (span is TextSpan && span.children != null) {
    for (final child in span.children!) {
      _extractTextStyles(child, styles);
    }
  }
  return styles;
}

// ─── Private widget classes ───────────────────────────────────────────────────

class _ColorDot extends StatelessWidget {
  const _ColorDot(this.color);

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

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch(this.color);

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
              children: [_ColorDot(color), Text('Copied $hex')],
            ),
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4.0,
        children: [_ColorDot(color), Text(hex)],
      ),
    );
  }
}

// ─── Main widget ──────────────────────────────────────────────────────────────

class BoxInfoPanelWidget extends StatelessWidget {
  const BoxInfoPanelWidget({
    Key? key,
    required this.boxInfo,
    this.comparedBoxInfo,
    this.onCompare,
    this.isCompareActive = false,
  }) : super(key: key);

  final BoxInfo boxInfo;
  final BoxInfo? comparedBoxInfo;
  final VoidCallback? onCompare;
  final bool isCompareActive;

  // ─── Core builders ────────────────────────────────────────────

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required Widget child,
    required String subtitle,
    Color? iconColor,
    Color? backgroundColor,
  }) {
    final theme = Theme.of(context);
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 20.0, color: iconColor ?? theme.textTheme.bodySmall?.color),
        const SizedBox(width: 12.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            child,
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.0),
            ),
          ],
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

  Widget _buildSection(BuildContext context, List<_PropSpec> props) {
    if (props.isEmpty) return const SizedBox.shrink();
    final bg = Theme.of(context).chipTheme.backgroundColor;
    return Wrap(
      spacing: 12.0,
      runSpacing: 8.0,
      children: [
        for (final p in props)
          _buildInfoRow(
            context,
            icon: p.icon,
            subtitle: p.subtitle,
            backgroundColor: bg,
            child: p.child,
          ),
      ],
    );
  }

  // ─── Property extractors ──────────────────────────────────────

  List<_PropSpec> _constraintsProps() {
    final c = boxInfo.targetRenderBox.constraints;
    String fmt(double min, double max) {
      if (min == max) return '=${min.toStringAsFixed(1)}';
      final hi = max == double.infinity ? '∞' : max.toStringAsFixed(1);
      return '${min.toStringAsFixed(1)}–$hi';
    }

    return [
      (
        icon: Icons.swap_horiz,
        subtitle: 'W constraint',
        child: Text(fmt(c.minWidth, c.maxWidth))
      ),
      (
        icon: Icons.swap_vert,
        subtitle: 'H constraint',
        child: Text(fmt(c.minHeight, c.maxHeight))
      ),
    ];
  }

  List<_PropSpec> _paragraphProps(RenderParagraph target) => [
        (
          icon: Icons.format_align_left,
          subtitle: 'text align',
          child: Text(target.textAlign.name)
        ),
        if (target.maxLines != null)
          (
            icon: Icons.format_list_numbered,
            subtitle: 'max lines',
            child: Text('${target.maxLines}')
          ),
        if (target.overflow != TextOverflow.clip)
          (
            icon: Icons.more_horiz,
            subtitle: 'overflow',
            child: Text(target.overflow.name)
          ),
        if (!target.softWrap)
          (
            icon: Icons.wrap_text,
            subtitle: 'soft wrap',
            child: const Text('off')
          ),
        if (target.textScaler != TextScaler.noScaling)
          (
            icon: Icons.text_fields,
            subtitle: 'text scale',
            child: Text(target.textScaler.toString())
          ),
      ];

  List<_PropSpec> _spanProps(TextStyle style) => [
        if (style.fontFamily != null)
          (
            icon: Icons.font_download,
            subtitle: 'font family',
            child: Text(style.fontFamily!)
          ),
        if (style.fontSize != null)
          (
            icon: Icons.format_size,
            subtitle: 'font size',
            child: Text(style.fontSize!.toStringAsFixed(1))
          ),
        if (style.fontWeight != null)
          (
            icon: Icons.line_weight,
            subtitle: 'weight',
            child: Text(style.fontWeight.toString())
          ),
        if (style.fontStyle != null)
          (
            icon: Icons.format_italic,
            subtitle: 'style',
            child: Text(style.fontStyle.toString())
          ),
        if (style.color != null)
          (
            icon: Icons.color_lens,
            subtitle: 'color',
            child: _ColorSwatch(style.color!)
          ),
        if (style.height != null)
          (
            icon: Icons.height,
            subtitle: 'height',
            child: Text(style.height!.toStringAsFixed(1))
          ),
        if (style.letterSpacing != null)
          (
            icon: Icons.horizontal_distribute,
            subtitle: 'letter spacing',
            child: Text(style.letterSpacing!.toStringAsFixed(1))
          ),
        if (style.wordSpacing != null)
          (
            icon: Icons.space_bar,
            subtitle: 'word spacing',
            child: Text(style.wordSpacing!.toStringAsFixed(1))
          ),
        if (style.decoration != null && style.decoration != TextDecoration.none)
          (
            icon: Icons.text_format,
            subtitle: 'decoration',
            child: Text(style.decoration.toString())
          ),
        if (style.backgroundColor != null)
          (
            icon: Icons.format_color_fill,
            subtitle: 'bg color',
            child: _ColorSwatch(style.backgroundColor!)
          ),
      ];

  List<_PropSpec> _decorationProps(BoxDecoration d) => [
        if (d.color != null)
          (
            icon: Icons.palette,
            subtitle: 'color',
            child: _ColorSwatch(d.color!)
          ),
        if (d.borderRadius != null)
          (
            icon: Icons.rounded_corner,
            subtitle: 'border radius (LTRB)',
            child: Text(_formatBorderRadius(d.borderRadius!))
          ),
        if (d.shape != BoxShape.rectangle)
          (
            icon: Icons.circle_outlined,
            subtitle: 'shape',
            child: Text(d.shape.name)
          ),
        if (d.border != null) ..._borderProps(d.border!),
        if (d.boxShadow != null && d.boxShadow!.isNotEmpty)
          (
            icon: Icons.blur_on,
            subtitle: 'shadows',
            child: _shadowsWidget(d.boxShadow!)
          ),
        if (d.gradient != null)
          (
            icon: Icons.gradient,
            subtitle: 'gradient',
            child: _gradientWidget(d.gradient!)
          ),
      ];

  List<_PropSpec> _stackProps(RenderStack target) => [
        (
          icon: Icons.align_vertical_bottom,
          subtitle: 'alignment',
          child: Text(target.alignment.toString()),
        ),
        if (target.fit != StackFit.loose)
          (
            icon: Icons.fit_screen,
            subtitle: 'fit',
            child: Text(target.fit.name),
          ),
      ];

  List<_PropSpec> _flexProps(RenderFlex target) => [
        (
          icon: Icons.swap_horiz,
          subtitle: 'direction',
          child: Text(target.direction.name)
        ),
        (
          icon: Icons.space_bar,
          subtitle: 'main axis',
          child: Text(target.mainAxisAlignment.name)
        ),
        (
          icon: Icons.vertical_align_center,
          subtitle: 'cross axis',
          child: Text(target.crossAxisAlignment.name)
        ),
        if (target.mainAxisSize != MainAxisSize.max)
          (
            icon: Icons.compress,
            subtitle: 'main size',
            child: Text(target.mainAxisSize.name)
          ),
        if (target.verticalDirection != VerticalDirection.down)
          (
            icon: Icons.swap_vert,
            subtitle: 'vertical dir',
            child: Text(target.verticalDirection.name)
          ),
      ];

  List<_PropSpec> _imageProps(RenderImage target) => [
        if (target.fit != null)
          (
            icon: Icons.fit_screen,
            subtitle: 'fit',
            child: Text(target.fit!.name)
          ),
        (
          icon: Icons.crop_free,
          subtitle: 'alignment',
          child: Text(target.alignment.toString())
        ),
        if (target.width != null)
          (
            icon: Icons.swap_horiz,
            subtitle: 'width',
            child: Text(target.width!.toStringAsFixed(1))
          ),
        if (target.height != null)
          (
            icon: Icons.swap_vert,
            subtitle: 'height',
            child: Text(target.height!.toStringAsFixed(1))
          ),
        if (target.repeat != ImageRepeat.noRepeat)
          (
            icon: Icons.repeat,
            subtitle: 'repeat',
            child: Text(target.repeat.name)
          ),
        if (target.color != null)
          (
            icon: Icons.color_lens,
            subtitle: 'color tint',
            child: _ColorSwatch(target.color!)
          ),
      ];

  List<_PropSpec> _opacityProps(RenderOpacity target) => [
        (
          icon: Icons.opacity,
          subtitle: 'opacity',
          child: Text(target.opacity.toStringAsFixed(2))
        ),
      ];

  List<_PropSpec> _physicalShapeProps(RenderPhysicalShape target) => [
        (
          icon: Icons.palette,
          subtitle: 'color',
          child: _ColorSwatch(target.color),
        ),
        if (target.elevation > 0)
          (
            icon: Icons.layers,
            subtitle: 'elevation',
            child: Text(target.elevation.toStringAsFixed(1)),
          ),
        (
          icon: Icons.blur_on,
          subtitle: 'shadow color',
          child: _ColorSwatch(target.shadowColor),
        ),
      ];

  // ─── Format helpers ───────────────────────────────────────────

  String _formatBorderRadius(BorderRadiusGeometry geometry) {
    final r = geometry.resolve(TextDirection.ltr);
    String f(double v) => v.toStringAsFixed(1);
    return '${f(r.topLeft.x)}, ${f(r.topRight.x)}, ${f(r.bottomRight.x)}, ${f(r.bottomLeft.x)}';
  }

  List<_PropSpec> _borderProps(BoxBorder border) {
    if (border is! Border) {
      return [
        (
          icon: Icons.border_all,
          subtitle: 'border',
          child: Text(border.runtimeType.toString()),
        ),
      ];
    }

    final sides = [border.top, border.right, border.bottom, border.left];
    final widths = sides.map((s) => s.width).toSet();
    final activeSides = sides.where((s) => s.width > 0).toList();
    final colors = activeSides.map((s) => s.color).toSet();

    Widget sideChild(Color color, String wStr) => Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [_ColorSwatch(color), Text(wStr)],
        );

    // Uniform border — single chip
    if (colors.length == 1 && activeSides.isNotEmpty) {
      final wStr = widths.length == 1
          ? 'w:${widths.first.toStringAsFixed(1)}'
          : 'w:${sides.map((s) => s.width.toStringAsFixed(1)).join('/')}';
      return [
        (
          icon: Icons.border_all,
          subtitle: 'border',
          child: sideChild(colors.first, wStr),
        ),
      ];
    }

    // Non-uniform border — one chip per active side
    const sideLabels = ['T', 'R', 'B', 'L'];
    return [
      for (var i = 0; i < sides.length; i++)
        if (sides[i].width > 0)
          (
            icon: Icons.border_all,
            subtitle: 'border ${sideLabels[i]}',
            child: sideChild(
              sides[i].color,
              'w:${sides[i].width.toStringAsFixed(1)}',
            ),
          ),
    ];
  }

  Widget _shadowsWidget(List<BoxShadow> shadows) {
    final maxBlur =
        shadows.map((s) => s.blurRadius).reduce((a, b) => a > b ? a : b);
    final label = shadows.length == 1
        ? () {
            final s = shadows.first;
            return 'blur:${s.blurRadius.toStringAsFixed(1)} (${s.offset.dx.toStringAsFixed(1)},${s.offset.dy.toStringAsFixed(1)})';
          }()
        : '${shadows.length}× blur:${maxBlur.toStringAsFixed(1)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final s in shadows) _ColorSwatch(s.color),
        Text(label),
      ],
    );
  }

  Widget _gradientWidget(Gradient g) {
    final (type, colors) = switch (g) {
      LinearGradient() => ('linear', g.colors),
      RadialGradient() => ('radial', g.colors),
      SweepGradient() => ('sweep', g.colors),
      _ => (g.runtimeType.toString(), <Color>[]),
    };
    if (colors.isEmpty) return Text(type);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in colors) _ColorSwatch(c),
        Text(type),
      ],
    );
  }

  // ─── Section builders ─────────────────────────────────────────

  Widget _buildMainRow(BuildContext context) {
    final theme = Theme.of(context);
    final displaySize = boxInfo.targetRenderBox.displaySize;
    return Wrap(
      spacing: 12.0,
      runSpacing: 8.0,
      children: [
        _buildInfoRow(
          context,
          icon: Icons.format_shapes,
          subtitle: 'size',
          backgroundColor: theme.chipTheme.backgroundColor,
          child: Text(
            '${displaySize.width.toStringAsFixed(1)} × ${displaySize.height.toStringAsFixed(1)}',
          ),
        ),
        if (boxInfo.containerRect != null && !boxInfo.isContainerFlex)
          _buildInfoRow(
            context,
            icon: Icons.straighten,
            subtitle: 'padding (LTRB)',
            backgroundColor: theme.chipTheme.backgroundColor,
            child: Text(boxInfo.describeOriginalPadding()),
          ),
      ],
    );
  }

  Widget _buildComparedRow(BuildContext context) {
    final originalWidth = boxInfo.targetRenderBox.size.width;
    final scale =
        originalWidth > 0 ? boxInfo.targetRect.width / originalWidth : 1.0;
    final distances = computeCompareDistances(
      boxInfo.targetRect,
      comparedBoxInfo!.targetRect,
      scale: scale,
    );
    return _buildSection(context, [
      for (final d in distances)
        (
          icon: d.icon,
          subtitle: d.side.name,
          child: Text(d.value.toStringAsFixed(1))
        ),
    ]);
  }

  Widget _buildParagraphSection(BuildContext context, RenderParagraph target) {
    final dividerColor = Theme.of(context).colorScheme.outlineVariant;
    final spanSections = _extractTextStyles(target.text)
        .map(_spanProps)
        .where((p) => p.isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        _buildSection(context, _paragraphProps(target)),
        if (spanSections.isNotEmpty) ...[
          Divider(height: 12, color: dividerColor),
          for (final props in spanSections) _buildSection(context, props),
        ],
      ],
    );
  }

  /// Type-specific props for the target render box, excluding decoration.
  /// Returns an empty list when the type has no known props.
  List<_PropSpec> _typeProps(RenderBox target) => [
        if (target is RenderStack) ..._stackProps(target),
        if (target is RenderFlex) ..._flexProps(target),
        if (target is RenderImage) ..._imageProps(target),
        if (target is RenderOpacity) ..._opacityProps(target),
        if (target is RenderPhysicalShape) ..._physicalShapeProps(target),
      ];

  /// Decoration props resolved from the hit-test path.
  /// Prefers [ColoredBox] color over [BoxDecoration] to avoid duplication.
  List<_PropSpec> _resolvedDecorationProps() {
    final coloredBoxColor = boxInfo.coloredBoxColor;
    if (coloredBoxColor != null) {
      return [
        (
          icon: Icons.palette,
          subtitle: 'color',
          child: _ColorSwatch(coloredBoxColor),
        ),
      ];
    }
    if (boxInfo.decoratedBoxForDisplay?.decoration case final BoxDecoration d) {
      return _decorationProps(d);
    }
    return [];
  }

  Widget? _buildTypeSection(BuildContext context, RenderBox target) {
    if (target is RenderParagraph) {
      return _buildParagraphSection(context, target);
    }
    final props = [..._typeProps(target), ..._resolvedDecorationProps()];
    return props.isEmpty ? null : _buildSection(context, props);
  }

  // ─── build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = boxInfo.targetRenderBox;
    final dividerColor = theme.colorScheme.outlineVariant;
    final typeSection = _buildTypeSection(context, target);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    describeIdentity(target),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                if (onCompare != null)
                  IconButton(
                    iconSize: 18.0,
                    color: isCompareActive
                        ? theme.colorScheme.primary
                        : theme.iconTheme.color,
                    onPressed: onCompare,
                    icon: const Icon(Icons.compare),
                  ),
                IconButton(
                  iconSize: 18.0,
                  onPressed: () => Clipboard.setData(
                    ClipboardData(text: target.toStringDeep()),
                  ),
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
            childrenPadding: const EdgeInsets.only(
              left: 12.0,
              right: 12.0,
              bottom: 12.0,
            ),
            expandedAlignment: Alignment.centerLeft,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMainRow(context),
              Divider(height: 16.0, color: dividerColor),
              _buildSection(context, _constraintsProps()),
              if (target.attached &&
                  comparedBoxInfo?.targetRenderBox.attached == true) ...[
                Divider(height: 16.0, color: dividerColor),
                _buildComparedRow(context),
              ],
              if (typeSection != null) ...[
                Divider(height: 16.0, color: dividerColor),
                typeSection,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:inspector/src/widgets/color_picker/utils.dart';
import 'package:inspector/src/widgets/inspector/box_info.dart';

class BoxInfoPanelWidget extends StatelessWidget {
  const BoxInfoPanelWidget({
    Key? key,
    required this.boxInfo,
    this.comparedBoxInfo,
  }) : super(key: key);

  final BoxInfo boxInfo;
  final BoxInfo? comparedBoxInfo;

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required Widget child,
    required String subtitle,
    Color? iconColor,
    Color? backgroundColor,
  }) {
    final theme = Theme.of(context);

    Widget _child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20.0,
          color: iconColor ?? theme.textTheme.bodySmall?.color,
        ),
        const SizedBox(width: 12.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            child,
            const SizedBox(height: 0.0),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.0),
            ),
          ],
        ),
      ],
    );

    if (backgroundColor != null) {
      _child = Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: _child,
      );
    }

    return _child;
  }

  Widget _buildMainRow(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 12.0,
      runSpacing: 8.0,
      children: [
        _buildInfoRow(
          context,
          icon: Icons.format_shapes,
          subtitle: 'size',
          child: Text(
            '${boxInfo.targetRect.width.toStringAsFixed(1)} × ${boxInfo.targetRect.height.toStringAsFixed(1)}',
          ),
          backgroundColor: theme.chipTheme.backgroundColor,
        ),
        if (boxInfo.containerRect != null)
          _buildInfoRow(
            context,
            icon: Icons.straighten,
            subtitle: 'padding (LTRB)',
            child: Text(boxInfo.describePadding()),
            backgroundColor: theme.chipTheme.backgroundColor,
          ),
      ],
    );
  }

  Widget _buildComparedRow(BuildContext context) {
    final theme = Theme.of(context);
    final from = boxInfo.targetRect;
    final to = comparedBoxInfo!.targetRect;

    double left = 0, right = 0, top = 0, bottom = 0;

    // Horizontal distances
    if (from.right <= to.left) {
      // from is left of to
      right = to.left - from.right;
    } else if (to.right <= from.left) {
      // from is right of to
      left = from.left - to.right;
    } else {
      // They overlap horizontally
      left = (from.left - to.left).abs();
      right = (from.right - to.right).abs();
    }

    // Vertical distances
    if (from.bottom <= to.top) {
      // from is above to
      bottom = to.top - from.bottom;
    } else if (to.bottom <= from.top) {
      // from is below to
      top = from.top - to.bottom;
    } else {
      // They overlap vertically
      top = (from.top - to.top).abs();
      bottom = (from.bottom - to.bottom).abs();
    }

    return Wrap(
      spacing: 12.0,
      runSpacing: 8.0,
      children: [
        _buildInfoRow(
          context,
          icon: Icons.open_with,
          subtitle: 'Distances (LTRB)',
          child: Text(
            '${left.toStringAsFixed(1)}, ${top.toStringAsFixed(1)}, ${right.toStringAsFixed(1)}, ${bottom.toStringAsFixed(1)}',
          ),
          backgroundColor: theme.chipTheme.backgroundColor,
        ),
      ],
    );
  }

  String _formatBorderRadiusLTRB(BorderRadiusGeometry geometry) {
    final resolved = geometry.resolve(TextDirection.ltr);

    String f(double v) => v.toStringAsFixed(1);

    return '${f(resolved.topLeft.x)}, ${f(resolved.topRight.x)}, ${f(resolved.bottomRight.x)}, ${f(resolved.bottomLeft.x)}';
  }


  RenderDecoratedBox? _findSelectedDecoratedBox() {
    final target = boxInfo.targetRenderBox;
    return target is RenderDecoratedBox ? target : null;
  }

  RenderDecoratedBox? _findNearestDecoratedBoxFromHitTestPath() {
    // When tapping a Container, the selected RenderBox might be a child
    // (e.g. alignment/padding) instead of the RenderDecoratedBox itself.
    // Use the hitTestPath to locate the nearest decorated box in the same
    // subtree under the pointer.
    for (final box in boxInfo.hitTestPath) {
      if (box is RenderDecoratedBox) return box;
    }
    return null;
  }

  RenderDecoratedBox? _findDecoratedBoxForDisplay() {
    // Prefer the selected render object when it is decorated; otherwise, fall
    // back to the nearest decorated box under the pointer.
    return _findSelectedDecoratedBox() ?? _findNearestDecoratedBoxFromHitTestPath();
  }

  bool _hasSelectedDecoratedInfo() {
    // Selection-first policy: never show decoration info when the selected box
    // is a RenderParagraph (text selection should focus on text).
    if (boxInfo.targetRenderBox is RenderParagraph) return false;

    final decorated = _findDecoratedBoxForDisplay();
    if (decorated == null) return false;

    final d = decorated.decoration;
    if (d is! BoxDecoration) return false;

    return d.color != null ||
        d.borderRadius != null ||
        d.shape != BoxShape.rectangle ||
        d.border != null ||
        d.boxShadow != null ||
        d.gradient != null;
  }

  Widget _buildRenderDecoratedBoxInfo(BuildContext context) {
    final theme = Theme.of(context);

    final renderDecoratedBox = _findDecoratedBoxForDisplay();
    if (renderDecoratedBox == null) return const SizedBox.shrink();

    final decoration = renderDecoratedBox.decoration;
    if (decoration is! BoxDecoration) return const SizedBox.shrink();

    final borderRadius = decoration.borderRadius;

    return Wrap(
      spacing: 12.0,
      runSpacing: 8.0,
      children: [
        if (borderRadius != null)
          _buildInfoRow(
            context,
            icon: Icons.rounded_corner,
            subtitle: 'border radius (LTRB)',
            backgroundColor: theme.chipTheme.backgroundColor,
            child: Text(_formatBorderRadiusLTRB(borderRadius)),
          ),
        if (decoration.shape != BoxShape.rectangle)
          _buildInfoRow(
            context,
            icon: Icons.circle_outlined,
            subtitle: 'shape',
            backgroundColor: theme.chipTheme.backgroundColor,
            child: Text(decoration.shape.toString()),
          ),
        _buildInfoRow(
          context,
          icon: Icons.palette,
          subtitle: 'color',
          backgroundColor: theme.chipTheme.backgroundColor,
          child: Text(
            decoration.color != null
                ? '#${colorToHexString(decoration.color!, withAlpha: true)}'
                : 'n/a',
          ),
        ),
      ],
    );
  }

  List<TextStyle> _extractTextStyles(
    InlineSpan span, [
    List<TextStyle>? styles,
  ]) {
    styles ??= [];

    if (span.style != null) {
      styles.add(span.style!);
    }

    if (span is TextSpan && span.children != null) {
      for (final child in span.children!) {
        _extractTextStyles(child, styles);
      }
    }

    return styles;
  }

  Widget _buildRenderParagraphInfo(BuildContext context) {
    final theme = Theme.of(context);

    final target = boxInfo.targetRenderBox;
    if (target is! RenderParagraph) return const SizedBox.shrink();

    final styles = _extractTextStyles(target.text);

    if (styles.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: styles
          .map(
            (style) => Wrap(
              spacing: 12.0,
              runSpacing: 8.0,
              children: [
                _buildInfoRow(
                  context,
                  icon: Icons.font_download,
                  subtitle: 'font family',
                  backgroundColor: theme.chipTheme.backgroundColor,
                  child: Text(style.fontFamily ?? 'n/a'),
                ),
                _buildInfoRow(
                  context,
                  icon: Icons.format_size,
                  subtitle: 'font size',
                  backgroundColor: theme.chipTheme.backgroundColor,
                  child: Text(style.fontSize?.toStringAsFixed(1) ?? 'n/a'),
                ),
                _buildInfoRow(
                  context,
                  icon: Icons.text_format,
                  subtitle: 'decoration',
                  backgroundColor: theme.chipTheme.backgroundColor,
                  child: Text(style.decoration?.toString() ?? 'n/a'),
                ),
                _buildInfoRow(
                  context,
                  icon: Icons.color_lens,
                  subtitle: 'color',
                  backgroundColor: theme.chipTheme.backgroundColor,
                  child: Text(
                    style.color != null
                        ? '#${colorToHexString(style.color!, withAlpha: true)}'
                        : 'n/a',
                  ),
                ),
                _buildInfoRow(
                  context,
                  icon: Icons.height,
                  subtitle: 'height',
                  backgroundColor: theme.chipTheme.backgroundColor,
                  child: Text(style.height?.toStringAsFixed(1) ?? 'n/a'),
                ),
                _buildInfoRow(
                  context,
                  icon: Icons.horizontal_distribute,
                  subtitle: 'Letter Spacing',
                  backgroundColor: theme.chipTheme.backgroundColor,
                  child: Text(style.letterSpacing?.toStringAsFixed(1) ?? 'n/a'),
                ),
                _buildInfoRow(
                  context,
                  icon: Icons.line_weight,
                  subtitle: 'weight',
                  backgroundColor: theme.chipTheme.backgroundColor,
                  child: Text(style.fontWeight?.toString() ?? 'n/a'),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final target = boxInfo.targetRenderBox;
    final isSelectedParagraph = target is RenderParagraph;
    final hasSelectedDecoration = !isSelectedParagraph && _hasSelectedDecoratedInfo();

    return Card(
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
                    describeIdentity(boxInfo.targetRenderBox),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  child: const Text('Copy'),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(
                        text: boxInfo.targetRenderBox.toStringDeep(),
                      ),
                    );
                  },
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
              if (boxInfo.targetRenderBox.attached == true &&
                  comparedBoxInfo?.targetRenderBox.attached == true) ...[
                Divider(
                  height: 16.0,
                  color: theme.dividerColor,
                ),
                _buildComparedRow(context),
              ],
              if (isSelectedParagraph) ...[
                Divider(
                  height: 16.0,
                  color: theme.dividerColor,
                ),
                _buildRenderParagraphInfo(context),
              ] else if (hasSelectedDecoration) ...[
                Divider(
                  height: 16.0,
                  color: theme.dividerColor,
                ),
                _buildRenderDecoratedBoxInfo(context),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

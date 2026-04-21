import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:inspector/src/widgets/components/property_extractors.dart';
import 'package:inspector/src/widgets/components/property_widgets.dart';
import 'package:inspector/src/widgets/inspector/box_info.dart';
import 'package:inspector/src/widgets/inspector/compare_distances.dart';
import 'package:inspector/src/widgets/inspector/render_box_extension.dart';

class BoxInfoPanelWidget extends StatelessWidget {
  const BoxInfoPanelWidget({
    super.key,
    required this.boxInfo,
    this.comparedBoxInfo,
    this.onCompare,
    this.isCompareActive = false,
  });

  final BoxInfo boxInfo;
  final BoxInfo? comparedBoxInfo;
  final VoidCallback? onCompare;
  final bool isCompareActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = boxInfo.targetRenderBox;
    final dividerColor = theme.colorScheme.outlineVariant;
    final hasCompare =
        target.attached && comparedBoxInfo?.targetRenderBox.attached == true;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: true,
            title: _PanelTitleBar(
              target: target,
              onCompare: onCompare,
              isCompareActive: isCompareActive,
            ),
            childrenPadding: const EdgeInsets.only(
              left: 12.0,
              right: 12.0,
              bottom: 12.0,
            ),
            expandedAlignment: Alignment.centerLeft,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MainRow(boxInfo: boxInfo),
              Divider(height: 16.0, color: dividerColor),
              PropSection(props: constraintsProps(target.constraints)),
              if (hasCompare) ...[
                Divider(height: 16.0, color: dividerColor),
                _ComparedRow(
                  boxInfo: boxInfo,
                  comparedBoxInfo: comparedBoxInfo!,
                ),
              ],
              ..._buildTargetSections(target, dividerColor),
              ..._buildWrapperSections(theme, dividerColor),
            ],
          ),
        ),
      ),
    );
  }

  /// Paragraph gets a dedicated section (text preview + span style
  /// breakdown). Everything else collapses type-specific props and resolved
  /// decoration into a single [PropSection].
  List<Widget> _buildTargetSections(RenderBox target, Color dividerColor) {
    if (target is RenderParagraph) {
      return [
        Divider(height: 16.0, color: dividerColor),
        _ParagraphSection(target: target),
      ];
    }
    final props = [...typeProps(target), ..._resolvedDecorationProps()];
    if (props.isEmpty) return const [];
    return [
      Divider(height: 16.0, color: dividerColor),
      PropSection(props: props),
    ];
  }

  /// Decoration resolved from the hit-test path. Prefers [ColoredBox] color
  /// over [BoxDecoration] to avoid duplication when a ColoredBox wraps a
  /// decorated child.
  List<PropSpec> _resolvedDecorationProps() {
    final coloredBoxColor = boxInfo.coloredBoxColor;
    if (coloredBoxColor != null) {
      return [
        (
          icon: Icons.palette,
          subtitle: 'color',
          child: ColorHexChip(coloredBoxColor),
        ),
      ];
    }
    if (boxInfo.decoratedBoxForDisplay?.decoration case final BoxDecoration d) {
      return decorationProps(d);
    }
    return [];
  }

  /// Surfaces same-size ancestor wrappers (Transform, Clip*, BackdropFilter,
  /// Opacity, FittedBox, etc.) whose props would otherwise be hidden when
  /// the inspector selects an inner decorated/proxy child.
  List<Widget> _buildWrapperSections(ThemeData theme, Color dividerColor) {
    final wrappers = _wrappersWithTypeProps();
    if (wrappers.isEmpty) return const [];
    return [
      for (final box in wrappers) ...[
        Divider(height: 16.0, color: dividerColor),
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            describeIdentity(box),
            style: theme.textTheme.bodySmall,
          ),
        ),
        PropSection(props: typeProps(box)),
      ],
    ];
  }

  /// Walks the parent chain, collecting render boxes that share the target's
  /// paint size and carry type-specific props. Stops at the first size
  /// mismatch — wrappers further up apply to a different bounding box, so
  /// surfacing them here would mislead about what the displayed size
  /// actually represents.
  List<RenderBox> _wrappersWithTypeProps() {
    final target = boxInfo.targetRenderBox;
    final result = <RenderBox>[];
    var current = target.parent;
    while (current is RenderBox && current.size == target.size) {
      if (hasTypeProps(current)) result.add(current);
      current = current.parent;
    }
    return result;
  }
}

// ─── Private widgets ─────────────────────────────────────────────────────────

class _PanelTitleBar extends StatelessWidget {
  const _PanelTitleBar({
    required this.target,
    required this.onCompare,
    required this.isCompareActive,
  });

  final RenderBox target;
  final VoidCallback? onCompare;
  final bool isCompareActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
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
    );
  }
}

class _MainRow extends StatelessWidget {
  const _MainRow({required this.boxInfo});
  final BoxInfo boxInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displaySize = boxInfo.targetRenderBox.displaySize;
    final bg = theme.chipTheme.backgroundColor;
    return Wrap(
      spacing: 12.0,
      runSpacing: 8.0,
      children: [
        PropChip(
          icon: Icons.format_shapes,
          subtitle: 'size',
          backgroundColor: bg,
          child: Text(
            '${displaySize.width.toStringAsFixed(1)} × '
            '${displaySize.height.toStringAsFixed(1)}',
          ),
        ),
        if (boxInfo.containerRect != null && !boxInfo.isContainerFlex)
          PropChip(
            icon: Icons.straighten,
            subtitle: 'padding (LTRB)',
            backgroundColor: bg,
            child: Text(boxInfo.describeOriginalPadding()),
          ),
      ],
    );
  }
}

class _ComparedRow extends StatelessWidget {
  const _ComparedRow({
    required this.boxInfo,
    required this.comparedBoxInfo,
  });

  final BoxInfo boxInfo;
  final BoxInfo comparedBoxInfo;

  @override
  Widget build(BuildContext context) {
    final originalWidth = boxInfo.targetRenderBox.size.width;
    final scale =
        originalWidth > 0 ? boxInfo.targetRect.width / originalWidth : 1.0;
    final distances = computeCompareDistances(
      boxInfo.targetRect,
      comparedBoxInfo.targetRect,
      scale: scale,
    );
    return PropSection(
      props: [
        for (final d in distances)
          (
            icon: d.icon,
            subtitle: d.side.name,
            child: Text(d.value.toStringAsFixed(1)),
          ),
      ],
    );
  }
}

class _ParagraphSection extends StatelessWidget {
  const _ParagraphSection({required this.target});
  final RenderParagraph target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = theme.colorScheme.outlineVariant;
    final spanSections = extractTextStyles(target.text)
        .map(spanProps)
        .where((p) => p.isNotEmpty)
        .toList();
    final preview = previewText(target.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        if (preview.isNotEmpty)
          PropChip(
            icon: Icons.text_snippet_outlined,
            subtitle: 'text',
            backgroundColor: theme.chipTheme.backgroundColor,
            expandChild: true,
            child: Text(
              '"$preview"',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        PropSection(props: paragraphProps(target)),
        if (spanSections.isNotEmpty) ...[
          Divider(height: 12, color: dividerColor),
          for (final props in spanSections) PropSection(props: props),
        ],
      ],
    );
  }
}

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
    required this.targetColor,
    required this.containerColor,
    required this.onVisibilityChanged,
    this.isVisible = true,
  }) : super(key: key);

  final bool isVisible;
  final ValueChanged<bool> onVisibilityChanged;
  final BoxInfo boxInfo;
  final Color targetColor;
  final Color containerColor;

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
          color: iconColor ?? theme.textTheme.caption?.color,
        ),
        const SizedBox(width: 12.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            child,
            const SizedBox(height: 0.0),
            Text(
              subtitle,
              style: theme.textTheme.caption?.copyWith(fontSize: 10.0),
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
            '${boxInfo.targetRect.width} × ${boxInfo.targetRect.height}',
          ),
          backgroundColor: theme.chipTheme.backgroundColor,
        ),
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

  Widget _buildRenderDecoratedBoxInfo(BuildContext context) {
    final theme = Theme.of(context);
    final _renderDecoratedBox = boxInfo.targetRenderBox as RenderDecoratedBox;

    final decoration = _renderDecoratedBox.decoration;

    if (decoration is! BoxDecoration) return const SizedBox.shrink();

    return Wrap(
      spacing: 12.0,
      runSpacing: 8.0,
      children: [
        _buildInfoRow(
          context,
          icon: Icons.rounded_corner,
          subtitle: 'border radius',
          backgroundColor: theme.chipTheme.backgroundColor,
          child: Text(decoration.borderRadius.toString()),
        ),
        _buildInfoRow(
          context,
          icon: Icons.palette,
          subtitle: 'color',
          backgroundColor: theme.chipTheme.backgroundColor,
          iconColor: decoration.color,
          child: Text(
            decoration.color != null
                ? '#${colorToHexString(decoration.color!, withAlpha: true)}'
                : 'n/a',
            style: TextStyle(color: decoration.color),
          ),
        ),
      ],
    );
  }

  Widget _buildRenderParagraphInfo(BuildContext context) {
    final theme = Theme.of(context);
    final _renderParagraph = boxInfo.targetRenderBox as RenderParagraph;

    final style = _renderParagraph.text.style;

    if (style == null) return const SizedBox.shrink();

    return Wrap(
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
          iconColor: style.color,
          backgroundColor: theme.chipTheme.backgroundColor,
          child: Text(
            _renderParagraph.text.style?.color != null
                ? '#${colorToHexString(style.color!, withAlpha: true)}'
                : 'n/a',
            style: TextStyle(
              color: style.color,
            ),
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
          icon: Icons.line_weight,
          subtitle: 'weight',
          backgroundColor: theme.chipTheme.backgroundColor,
          child: Text(style.fontWeight?.toString() ?? 'n/a'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    style: theme.textTheme.caption,
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
              // const SizedBox(height: 4.0),
              // _buildSizeRow(context),
              if (boxInfo.containerRect != null) ...[
                _buildMainRow(context),
              ],
              if (boxInfo.targetRenderBox is RenderParagraph) ...[
                Divider(
                  height: 16.0,
                  color: theme.dividerColor,
                ),
                _buildRenderParagraphInfo(context),
              ],
              if (boxInfo.targetRenderBox is RenderDecoratedBox) ...[
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

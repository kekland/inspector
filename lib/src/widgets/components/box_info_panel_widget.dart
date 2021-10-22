import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 20.0,
          color: Colors.blue,
        ),
        const SizedBox(width: 12.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            child,
            const SizedBox(height: 4.0),
            Text(subtitle, style: theme.textTheme.caption),
          ],
        ),
      ],
    );
  }

  Widget _buildPaddingRow(BuildContext context) {
    return _buildInfoRow(
      context,
      icon: Icons.straighten,
      subtitle: 'padding (LTRB)',
      child: Text(boxInfo.describePadding()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                describeIdentity(boxInfo.targetRenderBox),
                style: theme.textTheme.caption,
              ),
              // const SizedBox(height: 4.0),
              // _buildSizeRow(context),
              if (boxInfo.containerRect != null) ...[
                const SizedBox(height: 8.0),
                _buildPaddingRow(context),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

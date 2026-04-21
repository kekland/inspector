import 'dart:math' as math;

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
    bool expandChild = false,
  }) {
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
        Icon(icon,
            size: 20.0, color: iconColor ?? theme.textTheme.bodySmall?.color),
        const SizedBox(width: 12.0),
        if (expandChild)
          Expanded(child: column)
        else
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

  Widget _buildSection(BuildContext context, List<_PropSpec> props) {
    if (props.isEmpty) return const SizedBox.shrink();
    final bg = Theme.of(context).chipTheme.backgroundColor;
    return Wrap(
      spacing: 12.0,
      runSpacing: 8.0,
      children: [
        for (final p in props)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: _buildInfoRow(
              context,
              icon: p.icon,
              subtitle: p.subtitle,
              backgroundColor: bg,
              child: p.child,
            ),
          ),
      ],
    );
  }

  /// [Text] that truncates with ellipsis if it outgrows its chip. Used for
  /// properties with potentially unbounded length (URLs, toString() dumps of
  /// ColorFilter/ImageFilter, alignment/offset representations, etc.).
  Widget _ellipsized(String value) => Text(
        value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
      );

  /// Short, human-readable description of a [ColorFilter]. The default
  /// toString dump (`ColorFilter.mode(Color(alpha: ..., red: ..., ...), ...)`)
  /// is far too wide for the chip UI, so we extract the blend mode when
  /// possible and fall back to a trimmed form otherwise.
  String _describeColorFilter(ColorFilter f) {
    final s = f.toString();
    final blend = RegExp(r'BlendMode\.(\w+)').firstMatch(s);
    if (s.startsWith('ColorFilter.mode') && blend != null) {
      return 'mode · ${blend.group(1)}';
    }
    return s.replaceFirst('ColorFilter.', '');
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

  List<_PropSpec> _paragraphProps(RenderParagraph target) {
    return [
      (
        icon: Icons.format_align_left,
        subtitle: 'text align',
        child: Text(target.textAlign.name),
      ),
      if (target.maxLines != null)
        (
          icon: Icons.format_list_numbered,
          subtitle: 'max lines',
          child: Text('${target.maxLines}'),
        ),
      if (target.didExceedMaxLines)
        (
          icon: Icons.warning_amber,
          subtitle: 'overflow',
          child: const Text('exceeded'),
        ),
      if (target.overflow != TextOverflow.clip)
        (
          icon: Icons.more_horiz,
          subtitle: 'overflow',
          child: Text(target.overflow.name),
        ),
      if (!target.softWrap)
        (
          icon: Icons.wrap_text,
          subtitle: 'soft wrap',
          child: const Text('off'),
        ),
      if (target.textScaler != TextScaler.noScaling)
        (
          icon: Icons.text_fields,
          subtitle: 'text scale',
          child: Text(target.textScaler.toString()),
        ),
    ];
  }

  String _previewText(InlineSpan span) {
    final buf = StringBuffer();
    span.visitChildren((child) {
      if (child is TextSpan && child.text != null) buf.write(child.text);
      return buf.length < 120;
    });
    final raw = buf.toString().replaceAll('\n', '⏎');
    if (raw.length <= 80) return raw;
    return '${raw.substring(0, 80)}…';
  }

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
        if (_formatBorderRadius(d.borderRadius ?? BorderRadius.zero)
            case final br?)
          (
            icon: Icons.rounded_corner,
            subtitle: br.label,
            child: Text(br.value),
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
        if (d.image != null) ..._decorationImageProps(d.image!),
      ];

  List<_PropSpec> _decorationImageProps(DecorationImage img) => [
        (
          icon: Icons.image,
          subtitle: 'bg image',
          child: _ellipsized(_describeImageProvider(img.image)),
        ),
        (
          icon: Icons.fit_screen,
          subtitle: 'bg fit',
          child: Text(img.fit?.name ?? 'scaleDown'),
        ),
        if (img.alignment != Alignment.center)
          (
            icon: Icons.crop_free,
            subtitle: 'bg alignment',
            child: _ellipsized(img.alignment.toString()),
          ),
        if (img.repeat != ImageRepeat.noRepeat)
          (
            icon: Icons.repeat,
            subtitle: 'bg repeat',
            child: Text(img.repeat.name),
          ),
        if (img.colorFilter != null)
          (
            icon: Icons.filter_b_and_w,
            subtitle: 'bg filter',
            child: _ellipsized(_describeColorFilter(img.colorFilter!)),
          ),
      ];

  /// Best-effort short description of an [ImageProvider] — URL for network,
  /// asset name for bundled assets, file path for files, otherwise runtimeType.
  String _describeImageProvider(ImageProvider provider) {
    if (provider is NetworkImage) return provider.url;
    if (provider is AssetImage) return provider.assetName;
    if (provider is ExactAssetImage) return provider.assetName;
    if (provider is FileImage) return provider.file.path;
    if (provider is MemoryImage) {
      return 'MemoryImage(${provider.bytes.length}B)';
    }
    if (provider is ResizeImage) {
      return '${provider.width ?? '?'}×${provider.height ?? '?'} '
          '${_describeImageProvider(provider.imageProvider)}';
    }
    return provider.runtimeType.toString();
  }

  List<_PropSpec> _stackProps(RenderStack target) => [
        (
          icon: Icons.align_vertical_bottom,
          subtitle: 'alignment',
          child: _ellipsized(target.alignment.toString()),
        ),
        if (target.fit != StackFit.loose)
          (
            icon: Icons.fit_screen,
            subtitle: 'fit',
            child: Text(target.fit.name),
          ),
      ];

  List<_PropSpec> _wrapProps(RenderWrap target) => [
        (
          icon: Icons.swap_horiz,
          subtitle: 'direction',
          child: Text(target.direction.name),
        ),
        if (target.spacing != 0)
          (
            icon: Icons.space_bar,
            subtitle: 'spacing',
            child: Text(target.spacing.toStringAsFixed(1)),
          ),
        if (target.runSpacing != 0)
          (
            icon: Icons.height,
            subtitle: 'run spacing',
            child: Text(target.runSpacing.toStringAsFixed(1)),
          ),
        if (target.alignment != WrapAlignment.start)
          (
            icon: Icons.format_align_left,
            subtitle: 'alignment',
            child: Text(target.alignment.name),
          ),
        if (target.runAlignment != WrapAlignment.start)
          (
            icon: Icons.vertical_align_top,
            subtitle: 'run alignment',
            child: Text(target.runAlignment.name),
          ),
      ];

  _PropSpec? _clipBehaviorProp(Clip clipBehavior) => clipBehavior == Clip.none
      ? null
      : (
          icon: Icons.crop,
          subtitle: 'clip behavior',
          child: Text(clipBehavior.name),
        );

  List<_PropSpec> _clipRRectProps(RenderClipRRect target) => [
        if (_formatBorderRadius(target.borderRadius) case final br?)
          (
            icon: Icons.rounded_corner,
            subtitle: br.label,
            child: Text(br.value),
          ),
        if (_clipBehaviorProp(target.clipBehavior) case final c?) c,
      ];

  List<_PropSpec> _clipRectProps(RenderClipRect target) => [
        if (target.clipper != null)
          (
            icon: Icons.brush,
            subtitle: 'clipper',
            child: Text(target.clipper.runtimeType.toString()),
          ),
        if (_clipBehaviorProp(target.clipBehavior) case final c?) c,
      ];

  List<_PropSpec> _clipOvalProps(RenderClipOval target) => [
        if (target.clipper != null)
          (
            icon: Icons.brush,
            subtitle: 'clipper',
            child: Text(target.clipper.runtimeType.toString()),
          ),
        if (_clipBehaviorProp(target.clipBehavior) case final c?) c,
      ];

  List<_PropSpec> _clipPathProps(RenderClipPath target) => [
        if (target.clipper != null)
          (
            icon: Icons.brush,
            subtitle: 'clipper',
            child: Text(target.clipper.runtimeType.toString()),
          ),
        if (_clipBehaviorProp(target.clipBehavior) case final c?) c,
      ];

  List<_PropSpec> _customPaintProps(RenderCustomPaint target) => [
        if (target.painter != null)
          (
            icon: Icons.brush,
            subtitle: 'painter',
            child: Text(target.painter.runtimeType.toString()),
          ),
        if (target.foregroundPainter != null)
          (
            icon: Icons.brush,
            subtitle: 'fg painter',
            child: Text(target.foregroundPainter.runtimeType.toString()),
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

  List<_PropSpec> _imageProps(RenderImage target) {
    final provider = _resolveImageProvider(target);
    final rawImage = target.image;
    return [
      if (provider != null)
        (
          icon: Icons.image,
          subtitle: 'source',
          child: _ellipsized(_describeImageProvider(provider)),
        ),
      if (rawImage != null)
        (
          icon: Icons.photo_size_select_large,
          subtitle: 'raw px',
          child: Text('${rawImage.width}×${rawImage.height}'),
        ),
      if (target.fit != null)
        (
          icon: Icons.fit_screen,
          subtitle: 'fit',
          child: Text(target.fit!.name),
        ),
      (
        icon: Icons.crop_free,
        subtitle: 'alignment',
        child: _ellipsized(target.alignment.toString()),
      ),
      if (target.width != null)
        (
          icon: Icons.swap_horiz,
          subtitle: 'width',
          child: Text(target.width!.toStringAsFixed(1)),
        ),
      if (target.height != null)
        (
          icon: Icons.swap_vert,
          subtitle: 'height',
          child: Text(target.height!.toStringAsFixed(1)),
        ),
      if (target.repeat != ImageRepeat.noRepeat)
        (
          icon: Icons.repeat,
          subtitle: 'repeat',
          child: Text(target.repeat.name),
        ),
      if (target.color != null)
        (
          icon: Icons.color_lens,
          subtitle: 'color tint',
          child: _ColorSwatch(target.color!),
        ),
    ];
  }

  /// Tries to recover the originating [ImageProvider] via the render object's
  /// debug creator. Only works in debug builds where Flutter populates
  /// [RenderObject.debugCreator]; returns `null` in release/profile.
  ImageProvider? _resolveImageProvider(RenderImage target) {
    if (!kDebugMode) return null;
    final creator = target.debugCreator;
    if (creator is! DebugCreator) return null;
    final widget = creator.element.widget;
    if (widget is Image) return widget.image;
    return null;
  }

  List<_PropSpec> _opacityProps(RenderOpacity target) => [
        (
          icon: Icons.opacity,
          subtitle: 'opacity',
          child: Text(target.opacity.toStringAsFixed(2))
        ),
      ];

  List<_PropSpec> _physicalModelProps({
    required Color color,
    required double elevation,
    required Color shadowColor,
  }) =>
      [
        (
          icon: Icons.palette,
          subtitle: 'color',
          child: _ColorSwatch(color),
        ),
        if (elevation > 0)
          (
            icon: Icons.layers,
            subtitle: 'elevation',
            child: Text(elevation.toStringAsFixed(1)),
          ),
        (
          icon: Icons.blur_on,
          subtitle: 'shadow color',
          child: _ColorSwatch(shadowColor),
        ),
      ];

  List<_PropSpec> _physicalShapeProps(RenderPhysicalShape target) =>
      _physicalModelProps(
        color: target.color,
        elevation: target.elevation,
        shadowColor: target.shadowColor,
      );

  List<_PropSpec> _physicalModelBoxProps(RenderPhysicalModel target) =>
      _physicalModelProps(
        color: target.color,
        elevation: target.elevation,
        shadowColor: target.shadowColor,
      );

  List<_PropSpec> _fittedBoxProps(RenderFittedBox target) => [
        (
          icon: Icons.fit_screen,
          subtitle: 'fit',
          child: Text(target.fit.name),
        ),
        if (target.alignment != Alignment.center)
          (
            icon: Icons.crop_free,
            subtitle: 'alignment',
            child: _ellipsized(target.alignment.toString()),
          ),
      ];

  List<_PropSpec> _aspectRatioProps(RenderAspectRatio target) => [
        (
          icon: Icons.aspect_ratio,
          subtitle: 'aspect ratio',
          child: Text(target.aspectRatio.toStringAsFixed(2)),
        ),
      ];

  List<_PropSpec> _transformProps(RenderTransform target) {
    final matrix = Matrix4.identity();
    final child = target.child;
    if (child != null) target.applyPaintTransform(child, matrix);
    final m = matrix.storage;
    final tx = m[12];
    final ty = m[13];
    final scaleX = math.sqrt(m[0] * m[0] + m[1] * m[1]);
    final scaleY = math.sqrt(m[4] * m[4] + m[5] * m[5]);
    final rotationRad = math.atan2(m[1], m[0]);
    final rotationDeg = rotationRad * 180 / math.pi;
    String f(double v) => v.toStringAsFixed(2);

    return [
      if (tx.abs() > 0.001 || ty.abs() > 0.001)
        (
          icon: Icons.open_with,
          subtitle: 'translate',
          child: Text('(${f(tx)}, ${f(ty)})'),
        ),
      if ((scaleX - 1).abs() > 0.001 || (scaleY - 1).abs() > 0.001)
        (
          icon: Icons.zoom_out_map,
          subtitle: 'scale',
          child: Text(
            scaleX == scaleY ? f(scaleX) : '${f(scaleX)}, ${f(scaleY)}',
          ),
        ),
      if (rotationDeg.abs() > 0.01)
        (
          icon: Icons.rotate_right,
          subtitle: 'rotation°',
          child: Text(f(rotationDeg)),
        ),
      if (target.origin != null)
        (
          icon: Icons.place,
          subtitle: 'origin',
          child: _ellipsized(target.origin.toString()),
        ),
      if (target.alignment != null)
        (
          icon: Icons.crop_free,
          subtitle: 'alignment',
          child: _ellipsized(target.alignment.toString()),
        ),
      if (!target.transformHitTests)
        (
          icon: Icons.touch_app,
          subtitle: 'hit tests',
          child: const Text('untransformed'),
        ),
    ];
  }

  List<_PropSpec> _editableProps(RenderEditable target) => [
        (
          icon: Icons.format_align_left,
          subtitle: 'text align',
          child: Text(target.textAlign.name),
        ),
        if (target.cursorColor != null)
          (
            icon: Icons.text_fields,
            subtitle: 'cursor',
            child: _ColorSwatch(target.cursorColor!),
          ),
        if (target.selectionColor != null)
          (
            icon: Icons.select_all,
            subtitle: 'selection',
            child: _ColorSwatch(target.selectionColor!),
          ),
        if (target.obscureText)
          (
            icon: Icons.password,
            subtitle: 'obscure',
            child: const Text('on'),
          ),
        if (target.readOnly)
          (
            icon: Icons.lock_outline,
            subtitle: 'read only',
            child: const Text('on'),
          ),
        if (target.maxLines != 1)
          (
            icon: Icons.format_list_numbered,
            subtitle: 'max lines',
            child: Text(target.maxLines?.toString() ?? '∞'),
          ),
        if (target.minLines != null)
          (
            icon: Icons.format_list_numbered,
            subtitle: 'min lines',
            child: Text(target.minLines.toString()),
          ),
        if (target.enableInteractiveSelection == false)
          (
            icon: Icons.select_all,
            subtitle: 'interactive sel.',
            child: const Text('off'),
          ),
      ];

  List<_PropSpec> _backdropFilterProps(RenderBackdropFilter target) {
    final filterStr = target.filter.toString();
    return [
      (
        icon: Icons.blur_on,
        subtitle: 'filter',
        child: _ellipsized(filterStr),
      ),
      if (target.blendMode != BlendMode.srcOver)
        (
          icon: Icons.layers,
          subtitle: 'blend mode',
          child: Text(target.blendMode.name),
        ),
    ];
  }

  List<_PropSpec> _clipRSuperellipseProps(RenderClipRSuperellipse target) => [
        if (_formatBorderRadius(target.borderRadius) case final br?)
          (
            icon: Icons.rounded_corner,
            subtitle: br.label,
            child: Text(br.value),
          ),
        if (_clipBehaviorProp(target.clipBehavior) case final c?) c,
      ];

  // ─── Format helpers ───────────────────────────────────────────

  String _formatRadius(Radius r) {
    String f(double v) => v.toStringAsFixed(1);
    return r.x == r.y ? f(r.x) : '${f(r.x)}×${f(r.y)}';
  }

  /// Formats a [BorderRadiusGeometry] collapsing uniform values and showing
  /// elliptical (x×y) radii only when x != y.
  ///
  /// Returns `null` when the radius is zero (caller should skip the chip).
  ({String label, String value})? _formatBorderRadius(
      BorderRadiusGeometry geometry) {
    final r = geometry.resolve(TextDirection.ltr);
    if (r == BorderRadius.zero) return null;

    final corners = [r.topLeft, r.topRight, r.bottomRight, r.bottomLeft];
    final allEqual = corners.every((c) => c == corners.first);
    if (allEqual) {
      return (label: 'border radius', value: _formatRadius(corners.first));
    }
    return (
      label: 'radius TL/TR/BR/BL',
      value: corners.map(_formatRadius).join(', '),
    );
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
    String f(double v) => v.toStringAsFixed(1);
    String line(BoxShadow s) {
      final parts = <String>[
        'blur:${f(s.blurRadius)}',
        if (s.spreadRadius != 0) 'spread:${f(s.spreadRadius)}',
        '(${f(s.offset.dx)},${f(s.offset.dy)})',
      ];
      return parts.join(' ');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final s in shadows)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [_ColorSwatch(s.color), Text(line(s))],
          ),
      ],
    );
  }

  Widget _gradientPreview(Gradient g) => Container(
        width: 64,
        height: 14,
        decoration: BoxDecoration(
          gradient: g,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
      );

  Widget _gradientWidget(Gradient g) {
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
          children: [_gradientPreview(g), Text(type)],
        ),
        for (var i = 0; i < g.colors.length; i++)
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              _ColorSwatch(g.colors[i]),
              if (stops != null && i < stops.length)
                Text('@${stops[i].toStringAsFixed(2)}'),
            ],
          ),
        for (final d in detail) Text(d, style: const TextStyle(fontSize: 10)),
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
    final theme = Theme.of(context);
    final dividerColor = theme.colorScheme.outlineVariant;
    final spanSections = _extractTextStyles(target.text)
        .map(_spanProps)
        .where((p) => p.isNotEmpty)
        .toList();
    final preview = _previewText(target.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        if (preview.isNotEmpty)
          _buildInfoRow(
            context,
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
        if (target is RenderWrap) ..._wrapProps(target),
        if (target is RenderImage) ..._imageProps(target),
        if (target is RenderOpacity) ..._opacityProps(target),
        if (target is RenderAnimatedOpacity)
          (
            icon: Icons.opacity,
            subtitle: 'opacity',
            child: Text(target.opacity.value.toStringAsFixed(2)),
          ),
        if (target is RenderPhysicalShape) ..._physicalShapeProps(target),
        if (target is RenderPhysicalModel) ..._physicalModelBoxProps(target),
        if (target is RenderClipRRect) ..._clipRRectProps(target),
        if (target is RenderClipRSuperellipse)
          ..._clipRSuperellipseProps(target),
        if (target is RenderClipRect) ..._clipRectProps(target),
        if (target is RenderClipOval) ..._clipOvalProps(target),
        if (target is RenderClipPath) ..._clipPathProps(target),
        if (target is RenderCustomPaint) ..._customPaintProps(target),
        if (target is RenderFittedBox) ..._fittedBoxProps(target),
        if (target is RenderAspectRatio) ..._aspectRatioProps(target),
        if (target is RenderTransform) ..._transformProps(target),
        if (target is RenderBackdropFilter) ..._backdropFilterProps(target),
        if (target is RenderEditable) ..._editableProps(target),
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

  /// Ancestor render boxes of [targetRenderBox] with the same paint size that
  /// carry type-specific props (Transform, Clip*, BackdropFilter, Opacity,
  /// FittedBox, etc.). These are wrappers whose properties would otherwise
  /// be hidden when the inspector picks an inner decorated/proxy child.
  ///
  /// Walks the parent chain and stops at the first render object whose size
  /// diverges from the target — wrappers further up apply to a different
  /// bounding box, so surfacing them here would be misleading.
  List<RenderBox> _wrappersWithTypeProps() {
    final target = boxInfo.targetRenderBox;
    final result = <RenderBox>[];
    var current = target.parent;
    while (current is RenderBox && current.size == target.size) {
      if (_hasTypeProps(current)) result.add(current);
      current = current.parent;
    }
    return result;
  }

  bool _hasTypeProps(RenderBox box) =>
      box is RenderTransform ||
      box is RenderBackdropFilter ||
      box is RenderClipRect ||
      box is RenderClipRRect ||
      box is RenderClipRSuperellipse ||
      box is RenderClipOval ||
      box is RenderClipPath ||
      box is RenderFittedBox ||
      box is RenderAspectRatio ||
      box is RenderOpacity ||
      box is RenderAnimatedOpacity ||
      box is RenderPhysicalShape ||
      box is RenderPhysicalModel ||
      box is RenderCustomPaint;

  List<Widget> _buildWrapperSections(BuildContext context) {
    final wrappers = _wrappersWithTypeProps();
    if (wrappers.isEmpty) return const [];
    final theme = Theme.of(context);
    final dividerColor = theme.colorScheme.outlineVariant;
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
        _buildSection(context, _typeProps(box)),
      ],
    ];
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
              ..._buildWrapperSections(context),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:inspector/src/widgets/components/property_widgets.dart';

// ─── Format helpers ──────────────────────────────────────────────────────────

String _fmt(double v, [int digits = 1]) => v.toStringAsFixed(digits);

String _fmtOffset(Offset o) => '(${_fmt(o.dx)}, ${_fmt(o.dy)})';

/// Formats a single [Radius], collapsing to a scalar when x == y.
String formatRadius(Radius r) =>
    r.x == r.y ? _fmt(r.x) : '${_fmt(r.x)}×${_fmt(r.y)}';

/// Formats a [BorderRadiusGeometry], collapsing uniform values and showing
/// elliptical `(x×y)` radii only when x != y.
///
/// Returns `null` when the radius is zero — callers should skip the chip.
({String label, String value})? formatBorderRadius(
    BorderRadiusGeometry geometry) {
  final r = geometry.resolve(TextDirection.ltr);
  if (r == BorderRadius.zero) return null;
  final corners = [r.topLeft, r.topRight, r.bottomRight, r.bottomLeft];
  if (corners.every((c) => c == corners.first)) {
    return (label: 'border radius', value: formatRadius(corners.first));
  }
  return (
    label: 'radius TL/TR/BR/BL',
    value: corners.map(formatRadius).join(', '),
  );
}

/// Best-effort short description of an [ImageProvider]: URL for network
/// images, asset name for bundled assets, file path for files, else runtime
/// type. Recurses into [ResizeImage].
String describeImageProvider(ImageProvider provider) {
  if (provider is NetworkImage) return provider.url;
  if (provider is AssetImage) return provider.assetName;
  if (provider is ExactAssetImage) return provider.assetName;
  if (provider is FileImage) return provider.file.path;
  if (provider is MemoryImage) return 'MemoryImage(${provider.bytes.length}B)';
  if (provider is ResizeImage) {
    return '${provider.width ?? '?'}×${provider.height ?? '?'} '
        '${describeImageProvider(provider.imageProvider)}';
  }
  return provider.runtimeType.toString();
}

/// Short, human-readable description of a [ColorFilter].
///
/// [ColorFilter] exposes no accessors for its mode/color, so we parse
/// `toString()`. Brittle by design — the default dump
/// (`ColorFilter.mode(Color(alpha: ..., red: ..., ...), BlendMode.xxx)`)
/// is far too wide for a chip, and there is no alternative in the public
/// Flutter API as of 3.35. If upstream ever exposes fields, replace this.
String describeColorFilter(ColorFilter f) {
  final s = f.toString();
  final blend = RegExp(r'BlendMode\.(\w+)').firstMatch(s);
  if (s.startsWith('ColorFilter.mode') && blend != null) {
    return 'mode · ${blend.group(1)}';
  }
  return s.replaceFirst('ColorFilter.', '');
}

/// Flattens all [TextStyle]s found across an [InlineSpan] tree in traversal
/// order. Used to show each distinct span style as its own subsection.
List<TextStyle> extractTextStyles(InlineSpan span, [List<TextStyle>? out]) {
  out ??= [];
  if (span.style != null) out.add(span.style!);
  if (span is TextSpan && span.children != null) {
    for (final c in span.children!) {
      extractTextStyles(c, out);
    }
  }
  return out;
}

/// Truncated, newline-escaped plain-text preview of an [InlineSpan]. Caps at
/// 80 visible characters; appends `…` when the underlying text is longer.
String previewText(InlineSpan span) {
  final buf = StringBuffer();
  span.visitChildren((child) {
    if (child is TextSpan && child.text != null) buf.write(child.text);
    return buf.length < 120;
  });
  final raw = buf.toString().replaceAll('\n', '⏎');
  return raw.length <= 80 ? raw : '${raw.substring(0, 80)}…';
}

/// Recovers the [ImageProvider] that produced a [RenderImage] via its
/// `debugCreator`. Only works in debug builds where Flutter populates
/// [RenderObject.debugCreator]; returns `null` in release/profile.
ImageProvider? resolveImageProvider(RenderImage target) {
  if (!kDebugMode) return null;
  final creator = target.debugCreator;
  if (creator is! DebugCreator) return null;
  final widget = creator.element.widget;
  if (widget is Image) return widget.image;
  return null;
}

// ─── Property extractors ─────────────────────────────────────────────────────

List<PropSpec> constraintsProps(BoxConstraints c) {
  String fmt(double min, double max) {
    if (min == max) return '=${_fmt(min)}';
    final hi = max == double.infinity ? '∞' : _fmt(max);
    return '${_fmt(min)}–$hi';
  }

  return [
    (
      icon: Icons.swap_horiz,
      subtitle: 'W constraint',
      child: Text(fmt(c.minWidth, c.maxWidth)),
    ),
    (
      icon: Icons.swap_vert,
      subtitle: 'H constraint',
      child: Text(fmt(c.minHeight, c.maxHeight)),
    ),
  ];
}

List<PropSpec> paragraphProps(RenderParagraph target) => [
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

List<PropSpec> spanProps(TextStyle style) => [
      if (style.fontFamily != null)
        (
          icon: Icons.font_download,
          subtitle: 'font family',
          child: Text(style.fontFamily!),
        ),
      if (style.fontSize != null)
        (
          icon: Icons.format_size,
          subtitle: 'font size',
          child: Text(_fmt(style.fontSize!)),
        ),
      if (style.fontWeight != null)
        (
          icon: Icons.line_weight,
          subtitle: 'weight',
          child: Text(style.fontWeight.toString()),
        ),
      if (style.fontStyle != null)
        (
          icon: Icons.format_italic,
          subtitle: 'style',
          child: Text(style.fontStyle.toString()),
        ),
      if (style.color != null)
        (
          icon: Icons.color_lens,
          subtitle: 'color',
          child: ColorHexChip(style.color!),
        ),
      if (style.height != null)
        (
          icon: Icons.height,
          subtitle: 'height',
          child: Text(_fmt(style.height!)),
        ),
      if (style.letterSpacing != null)
        (
          icon: Icons.horizontal_distribute,
          subtitle: 'letter spacing',
          child: Text(_fmt(style.letterSpacing!)),
        ),
      if (style.wordSpacing != null)
        (
          icon: Icons.space_bar,
          subtitle: 'word spacing',
          child: Text(_fmt(style.wordSpacing!)),
        ),
      if (style.decoration != null && style.decoration != TextDecoration.none)
        (
          icon: Icons.text_format,
          subtitle: 'decoration',
          child: Text(style.decoration.toString()),
        ),
      if (style.backgroundColor != null)
        (
          icon: Icons.format_color_fill,
          subtitle: 'bg color',
          child: ColorHexChip(style.backgroundColor!),
        ),
    ];

List<PropSpec> decorationProps(BoxDecoration d) => [
      if (d.color != null)
        (
          icon: Icons.palette,
          subtitle: 'color',
          child: ColorHexChip(d.color!),
        ),
      if (formatBorderRadius(d.borderRadius ?? BorderRadius.zero)
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
          child: Text(d.shape.name),
        ),
      if (d.border != null) ..._borderProps(d.border!),
      if (d.boxShadow != null && d.boxShadow!.isNotEmpty)
        (
          icon: Icons.blur_on,
          subtitle: 'shadows',
          child: ShadowsView(d.boxShadow!),
        ),
      if (d.gradient != null)
        (
          icon: Icons.gradient,
          subtitle: 'gradient',
          child: GradientView(d.gradient!),
        ),
      if (d.image != null) ..._decorationImageProps(d.image!),
    ];

List<PropSpec> _decorationImageProps(DecorationImage img) => [
      (
        icon: Icons.image,
        subtitle: 'bg image',
        child: EllipsizedText(describeImageProvider(img.image)),
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
          child: EllipsizedText(img.alignment.toString()),
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
          child: EllipsizedText(describeColorFilter(img.colorFilter!)),
        ),
    ];

List<PropSpec> _borderProps(BoxBorder border) {
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
        children: [ColorHexChip(color), Text(wStr)],
      );

  // Uniform border — single chip
  if (colors.length == 1 && activeSides.isNotEmpty) {
    final wStr = widths.length == 1
        ? 'w:${_fmt(widths.first)}'
        : 'w:${sides.map((s) => _fmt(s.width)).join('/')}';
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
          child: sideChild(sides[i].color, 'w:${_fmt(sides[i].width)}'),
        ),
  ];
}

List<PropSpec> stackProps(RenderStack target) => [
      (
        icon: Icons.align_vertical_bottom,
        subtitle: 'alignment',
        child: EllipsizedText(target.alignment.toString()),
      ),
      if (target.fit != StackFit.loose)
        (
          icon: Icons.fit_screen,
          subtitle: 'fit',
          child: Text(target.fit.name),
        ),
    ];

List<PropSpec> wrapProps(RenderWrap target) => [
      (
        icon: Icons.swap_horiz,
        subtitle: 'direction',
        child: Text(target.direction.name),
      ),
      if (target.spacing != 0)
        (
          icon: Icons.space_bar,
          subtitle: 'spacing',
          child: Text(_fmt(target.spacing)),
        ),
      if (target.runSpacing != 0)
        (
          icon: Icons.height,
          subtitle: 'run spacing',
          child: Text(_fmt(target.runSpacing)),
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

PropSpec? _clipBehaviorProp(Clip clipBehavior) => clipBehavior == Clip.none
    ? null
    : (
        icon: Icons.crop,
        subtitle: 'clip behavior',
        child: Text(clipBehavior.name),
      );

List<PropSpec> clipRRectProps(RenderClipRRect target) => [
      if (formatBorderRadius(target.borderRadius) case final br?)
        (
          icon: Icons.rounded_corner,
          subtitle: br.label,
          child: Text(br.value),
        ),
      if (_clipBehaviorProp(target.clipBehavior) case final c?) c,
    ];

List<PropSpec> clipRSuperellipseProps(RenderClipRSuperellipse target) => [
      if (formatBorderRadius(target.borderRadius) case final br?)
        (
          icon: Icons.rounded_corner,
          subtitle: br.label,
          child: Text(br.value),
        ),
      if (_clipBehaviorProp(target.clipBehavior) case final c?) c,
    ];

List<PropSpec> clipRectProps(RenderClipRect target) =>
    _genericClipProps(target.clipper?.runtimeType, target.clipBehavior);

List<PropSpec> clipOvalProps(RenderClipOval target) =>
    _genericClipProps(target.clipper?.runtimeType, target.clipBehavior);

List<PropSpec> clipPathProps(RenderClipPath target) =>
    _genericClipProps(target.clipper?.runtimeType, target.clipBehavior);

List<PropSpec> _genericClipProps(Type? clipperType, Clip clipBehavior) => [
      if (clipperType != null)
        (
          icon: Icons.brush,
          subtitle: 'clipper',
          child: Text(clipperType.toString()),
        ),
      if (_clipBehaviorProp(clipBehavior) case final c?) c,
    ];

List<PropSpec> customPaintProps(RenderCustomPaint target) => [
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

List<PropSpec> flexProps(RenderFlex target) => [
      (
        icon: Icons.swap_horiz,
        subtitle: 'direction',
        child: Text(target.direction.name),
      ),
      (
        icon: Icons.space_bar,
        subtitle: 'main axis',
        child: Text(target.mainAxisAlignment.name),
      ),
      (
        icon: Icons.vertical_align_center,
        subtitle: 'cross axis',
        child: Text(target.crossAxisAlignment.name),
      ),
      if (target.mainAxisSize != MainAxisSize.max)
        (
          icon: Icons.compress,
          subtitle: 'main size',
          child: Text(target.mainAxisSize.name),
        ),
      if (target.verticalDirection != VerticalDirection.down)
        (
          icon: Icons.swap_vert,
          subtitle: 'vertical dir',
          child: Text(target.verticalDirection.name),
        ),
    ];

List<PropSpec> imageProps(RenderImage target) {
  final provider = resolveImageProvider(target);
  final rawImage = target.image;
  return [
    if (provider != null)
      (
        icon: Icons.image,
        subtitle: 'source',
        child: EllipsizedText(describeImageProvider(provider)),
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
      child: EllipsizedText(target.alignment.toString()),
    ),
    if (target.width != null)
      (
        icon: Icons.swap_horiz,
        subtitle: 'width',
        child: Text(_fmt(target.width!)),
      ),
    if (target.height != null)
      (
        icon: Icons.swap_vert,
        subtitle: 'height',
        child: Text(_fmt(target.height!)),
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
        child: ColorHexChip(target.color!),
      ),
  ];
}

List<PropSpec> opacityProps(RenderOpacity target) => [
      (
        icon: Icons.opacity,
        subtitle: 'opacity',
        child: Text(target.opacity.toStringAsFixed(2)),
      ),
    ];

List<PropSpec> animatedOpacityProps(RenderAnimatedOpacity target) => [
      (
        icon: Icons.opacity,
        subtitle: 'opacity',
        child: Text(target.opacity.value.toStringAsFixed(2)),
      ),
    ];

List<PropSpec> _physicalFinishProps({
  required Color color,
  required double elevation,
  required Color shadowColor,
}) =>
    [
      (icon: Icons.palette, subtitle: 'color', child: ColorHexChip(color)),
      if (elevation > 0)
        (
          icon: Icons.layers,
          subtitle: 'elevation',
          child: Text(_fmt(elevation)),
        ),
      (
        icon: Icons.blur_on,
        subtitle: 'shadow color',
        child: ColorHexChip(shadowColor),
      ),
    ];

List<PropSpec> physicalShapeProps(RenderPhysicalShape target) =>
    _physicalFinishProps(
      color: target.color,
      elevation: target.elevation,
      shadowColor: target.shadowColor,
    );

List<PropSpec> physicalModelProps(RenderPhysicalModel target) =>
    _physicalFinishProps(
      color: target.color,
      elevation: target.elevation,
      shadowColor: target.shadowColor,
    );

List<PropSpec> fittedBoxProps(RenderFittedBox target) => [
      (
        icon: Icons.fit_screen,
        subtitle: 'fit',
        child: Text(target.fit.name),
      ),
      if (target.alignment != Alignment.center)
        (
          icon: Icons.crop_free,
          subtitle: 'alignment',
          child: EllipsizedText(target.alignment.toString()),
        ),
    ];

List<PropSpec> aspectRatioProps(RenderAspectRatio target) => [
      (
        icon: Icons.aspect_ratio,
        subtitle: 'aspect ratio',
        child: Text(target.aspectRatio.toStringAsFixed(2)),
      ),
    ];

List<PropSpec> transformProps(RenderTransform target) {
  final matrix = Matrix4.identity();
  final child = target.child;
  if (child != null) target.applyPaintTransform(child, matrix);
  final m = matrix.storage;
  final tx = m[12];
  final ty = m[13];
  final scaleX = math.sqrt(m[0] * m[0] + m[1] * m[1]);
  final scaleY = math.sqrt(m[4] * m[4] + m[5] * m[5]);
  final rotationDeg = math.atan2(m[1], m[0]) * 180 / math.pi;
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
        child: EllipsizedText(_fmtOffset(target.origin!)),
      ),
    if (target.alignment != null)
      (
        icon: Icons.crop_free,
        subtitle: 'alignment',
        child: EllipsizedText(target.alignment.toString()),
      ),
    if (!target.transformHitTests)
      (
        icon: Icons.touch_app,
        subtitle: 'hit tests',
        child: const Text('untransformed'),
      ),
  ];
}

List<PropSpec> backdropFilterProps(RenderBackdropFilter target) => [
      (
        icon: Icons.blur_on,
        subtitle: 'filter',
        child: EllipsizedText(target.filter.toString()),
      ),
      if (target.blendMode != BlendMode.srcOver)
        (
          icon: Icons.layers,
          subtitle: 'blend mode',
          child: Text(target.blendMode.name),
        ),
    ];

List<PropSpec> editableProps(RenderEditable target) => [
      (
        icon: Icons.format_align_left,
        subtitle: 'text align',
        child: Text(target.textAlign.name),
      ),
      if (target.cursorColor != null)
        (
          icon: Icons.text_fields,
          subtitle: 'cursor',
          child: ColorHexChip(target.cursorColor!),
        ),
      if (target.selectionColor != null)
        (
          icon: Icons.select_all,
          subtitle: 'selection',
          child: ColorHexChip(target.selectionColor!),
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

/// Type-specific props for any [RenderBox]. Returns an empty list when the
/// type has no known extractor.
List<PropSpec> typeProps(RenderBox target) => [
      if (target is RenderStack) ...stackProps(target),
      if (target is RenderFlex) ...flexProps(target),
      if (target is RenderWrap) ...wrapProps(target),
      if (target is RenderImage) ...imageProps(target),
      if (target is RenderOpacity) ...opacityProps(target),
      if (target is RenderAnimatedOpacity) ...animatedOpacityProps(target),
      if (target is RenderPhysicalShape) ...physicalShapeProps(target),
      if (target is RenderPhysicalModel) ...physicalModelProps(target),
      if (target is RenderClipRRect) ...clipRRectProps(target),
      if (target is RenderClipRSuperellipse) ...clipRSuperellipseProps(target),
      if (target is RenderClipRect) ...clipRectProps(target),
      if (target is RenderClipOval) ...clipOvalProps(target),
      if (target is RenderClipPath) ...clipPathProps(target),
      if (target is RenderCustomPaint) ...customPaintProps(target),
      if (target is RenderFittedBox) ...fittedBoxProps(target),
      if (target is RenderAspectRatio) ...aspectRatioProps(target),
      if (target is RenderTransform) ...transformProps(target),
      if (target is RenderBackdropFilter) ...backdropFilterProps(target),
      if (target is RenderEditable) ...editableProps(target),
    ];

/// Whether [typeProps] produces something for a type. Used to filter
/// same-size ancestors in the parent chain when surfacing wrapper sections.
///
/// Narrower than [typeProps]'s full dispatcher: layout-shaping types
/// (Stack, Flex, Wrap, Image, Editable, Paragraph) never act as
/// same-size proxy wrappers around an inner target, so they are excluded.
bool hasTypeProps(RenderBox box) =>
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

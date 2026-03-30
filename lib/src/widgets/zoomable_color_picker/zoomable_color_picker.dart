import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:inspector/src/widgets/color_picker/color_scheme_inspector.dart';
import 'package:inspector/src/widgets/color_picker/utils.dart';
import 'package:inspector/src/widgets/components/information_box_widget.dart';

/// A combined overlay widget for zoomable color picker with color display
/// and zoom level indicators.
///
/// Features:
/// - Triple-layer circular border design (outer border, color ring, inner border)
/// - Zoomed image preview with custom painter
/// - Color hex code display at top
/// - Auto-hiding zoom level indicator
/// - Center color indicator dot
/// - Optional ColorScheme matching hint
class ZoomableColorPickerOverlay extends StatelessWidget {
  const ZoomableColorPickerOverlay({
    Key? key,
    required this.image,
    required this.imageOffset,
    required this.overlaySize,
    required this.zoomScale,
    required this.pixelRatio,
    required this.color,
    this.isColorSchemeHintEnabled = false,
    this.backgroundColor = const Color(0xFF1E1E1E),
  }) : super(key: key);

  final ui.Image image;
  final Offset imageOffset;
  final double overlaySize;
  final double zoomScale;
  final double pixelRatio;
  final Color color;
  final bool isColorSchemeHintEnabled;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = colorScheme.inverseSurface.withValues(alpha: 0.2);
    final textColor = getTextColorOnBackground(color);

    final String? match;
    if (isColorSchemeHintEnabled) {
      match = ColorSchemeInspector.identifyColorSchemeMatch(color, colorScheme);
    } else {
      match = null;
    }

    final colorString = '#${colorToHexString(color)}';

    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: overlaySize,
            child: DecoratedBox(
              // Outer semi-transparent border
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(
                    color: borderColor,
                    width: 20,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
              ),
              child: DecoratedBox(
                // Middle color ring showing picked color
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(
                      color: color,
                      width: 18,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                  ),
                ),
                child: DecoratedBox(
                  // Inner border with shadow
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(
                        color: borderColor,
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 12,
                        color: Colors.black12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      children: [
                        // Zoomed image content
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              isComplex: true,
                              willChange: true,
                              painter: _ZoomPainter(
                                image: image,
                                imageOffset: imageOffset,
                                overlaySize: overlaySize,
                                zoomScale: zoomScale,
                                pixelRatio: pixelRatio,
                                backgroundColor: backgroundColor,
                              ),
                            ),
                          ),
                        ),
                        // Color hex code display at top
                        Align(
                          alignment: const Alignment(0, -0.8),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: color,
                                border: Border.all(
                                  color: textColor.withValues(alpha: 0.2),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  colorString,
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Zoom level display at bottom
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ZoomLevelDisplay(zoomScale: zoomScale),
                          ),
                        ),
                        // Center color indicator dot
                        Center(
                          child: SizedBox.square(
                            dimension: 10,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: textColor.withValues(alpha: 0.4),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ColorScheme hint outside the circle at bottom
          if (match != null && match.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 32),
              child: SizedBox(
                width: overlaySize,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    border: Border.all(
                      color: textColor.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      match,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
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

/// Custom painter for rendering zoomed image content in the overlay.
///
/// Optimizes performance with proper shouldRepaint implementation
/// and efficient canvas operations.
/// Areas outside the image bounds are filled with [backgroundColor].
class _ZoomPainter extends CustomPainter {
  _ZoomPainter({
    required this.image,
    required this.imageOffset,
    required this.overlaySize,
    required this.zoomScale,
    required this.pixelRatio,
    required this.backgroundColor,
  })  : _backgroundPaint = Paint()..color = backgroundColor,
        _imagePaint = Paint()..filterQuality = FilterQuality.low;

  final ui.Image image;
  final Offset imageOffset;
  final double overlaySize;
  final double zoomScale;
  final double pixelRatio;
  final Color backgroundColor;

  final Paint _backgroundPaint;
  final Paint _imagePaint;

  @override
  void paint(Canvas canvas, Size size) {
    // Fill background for areas outside image bounds
    canvas.drawRect(Offset.zero & size, _backgroundPaint);

    final halfSize = overlaySize / 2.0;
    final scale = (1 / pixelRatio) * zoomScale;

    canvas
      ..clipRect(Offset.zero & size)
      ..translate(halfSize, halfSize)
      ..scale(scale)
      ..drawImage(image, -imageOffset, _imagePaint);
  }

  @override
  bool shouldRepaint(covariant _ZoomPainter oldDelegate) =>
      image != oldDelegate.image ||
      imageOffset != oldDelegate.imageOffset ||
      overlaySize != oldDelegate.overlaySize ||
      zoomScale != oldDelegate.zoomScale ||
      pixelRatio != oldDelegate.pixelRatio ||
      backgroundColor != oldDelegate.backgroundColor;
}

/// Auto-hiding zoom level display widget with smooth fade animation.
///
/// Shows zoom scale for 1 second after changes, then fades out.
/// Properly manages timer lifecycle and mounted state checks.
class _ZoomLevelDisplay extends StatefulWidget {
  const _ZoomLevelDisplay({
    required this.zoomScale,
  });

  final double zoomScale;

  @override
  State<_ZoomLevelDisplay> createState() => _ZoomLevelDisplayState();
}

class _ZoomLevelDisplayState extends State<_ZoomLevelDisplay> {
  static const _visibilityDuration = Duration(seconds: 1);
  static const _animationDuration = Duration(milliseconds: 200);

  Timer? _hideTimer;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _showZoomScale();
  }

  @override
  void didUpdateWidget(covariant _ZoomLevelDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.zoomScale != oldWidget.zoomScale) {
      _showZoomScale();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _showZoomScale() {
    if (!mounted) return;

    setState(() => _isVisible = true);

    _hideTimer?.cancel();
    _hideTimer = Timer(_visibilityDuration, () {
      if (mounted) {
        setState(() => _isVisible = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: _animationDuration,
      child: InformationBoxWidget(
        child: Text('x${widget.zoomScale}'),
      ),
    );
  }
}

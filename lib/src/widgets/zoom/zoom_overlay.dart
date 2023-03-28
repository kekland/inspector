import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:inspector/src/widgets/components/information_box_widget.dart';

class ZoomOverlayWidget extends StatelessWidget {
  const ZoomOverlayWidget({
    Key? key,
    required this.image,
    required this.imageOffset,
    required this.overlayOffset,
    required this.overlaySize,
    required this.zoomScale,
    required this.pixelRatio,
  }) : super(key: key);

  final ui.Image image;
  final Offset imageOffset;
  final Offset overlayOffset;
  final double overlaySize;
  final double zoomScale;
  final double pixelRatio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: overlaySize,
      height: overlaySize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.inverseSurface,
          width: 2.0,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12.0,
            color: Colors.black45,
            offset: Offset(0.0, 8.0),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              isComplex: true,
              willChange: true,
              painter: _ZoomPainter(
                image: image,
                imageOffset: imageOffset,
                overlayOffset: overlayOffset,
                overlaySize: overlaySize,
                zoomScale: zoomScale,
                pixelRatio: pixelRatio,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _ZoomLevelDisplay(zoomScale: zoomScale),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomPainter extends CustomPainter {
  _ZoomPainter({
    required this.image,
    required this.imageOffset,
    required this.overlayOffset,
    required this.overlaySize,
    required this.zoomScale,
    required this.pixelRatio,
  });

  final ui.Image image;
  final Offset imageOffset;
  final Offset overlayOffset;
  final double overlaySize;
  final double zoomScale;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final _imageOffset = -imageOffset;

    canvas.clipRect(Offset.zero & size);
    canvas.translate(overlaySize / 2.0, overlaySize / 2.0);
    canvas.scale((1 / pixelRatio) * zoomScale);
    canvas.drawImage(image, _imageOffset, Paint());
  }

  @override
  bool shouldRepaint(_ZoomPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.imageOffset != imageOffset ||
      oldDelegate.overlayOffset != overlayOffset ||
      oldDelegate.overlaySize != overlaySize ||
      oldDelegate.zoomScale != zoomScale;
}

class _ZoomLevelDisplay extends StatefulWidget {
  const _ZoomLevelDisplay({
    Key? key,
    required this.zoomScale,
  }) : super(key: key);

  final double zoomScale;

  @override
  State<_ZoomLevelDisplay> createState() => __ZoomLevelDisplayState();
}

class __ZoomLevelDisplayState extends State<_ZoomLevelDisplay> {
  Timer? _zoomHideTimer;
  bool _isZoomScaleVisible = false;

  @override
  void initState() {
    super.initState();
    _showZoomScale();
  }

  Future<void> _showZoomScale() async {
    setState(() => _isZoomScaleVisible = true);

    _zoomHideTimer?.cancel();

    _zoomHideTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isZoomScaleVisible = false);
    });
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
    _zoomHideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isZoomScaleVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: InformationBoxWidget(
        child: Text('x${widget.zoomScale.toString()}'),
      ),
    );
  }
}

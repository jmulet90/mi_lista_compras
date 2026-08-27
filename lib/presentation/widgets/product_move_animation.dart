import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'product_visuals.dart';

enum ProductMoveTarget { pantry, cart }

class MoveVisuals {
  static IconData icon(ProductMoveTarget target) =>
      target == ProductMoveTarget.pantry
          ? Icons.home_rounded
          : Icons.shopping_cart_rounded;

  static MaterialColor accent(ProductMoveTarget target) =>
      target == ProductMoveTarget.pantry ? Colors.green : Colors.red;
}

Widget buildMovePreview({String? imagePath, String? emoji}) {
  return ClipOval(
    child: ProductVisuals.circleChild(
      imagePath: imagePath,
      emoji: emoji,
      emojiSize: 28,
    ),
  );
}

Rect? rectOfContext(BuildContext? context) {
  if (context == null) return null;
  final renderObject = context.findRenderObject();
  if (renderObject is RenderBox && renderObject.attached && renderObject.hasSize) {
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }
  return null;
}

void playProductMove(
  BuildContext context, {
  Rect? fromRect,
  required ProductMoveTarget target,
  Widget? preview,
}) {
  OverlayEntry? entry;
  entry = OverlayEntry(
    builder: (_) => _ProductMoveOverlay(
      fromRect: fromRect,
      target: target,
      preview: preview,
      onCompleted: () => entry?.remove(),
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
}

class _ProductMoveOverlay extends StatefulWidget {
  const _ProductMoveOverlay({
    required this.fromRect,
    required this.target,
    required this.onCompleted,
    this.preview,
  });

  final Rect? fromRect;
  final ProductMoveTarget target;
  final Widget? preview;
  final VoidCallback onCompleted;

  @override
  State<_ProductMoveOverlay> createState() => _ProductMoveOverlayState();
}

class _ProductMoveOverlayState extends State<_ProductMoveOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onCompleted();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    const double targetDiameter = 68;
    final Offset targetTopLeft = Offset(
      (size.width - targetDiameter) / 2,
      kToolbarHeight + 20,
    );
    final Offset targetCenter =
        targetTopLeft + const Offset(targetDiameter / 2, targetDiameter / 2);

    Rect origin = widget.fromRect ??
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.6),
          width: 56,
          height: 56,
        );
    origin = Rect.fromCenter(
      center: Offset(
        origin.center.dx.clamp(40, size.width - 40),
        origin.center.dy.clamp(80, size.height - 120),
      ),
      width: origin.width.clamp(36, 90).toDouble(),
      height: origin.height.clamp(36, 90).toDouble(),
    );
    final Offset startCenter = origin.center;
    final Offset controlPoint =
        Offset((startCenter.dx + targetCenter.dx) / 2, math.min(startCenter.dy, targetCenter.dy) - 130);
    const double ghostSize = 46;

    final MaterialColor accent = MoveVisuals.accent(widget.target);

    return Material(
      type: MaterialType.transparency,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final double popT = CurvedAnimation(
              parent: _controller,
              curve: const Interval(0, 0.16, curve: Curves.easeOutBack),
            ).value;
            final double flyT = CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.06, 0.68, curve: Curves.easeInOutCubic),
            ).value;
            final double ghostFadeT = 1.0 -
                CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.52, 0.68),
                ).value;
            final double impactT = CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.62, 0.84),
            ).value;
            final double exitT = CurvedAnimation(
              parent: _controller,
              curve: const Interval(0.84, 1.0, curve: Curves.easeIn),
            ).value;

            final double inv = 1 - flyT;
            final Offset ghostCenter = startCenter * (inv * inv) +
                controlPoint * (2 * inv * flyT) +
                targetCenter * (flyT * flyT);
            final double ghostScale =
                lerpDouble(1.0, 0.35, flyT) ?? 1.0;
            final double targetScale =
                popT * (1 + 0.22 * math.sin(impactT * math.pi));

            return Opacity(
              opacity: (1 - exitT).clamp(0.0, 1.0),
              child: SizedBox.expand(
                child: Stack(
                  children: [
                    Positioned(
                      left: targetTopLeft.dx,
                      top: targetTopLeft.dy,
                      child: Transform.scale(
                        scale: targetScale,
                        child: Container(
                          width: targetDiameter,
                          height: targetDiameter,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(color: accent, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.35),
                                blurRadius: 18,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            MoveVisuals.icon(widget.target),
                            color: accent.shade700,
                            size: 34,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: ghostCenter.dx - ghostSize / 2,
                      top: ghostCenter.dy - ghostSize / 2,
                      child: Opacity(
                        opacity: ghostFadeT.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: ghostScale,
                          child: Container(
                            width: ghostSize,
                            height: ghostSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: accent.withValues(alpha: 0.6),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: widget.preview ?? buildMovePreview(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

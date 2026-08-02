import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// A curved scroll indicator that traces the round bezel of a smartwatch,
/// the way Wear OS / Galaxy Watch show scroll position as an arc along the
/// screen edge instead of a straight scrollbar (which reads poorly on a
/// circular display).
///
/// Wrap the scrollable content in a [Stack] and add this as the last child
/// so it overlays the right edge:
/// ```dart
/// Stack(
///   children: [
///     ListView(controller: controller, ...),
///     RoundedScrollIndicator(controller: controller),
///   ],
/// )
/// ```
class RoundedScrollIndicator extends StatefulWidget {
  final ScrollController controller;

  const RoundedScrollIndicator({super.key, required this.controller});

  @override
  State<RoundedScrollIndicator> createState() => _RoundedScrollIndicatorState();
}

class _RoundedScrollIndicatorState extends State<RoundedScrollIndicator> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() => setState(() {});

  @override
  Widget build(BuildContext context) {
    // hasContentDimensions must be checked before touching maxScrollExtent:
    // on the very first build (client attached, but the list hasn't
    // completed its first layout/measurement pass yet) that getter throws
    // a null-check error internally instead of returning a safe default.
    if (!widget.controller.hasClients ||
        !widget.controller.position.hasContentDimensions ||
        widget.controller.position.maxScrollExtent <= 0) {
      return const SizedBox.shrink();
    }

    final position = widget.controller.position;
    final progress = (position.pixels / position.maxScrollExtent).clamp(0.0, 1.0);
    // Fraction of the track the thumb itself covers, shrinking as there's
    // more content to scroll through (mirrors how a normal scrollbar thumb
    // shrinks), clamped so it stays visible even for very long lists.
    final viewportFraction =
        (position.viewportDimension / (position.viewportDimension + position.maxScrollExtent))
            .clamp(0.12, 1.0);

    // Positioned.fill (rather than an explicit Size with an infinite
    // dimension, which triggered "infinite height" layout assertions) lets
    // CustomPaint adopt the Stack's own bounded size; the painter itself
    // only draws a thin arc near the right edge regardless of that size.
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ArcPainter(progress: progress, thumbFraction: viewportFraction),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final double thumbFraction;

  _ArcPainter({required this.progress, required this.thumbFraction});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height / 2;
    final center = Offset(size.width - 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Total arc spans 120° along the right edge (60° above and below
    // center), matching the visible curvature of a round watch face.
    const totalSweep = math.pi * 2 / 3;
    const startAngle = -math.pi / 2 - totalSweep / 2;

    final trackPaint = Paint()
      ..color = AppTheme.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, startAngle, totalSweep, false, trackPaint);

    final thumbSweep = totalSweep * thumbFraction;
    final thumbStart = startAngle + (totalSweep - thumbSweep) * progress;
    final thumbPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, thumbStart, thumbSweep, false, thumbPaint);
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.thumbFraction != thumbFraction;
}

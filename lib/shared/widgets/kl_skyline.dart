import 'package:flutter/material.dart';

/// KL city skyline SVG recreated as a Flutter CustomPaint widget.
///
/// Matches the React KLSkylineSVG component with animated train and bus.
/// Features: Petronas Twin Towers, KL Tower, buildings, elevated LRT track.
class KLSkyline extends StatefulWidget {
  final double height;

  const KLSkyline({super.key, this.height = 150});

  @override
  State<KLSkyline> createState() => _KLSkylineState();
}

class _KLSkylineState extends State<KLSkyline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _KLSkylinePainter(
              trainProgress: _controller.value,
              busProgress: (_controller.value * 9 / 13) % 1.0,
            ),
          );
        },
      ),
    );
  }
}

class _KLSkylinePainter extends CustomPainter {
  final double trainProgress;
  final double busProgress;

  _KLSkylinePainter({
    required this.trainProgress,
    required this.busProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final scale = h / 150.0;

    canvas.save();
    canvas.scale(scale, scale);
    final white = Paint()..color = Colors.white;

    // Stars
    const stars = [38.0, 95.0, 150.0, 210.0, 280.0, 340.0, 380.0];
    for (var i = 0; i < stars.length; i++) {
      canvas.drawCircle(
        Offset(stars[i], 7.0 + (i % 3) * 6.0),
        1.3,
        white..color = Colors.white.withValues(alpha: 0.45),
      );
    }

    // Far BG buildings
    final bgPaint = Paint();
    canvas.drawRect(
        const Rect.fromLTWH(0, 88, 32, 62),
        bgPaint..color = Colors.white.withValues(alpha: 0.10));
    canvas.drawRect(
        const Rect.fromLTWH(28, 78, 24, 72),
        bgPaint..color = Colors.white.withValues(alpha: 0.12));
    canvas.drawRect(
        const Rect.fromLTWH(333, 86, 30, 64),
        bgPaint..color = Colors.white.withValues(alpha: 0.10));
    canvas.drawRect(
        const Rect.fromLTWH(358, 76, 26, 74),
        bgPaint..color = Colors.white.withValues(alpha: 0.12));
    canvas.drawRect(
        const Rect.fromLTWH(378, 90, 22, 60),
        bgPaint..color = Colors.white.withValues(alpha: 0.09));

    // KL Tower
    final towerPaint = Paint();
    canvas.drawLine(
      const Offset(92, 16),
      const Offset(92, 33),
      towerPaint
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeWidth = 2.5,
    );
    canvas.drawOval(
      const Rect.fromLTWH(78, 32, 28, 20),
      towerPaint..color = Colors.white.withValues(alpha: 0.45),
    );
    canvas.drawRect(
      const Rect.fromLTWH(89, 33, 6, 75),
      towerPaint..color = Colors.white.withValues(alpha: 0.45),
    );

    // Mid left buildings
    canvas.drawRect(const Rect.fromLTWH(55, 70, 22, 80),
        bgPaint..color = Colors.white.withValues(alpha: 0.18));
    canvas.drawRect(const Rect.fromLTWH(74, 60, 16, 90),
        bgPaint..color = Colors.white.withValues(alpha: 0.16));
    canvas.drawRect(const Rect.fromLTWH(110, 78, 18, 72),
        bgPaint..color = Colors.white.withValues(alpha: 0.14));
    canvas.drawRect(const Rect.fromLTWH(125, 68, 20, 82),
        bgPaint..color = Colors.white.withValues(alpha: 0.17));

    // Petronas Left Tower
    final twinPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.62);
    final leftTower = Path()
      ..moveTo(148, 44)
      ..lineTo(163, 16)
      ..lineTo(178, 44)
      ..close();
    canvas.drawPath(leftTower, twinPaint);
    canvas.drawRect(const Rect.fromLTWH(148, 44, 30, 106), twinPaint);
    canvas.drawRect(
        const Rect.fromLTWH(162, 9, 2, 8), twinPaint);
    canvas.drawLine(
      const Offset(163, 5),
      const Offset(163, 9),
      twinPaint..strokeWidth = 2.2,
    );
    canvas.drawRect(
      const Rect.fromLTWH(150, 58, 26, 2),
      bgPaint..color = Colors.white.withValues(alpha: 0.28),
    );
    canvas.drawRect(
      const Rect.fromLTWH(150, 78, 26, 2),
      bgPaint..color = Colors.white.withValues(alpha: 0.28),
    );
    canvas.drawRect(
      const Rect.fromLTWH(150, 98, 26, 2),
      bgPaint..color = Colors.white.withValues(alpha: 0.28),
    );

    // Petronas Right Tower
    final rightTower = Path()
      ..moveTo(184, 44)
      ..lineTo(199, 16)
      ..lineTo(214, 44)
      ..close();
    canvas.drawPath(rightTower, twinPaint);
    canvas.drawRect(const Rect.fromLTWH(184, 44, 30, 106), twinPaint);
    canvas.drawRect(
        const Rect.fromLTWH(198, 9, 2, 8), twinPaint);
    canvas.drawLine(
      const Offset(199, 5),
      const Offset(199, 9),
      twinPaint..strokeWidth = 2.2,
    );
    canvas.drawRect(
      const Rect.fromLTWH(186, 58, 26, 2),
      bgPaint..color = Colors.white.withValues(alpha: 0.28),
    );
    canvas.drawRect(
      const Rect.fromLTWH(186, 78, 26, 2),
      bgPaint..color = Colors.white.withValues(alpha: 0.28),
    );
    canvas.drawRect(
      const Rect.fromLTWH(186, 98, 26, 2),
      bgPaint..color = Colors.white.withValues(alpha: 0.28),
    );

    // Sky Bridge
    canvas.drawRect(
      const Rect.fromLTWH(148, 68, 66, 10),
      bgPaint..color = Colors.white.withValues(alpha: 0.68),
    );
    canvas.drawRect(
      const Rect.fromLTWH(152, 66, 5, 12),
      bgPaint..color = Colors.white.withValues(alpha: 0.52),
    );
    canvas.drawRect(
      const Rect.fromLTWH(205, 66, 5, 12),
      bgPaint..color = Colors.white.withValues(alpha: 0.52),
    );

    // Concourse
    canvas.drawRect(
      const Rect.fromLTWH(128, 88, 22, 62),
      bgPaint..color = Colors.white.withValues(alpha: 0.28),
    );
    canvas.drawRect(
      const Rect.fromLTWH(212, 88, 22, 62),
      bgPaint..color = Colors.white.withValues(alpha: 0.28),
    );

    // Mid right buildings
    canvas.drawRect(const Rect.fromLTWH(244, 66, 20, 84),
        bgPaint..color = Colors.white.withValues(alpha: 0.18));
    canvas.drawRect(const Rect.fromLTWH(260, 54, 16, 96),
        bgPaint..color = Colors.white.withValues(alpha: 0.16));
    canvas.drawRect(const Rect.fromLTWH(274, 72, 24, 78),
        bgPaint..color = Colors.white.withValues(alpha: 0.14));
    canvas.drawRect(const Rect.fromLTWH(294, 62, 20, 88),
        bgPaint..color = Colors.white.withValues(alpha: 0.16));

    // Elevated LRT Track
    canvas.drawRect(
      const Rect.fromLTWH(0, 124, 400, 4),
      bgPaint..color = Colors.white.withValues(alpha: 0.52),
    );
    final pillars = [22.0, 75.0, 130.0, 200.0, 260.0, 315.0, 368.0];
    for (final x in pillars) {
      canvas.drawRect(
        Rect.fromLTWH(x, 124.0, 3.0, 20.0),
        bgPaint..color = Colors.white.withValues(alpha: 0.28),
      );
    }

    // Animated LRT Train
    final trainX = -80.0 + trainProgress * 510.0;
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(0, 0, 400, 150));
    canvas.translate(trainX, 0);

    final trainPaint = Paint()..color = const Color(0xFFC41230);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 111, 76, 15),
        const Radius.circular(4),
      ),
      trainPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 111, 76, 4),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0x59FF4466),
    );
    final windows = [5.0, 19.0, 33.0, 47.0, 61.0];
    for (final wx in windows) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(wx, 114.0, 11.0, 8.0),
          const Radius.circular(1.5),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.92),
      );
    }
    canvas.drawCircle(
      const Offset(4, 118),
      2.5,
      Paint()..color = const Color(0xFFFBBF24),
    );
    canvas.restore();

    // Animated Bus (opposite direction)
    final busX = 430.0 + (-510.0) * busProgress; // right to left
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(0, 0, 400, 150));
    canvas.translate(busX, 0);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 113, 46, 12),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xE01B4FD8),
    );
    final busWindows = [3.0, 13.0, 23.0, 33.0];
    for (final wx in busWindows) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(wx, 116.0, 8.0, 6.0),
          const Radius.circular(1),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.88),
      );
    }
    canvas.drawCircle(
      const Offset(3, 122),
      2,
      Paint()..color = const Color(0x9960A5FA),
    );
    canvas.restore();

    // Restore the initial scale transform
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KLSkylinePainter oldDelegate) {
    return trainProgress != oldDelegate.trainProgress ||
        busProgress != oldDelegate.busProgress;
  }
}

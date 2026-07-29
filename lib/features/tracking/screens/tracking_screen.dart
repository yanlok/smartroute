import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

class TrackingScreen extends StatefulWidget {
  final VoidCallback onBack;

  const TrackingScreen({super.key, required this.onBack});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 28;
  Timer? _timer;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _timer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      setState(() {
        _progress = _progress >= 96 ? 18 : _progress + 0.6;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  int get curIdx {
    final stations = kjLineStops.length - 1;
    return min((_progress / 100 * stations).floor(), stations);
  }

  int get eta => max(0, ((100 - _progress) / 100 * 18).round());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header ──
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: AppShadows.header,
          ),
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).padding.top,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 12, 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBack,
                      icon:
                          const Icon(Icons.chevron_left_rounded, size: 20),
                      color: AppColors.textSecondary,
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('Live Tracking',
                          style: AppTypography.titleMedium),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.greenLiveBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.greenLiveBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + _pulseController.value * 0.45,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.greenLive,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          Text('LIVE',
                              style: AppTypography.captionBold),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Body ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // SVG Map
                Container(
                  height: 196,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: AppShadows.card,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: CustomPaint(
                      size: const Size(390, 196),
                      painter: _TrackingMapPainter(
                        progress: _progress,
                        pulseValue: _pulseController.value,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Vehicle card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0x12009FE3),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(Icons.train_rounded,
                                color: Color(0xFF009FE3), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _KJBadge(),
                                    SizedBox(width: 8),
                                    Text('Train KJL-2847',
                                        style: AppTypography.bodySmall),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Text('Platform 2 · Towards Putra Heights',
                                    style: AppTypography.labelMedium),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('ETA',
                                  style: AppTypography.captionMedium),
                              Text('${eta}m',
                                  style: AppTypography.monoLarge.copyWith(color: AppColors.primary)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _progress / 100,
                          backgroundColor: AppColors.mutedBg,
                          color: const Color(0xFF009FE3),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Asia Jaya',
                              style: AppTypography.captionMedium),
                          Text('${_progress.round()}% complete',
                              style: AppTypography.captionBold.copyWith(
                                color: const Color(0xFF009FE3),
                              )),
                          Text('KL Sentral',
                              style: AppTypography.captionMedium),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Upcoming stops
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('UPCOMING STOPS',
                      style: AppTypography.captionBlack),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    children: List.generate(
                      min(kjLineStops.length - curIdx, 4),
                      (i) {
                        final name = kjLineStops[curIdx + i];
                        final isCurrent = i == 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: i < min(kjLineStops.length - curIdx, 4) - 1
                              ? const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                        color: Color(0xFFF9FAFB)),
                                  ),
                                )
                              : null,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppColors.primary
                                      : const Color(0x40009FE3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(name,
                                        style: isCurrent
                                            ? AppTypography.bodyLarge
                                            : AppTypography.labelMedium),
                                    if (isCurrent) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryLight,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text('Current',
                                            style: AppTypography.captionBold),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (!isCurrent)
                                Text('+${i * 3} min',
                                    style: AppTypography.labelSmallBold.copyWith(
                                      color: AppColors.iconGray,
                                    )),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _KJBadge extends StatelessWidget {
  const _KJBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF009FE3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('KJ Line',
          style: AppTypography.captionBold),
    );
  }
}

const kjLineStops = [
  'Asia Jaya',
  'Taman Paramount',
  'Taman Jaya',
  'Universiti',
  'Bangsar',
  'KL Sentral',
];

class _TrackingMapPainter extends CustomPainter {
  final double progress;
  final double pulseValue;

  _TrackingMapPainter({required this.progress, required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFFF8FAFC),
    );

    // Grid
    final gridPaint = Paint()
      ..color = const Color(0xFFE8EBF0)
      ..strokeWidth = 0.6;
    for (double x = 0; x < w; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Roads
    final roadPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(0, 155), Offset(w, 155), roadPaint..strokeWidth = 10);
    canvas.drawLine(Offset(0, 50), Offset(w, 50), roadPaint..strokeWidth = 7);
    canvas.drawLine(
        Offset(w / 2, 0), Offset(w / 2, h), roadPaint..strokeWidth = 6);

    // Scale positions to size
    final scaleX = w / 390;
    final scaleY = h / 196;

    // LRT track
    final trackPaint = Paint()
      ..color = const Color(0xFF009FE3)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final trackPath = Path()
      ..moveTo(28 * scaleX, 120 * scaleY)
      ..quadraticBezierTo(58 * scaleX, 112 * scaleY, 90 * scaleX, 100 * scaleY)
      ..quadraticBezierTo(120 * scaleX, 88 * scaleY, 155 * scaleX, 88 * scaleY)
      ..quadraticBezierTo(190 * scaleX, 88 * scaleY, 220 * scaleX, 84 * scaleY)
      ..quadraticBezierTo(255 * scaleX, 80 * scaleY, 290 * scaleX, 90 * scaleY)
      ..quadraticBezierTo(
          322 * scaleX, 100 * scaleY, 355 * scaleX, 110 * scaleY);
    canvas.drawPath(trackPath, trackPaint);

    // Station positions
    final stationPositions = [
      Offset(28, 120),
      Offset(90, 100),
      Offset(155, 88),
      Offset(220, 84),
      Offset(290, 90),
      Offset(355, 110),
    ];

    final curIdx = min((progress / 100 * 5).floor(), 5);

    for (var i = 0; i < stationPositions.length; i++) {
      final pos = stationPositions[i];
      final sx = pos.dx * scaleX;
      final sy = pos.dy * scaleY;

      // Ping ring at current station
      if (i == curIdx) {
        final pingRadius = 11 + pulseValue * 8;
        canvas.drawCircle(
          Offset(sx, sy),
          pingRadius,
          Paint()
            ..color = const Color(0xFF009FE3)
                .withValues(alpha: 0.18 * (1 - pulseValue)),
        );
      }

      // Station dot
      canvas.drawCircle(
        Offset(sx, sy),
        (i == 0 || i == 5) ? 6.0 : 4.5,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        Offset(sx, sy),
        (i == 0 || i == 5) ? 6.0 : 4.5,
        Paint()
          ..color = i == curIdx ? AppColors.primary : const Color(0xFF009FE3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == curIdx ? 2.5 : 2,
      );
    }

    // Train position (interpolated along the track)
    final trainX = (28 + (progress / 100) * (355 - 28)) * scaleX;
    final trainY = (120 + (progress / 100) * (110 - 120)) * scaleY;

    canvas.save();
    canvas.translate(trainX, trainY);
    // Train body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-20, -11, 40, 16),
        const Radius.circular(4),
      ),
      Paint()..color = AppColors.primary,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-20, -11, 40, 5),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0x66FF4466),
    );
    // Windows
    for (final wx in [-16.0, -5.0, 6.0, 16.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(wx, -8.0, 9.0, 8.0),
          const Radius.circular(1.5),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.92),
      );
    }
    // Headlight
    canvas.drawCircle(
      const Offset(-18, -3),
      2,
      Paint()..color = AppColors.yellowBadge,
    );
    canvas.restore();

    // Destination marker
    final destX = 355 * scaleX;
    final destY = 110 * scaleY;
    canvas.drawCircle(
      Offset(destX, destY),
      8,
      Paint()..color = AppColors.secondary.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      Offset(destX, destY),
      5,
      Paint()..color = AppColors.secondary,
    );

    // Labels
    final labelStyle = TextStyle(
      fontSize: 8 * scaleX,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF64748B),
    );
    final textPainter = TextPainter(
      text: TextSpan(text: 'Asia Jaya', style: labelStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(28 * scaleX - textPainter.width / 2, 135 * scaleY));

    final destLabel = TextPainter(
      text: TextSpan(
        text: 'KL Sentral',
        style: labelStyle.copyWith(color: AppColors.secondary),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    destLabel.layout();
    destLabel.paint(
        canvas, Offset(355 * scaleX - destLabel.width / 2, 125 * scaleY));
  }

  @override
  bool shouldRepaint(covariant _TrackingMapPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        pulseValue != oldDelegate.pulseValue;
  }
}

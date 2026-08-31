import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/models/live_vehicle.dart';
import '../../domain/models/tracking_station.dart';
import '../../domain/models/transit_direction.dart';

/// Renders the live tracking map for a single line.
///
/// The painter draws:
///   * a faint background grid and road lines,
///   * the line track (a straight horizontal stroke),
///   * station dots (with the current vehicle's station highlighted
///     and a pulsing ring),
///   * the moving vehicle as a small rounded rectangle with
///     windows and a headlight,
///   * a destination marker at the terminal,
///   * origin and destination labels at the bottom.
///
/// All geometry is derived from the supplied [Size] (per
/// `docs/design.md` §7), and all colours come from [AppColors]
/// (per `docs/design.md` §3).
class LiveMapPainter extends CustomPainter {
  /// Ordered list of stations along the line. The painter uses
  /// the index of each station along [stations] (clamped) to
  /// position the vehicle and the station dots.
  final List<TrackingStation> stations;

  /// The currently selected vehicle. `null` means no vehicle has
  /// been emitted yet (initial loading).
  final LiveVehicle? vehicle;

  /// Pulse value in `[0.0, 1.0]` used to animate the current
  /// station's ping ring. Driven by the parent widget's
  /// `AnimationController`.
  final double pulseValue;

  /// The line's brand colour. Resolved from
  /// [TransitLine.colorToken] by the parent.
  final Color lineColor;

  LiveMapPainter({
    required this.stations,
    required this.vehicle,
    required this.pulseValue,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Background ─────────────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = AppColors.mutedBg,
    );

    // ── Grid (subtle) ─────────────────────────────────────────────────
    final gridPaint = Paint()
      ..color = AppColors.borderLight
      ..strokeWidth = 0.6;
    for (double x = 0; x < w; x += AppSpacing.xxl) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += AppSpacing.xxl) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // ── Roads (decorative) ────────────────────────────────────────────
    final roadPaint = Paint()
      ..color = AppColors.border
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, h * 0.79),
      Offset(w, h * 0.79),
      roadPaint..strokeWidth = 10,
    );
    canvas.drawLine(
      Offset(0, h * 0.25),
      Offset(w, h * 0.25),
      roadPaint..strokeWidth = 7,
    );
    canvas.drawLine(
      Offset(w * 0.5, 0),
      Offset(w * 0.5, h),
      roadPaint..strokeWidth = 6,
    );

    if (stations.isEmpty) {
      return;
    }

    // ── Track ─────────────────────────────────────────────────────────
    final trackPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final trackY = h * 0.55;
    final leftX = w * 0.07;
    final rightX = w * 0.91;

    final trackPath = Path()
      ..moveTo(leftX, trackY)
      ..quadraticBezierTo(w * 0.25, trackY - 8, w * 0.5, trackY)
      ..quadraticBezierTo(w * 0.75, trackY + 8, rightX, trackY);
    canvas.drawPath(trackPath, trackPaint);

    // ── Station dots ──────────────────────────────────────────────────
    final n = stations.length;
    final currentStationIdx = vehicle == null
        ? -1
        : _stationIndexForPosition(vehicle!.positionFraction, n);

    for (var i = 0; i < n; i++) {
      final x = _interp(leftX, rightX, i / (n - 1));
      final isTerminal = i == 0 || i == n - 1;
      final isCurrent = i == currentStationIdx;

      // Ping ring at current station.
      if (isCurrent) {
        final pingRadius = 11 + pulseValue * 8;
        canvas.drawCircle(
          Offset(x, trackY),
          pingRadius,
          Paint()..color = lineColor.withValues(alpha: 0.18 * (1 - pulseValue)),
        );
      }

      // White halo, then coloured ring.
      final dotRadius = isTerminal
          ? AppSpacing.dotMedium
          : AppSpacing.stationDotRadius;
      canvas.drawCircle(
        Offset(x, trackY),
        dotRadius,
        Paint()..color = AppColors.surface,
      );
      canvas.drawCircle(
        Offset(x, trackY),
        dotRadius,
        Paint()
          ..color = isCurrent ? AppColors.primary : lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = isCurrent ? 2.5 : 2,
      );
    }

    // ── Vehicle (train) ──────────────────────────────────────────────
    if (vehicle != null) {
      final pos = vehicle!.positionFraction.clamp(0.0, 1.0);
      final x = _interp(leftX, rightX, pos);
      final y = trackY;
      _drawTrain(canvas, Offset(x, y));
    }

    // ── Destination marker ───────────────────────────────────────────
    canvas.drawCircle(
      Offset(rightX, trackY),
      8,
      Paint()..color = AppColors.secondary.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      Offset(rightX, trackY),
      5,
      Paint()..color = AppColors.secondary,
    );

    // ── Labels ────────────────────────────────────────────────────────
    _drawLabel(
      canvas,
      text: stations.first.name,
      x: leftX,
      y: trackY + 18,
      w: w,
      color: AppColors.textSecondary,
    );
    _drawLabel(
      canvas,
      text: stations.last.name,
      x: rightX,
      y: trackY + 18,
      w: w,
      color: AppColors.secondary,
      alignRight: true,
    );
  }

  void _drawTrain(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    final direction = vehicle?.direction ?? TransitDirection.forward;
    // Train body (faces direction of travel).
    final flip = direction == TransitDirection.reverse ? -1.0 : 1.0;

    canvas.save();
    canvas.scale(flip, 1.0);

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-20, -11, 40, 16),
        const Radius.circular(AppRadius.sm),
      ),
      Paint()..color = AppColors.primary,
    );
    // Top accent
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-20, -11, 40, 5),
        const Radius.circular(2),
      ),
      Paint()..color = AppColors.primaryLight,
    );
    // Windows
    for (final wx in const [-16.0, -5.0, 6.0, 16.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(wx, -8.0, 9.0, 8.0),
          const Radius.circular(1.5),
        ),
        Paint()..color = AppColors.surface.withValues(alpha: 0.92),
      );
    }
    // Headlight
    canvas.drawCircle(
      const Offset(-18, -3),
      2,
      Paint()..color = AppColors.yellowBadge,
    );
    canvas.restore();

    canvas.restore();
  }

  void _drawLabel(
    Canvas canvas, {
    required String text,
    required double x,
    required double y,
    required double w,
    required Color color,
    bool alignRight = false,
  }) {
    final style = TextStyle(
      fontSize: 8,
      fontWeight: FontWeight.w700,
      color: color,
    );
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );
    painter.layout(maxWidth: w * 0.3);
    final dx = alignRight ? x - painter.width : x - painter.width / 2;
    painter.paint(canvas, Offset(dx, y));
  }

  /// Maps a `positionFraction` in `[0,1]` to the nearest station
  /// index along the line.
  int _stationIndexForPosition(double fraction, int stationCount) {
    if (stationCount <= 1) return 0;
    final raw = (fraction * (stationCount - 1)).round();
    return raw.clamp(0, stationCount - 1);
  }

  /// Linear interpolation between [a] and [b] by [t] in `[0,1]`.
  double _interp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  @override
  bool shouldRepaint(covariant LiveMapPainter old) {
    return old.vehicle?.vehicleId != vehicle?.vehicleId ||
        old.vehicle?.positionFraction != vehicle?.positionFraction ||
        old.vehicle?.direction != vehicle?.direction ||
        old.pulseValue != pulseValue ||
        old.lineColor != lineColor ||
        old.stations.length != stations.length;
  }
}

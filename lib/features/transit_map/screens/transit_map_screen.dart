import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/mock_data.dart';
import 'package:flutter/material.dart';

class TransitMapScreen extends StatefulWidget {
  final VoidCallback onBack;

  const TransitMapScreen({super.key, required this.onBack});

  @override
  State<TransitMapScreen> createState() => _TransitMapScreenState();
}

class _TransitMapScreenState extends State<TransitMapScreen> {
  String? _selectedLine;
  String? _selectedStation;

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
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      color: AppColors.textSecondary,
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('Transit Map',
                          style: AppTypography.titleMedium),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.search_rounded, size: 16),
                      color: AppColors.iconDark,
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Line filters
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null, AppColors.primary),
                      const SizedBox(width: 8),
                      ...transportLines.map((l) {
                        final color = Color(int.parse(
                            '0xFF${l.color.replaceFirst('#', '')}'));
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(
                              l.shortName, l.id, color),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Map ──
        Expanded(
          child: Container(
            color: Colors.white,
            child: InteractiveViewer(
              constrained: false,
              minScale: 0.8,
              maxScale: 3.0,
              child: SizedBox(
                width: 390,
                height: 490,
                child: CustomPaint(
                  size: const Size(390, 490),
                  painter: _TransitMapPainter(
                    selectedLine: _selectedLine,
                    onStationTap: (name) =>
                        setState(() => _selectedStation = name),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Station Info Panel ──
        if (_selectedStation != null)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: AppShadows.panel,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedStation!,
                            style: AppTypography.bodyLarge),
                        const SizedBox(height: 2),
                        Text('Interchange · Open 06:00–24:00',
                            style: AppTypography.labelMedium),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedStation = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.mutedBg,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.mutedForeground),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: AppColors.gradientPrimary),
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: Center(
                            child: Text('Get Directions',
                                style: AppTypography.bodySmall),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.mutedBg,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: Center(
                            child: Text('Station Info',
                                style: AppTypography.bodySmall),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String? id, Color color) {
    final active = _selectedLine == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLine = _selectedLine == id ? null : id;
          _selectedStation = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color : AppColors.mutedBg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: active
              ? [BoxShadow(color: color.withValues(alpha: 0.27), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(label,
            style: AppTypography.captionBold.copyWith(
              color: active ? Colors.white : AppColors.mutedForeground,
            )),
          ),
        );
  }
}

class _TransitMapPainter extends CustomPainter {
  final String? selectedLine;
  final void Function(String) onStationTap;

  _TransitMapPainter({required this.selectedLine, required this.onStationTap});

  double _lineOpacity(String? lineId) {
    if (selectedLine == null || selectedLine == lineId) return 1.0;
    return 0.12;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFFF8FAFC));

    // Grid
    final gridPaint = Paint()
      ..color = const Color(0xFFECEEF2)
      ..strokeWidth = 0.5;
    for (double y = 50; y < 490; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(390, y), gridPaint);
    }
    for (double x = 65; x < 390; x += 65) {
      canvas.drawLine(Offset(x, 0), Offset(x, 490), gridPaint);
    }

    final kjPaint = Paint()
      ..color = const Color(0xFF009FE3)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final spPaint = Paint()
      ..color = const Color(0xFF00A550)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final mkPaint = Paint()
      ..color = const Color(0xFF003087)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final mpPaint = Paint()
      ..color = const Color(0xFF8B0000)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Kelana Jaya Line
    kjPaint.color = kjPaint.color.withValues(alpha: _lineOpacity('kjl'));
    final kjPath = Path()
      ..moveTo(28, 115)
      ..lineTo(85, 115)
      ..lineTo(125, 90)
      ..lineTo(185, 72)
      ..lineTo(245, 62)
      ..lineTo(295, 68)
      ..lineTo(338, 98)
      ..lineTo(358, 142);
    canvas.drawPath(kjPath, kjPaint);

    // Sri Petaling Line
    spPaint.color = spPaint.color.withValues(alpha: _lineOpacity('spl'));
    final spPath = Path()
      ..moveTo(38, 55)
      ..lineTo(88, 75)
      ..lineTo(125, 90)
      ..lineTo(165, 125)
      ..lineTo(198, 175)
      ..lineTo(210, 235)
      ..lineTo(215, 295)
      ..lineTo(210, 360);
    canvas.drawPath(spPath, spPaint);

    // MRT Kajang
    mkPaint.color = mkPaint.color.withValues(alpha: _lineOpacity('mrt-k'));
    final mkPath = Path()
      ..moveTo(45, 200)
      ..lineTo(98, 210)
      ..lineTo(148, 218)
      ..lineTo(200, 228)
      ..lineTo(248, 238)
      ..lineTo(295, 248)
      ..lineTo(338, 268)
      ..lineTo(358, 308)
      ..lineTo(354, 360);
    canvas.drawPath(mkPath, mkPaint);

    // MRT Putrajaya
    mpPaint.color = mpPaint.color.withValues(alpha: _lineOpacity('mrt-p'));
    final mpPath = Path()
      ..moveTo(55, 385)
      ..lineTo(98, 345)
      ..lineTo(138, 305)
      ..lineTo(178, 270)
      ..lineTo(218, 258)
      ..lineTo(248, 258)
      ..lineTo(285, 268)
      ..lineTo(318, 290);
    canvas.drawPath(mpPath, mpPaint);

    // KL Monorail (dashed)
    final monoPaint = Paint()
      ..color = const Color(0xFF7C3AED).withValues(alpha: _lineOpacity('mono'))
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    const dashWidth = 9.0;
    const dashSpace = 4.0;
    final monoPath = Path()
      ..moveTo(338, 98)
      ..lineTo(328, 130)
      ..lineTo(308, 152)
      ..lineTo(288, 168)
      ..lineTo(268, 182)
      ..lineTo(248, 198)
      ..lineTo(238, 222)
      ..lineTo(232, 248)
      ..lineTo(238, 278)
      ..lineTo(242, 300);
    _drawDashedPath(canvas, monoPath, monoPaint, dashWidth, dashSpace);

    // Draw station dots
    _drawStations(canvas, _kjStations, const Color(0xFF009FE3),
        _lineOpacity('kjl'), 5.0);
    _drawStations(canvas, _spStations, const Color(0xFF00A550),
        _lineOpacity('spl'), 5.0);
    _drawStations(canvas, _mkStations, const Color(0xFF003087),
        _lineOpacity('mrt-k'), 5.0);
    _drawStations(canvas, _mpStations, const Color(0xFF8B0000),
        _lineOpacity('mrt-p'), 4.5);
    _drawStations(canvas, _moStations, const Color(0xFF7C3AED),
        _lineOpacity('mono'), 4.0);

    // Interchange stations (red double-ring)
    for (final ic in _interchanges) {
      canvas.drawCircle(ic.offset, 10,
          Paint()..color = Colors.white);
      canvas.drawCircle(ic.offset, 10,
          Paint()
            ..color = AppColors.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
      canvas.drawCircle(ic.offset, 5,
          Paint()..color = AppColors.primary);
    }

    // Legend
    final legendY = 426.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(8, legendY, 374, 58),
          const Radius.circular(12)),
      Paint()..color = Colors.white.withValues(alpha: 0.97),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(8, legendY, 374, 58),
          const Radius.circular(12)),
      Paint()
        ..color = const Color(0xFFE8EBF0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Draw labels and legend items
    final labelStyle = TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0369A1));
    _drawLabel(canvas, 'KLCC', const Offset(185, 60), labelStyle);
    _drawLabel(canvas, 'Masjid Jamek', const Offset(245, 50), labelStyle);
    _drawLabel(canvas, 'Pasar Seni', const Offset(295, 56), labelStyle);

    final spLabel = labelStyle.copyWith(color: const Color(0xFF166534));
    _drawLabel(canvas, 'Titiwangsa', const Offset(155, 115), spLabel,
        align: TextAlign.right);
    _drawLabel(canvas, 'Hang Tuah', const Offset(188, 165), spLabel,
        align: TextAlign.right);

    final mkLabel = labelStyle.copyWith(color: const Color(0xFF1E3A5F));
    _drawLabel(canvas, 'Merdeka', const Offset(248, 252), mkLabel);
    _drawLabel(canvas, 'Bukit Bintang', const Offset(295, 262), mkLabel);

    final icLabel = TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        color: AppColors.primary);
    _drawLabel(canvas, 'KL Sentral', const Offset(338, 116), icLabel);
    _drawLabel(canvas, 'Masjid Jamek', const Offset(245, 80), icLabel);
    _drawLabel(canvas, 'Titiwangsa', const Offset(165, 143), icLabel);
  }

  void _drawStations(Canvas canvas, List<_Station> stations, Color color,
      double opacity, double radius) {
    for (final s in stations) {
      canvas.drawCircle(s.offset, radius, Paint()..color = Colors.white);
      canvas.drawCircle(
        s.offset,
        radius,
        Paint()
          ..color = color.withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  void _drawLabel(Canvas canvas, String text, Offset position,
      TextStyle style,
      {TextAlign align = TextAlign.center}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
    );
    tp.layout();
    final x = align == TextAlign.right
        ? position.dx - tp.width
        : position.dx - tp.width / 2;
    tp.paint(canvas, Offset(x, position.dy));
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint,
      double dashWidth, double dashSpace) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0, metric.length).toDouble();
        final extractPath =
            metric.extractPath(distance, end);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TransitMapPainter oldDelegate) {
    return selectedLine != oldDelegate.selectedLine;
  }
}

class _Station {
  final Offset offset;
  final String name;
  const _Station(this.offset, this.name);
}

const _kjStations = [
  _Station(Offset(28, 115), 'Gombak'),
  _Station(Offset(85, 115), 'Wangsa Maju'),
  _Station(Offset(125, 90), 'Sri Rampai'),
  _Station(Offset(185, 72), 'KLCC'),
  _Station(Offset(217, 63), 'Dang Wangi'),
  _Station(Offset(245, 62), 'Masjid Jamek'),
  _Station(Offset(295, 68), 'Pasar Seni'),
  _Station(Offset(338, 98), 'KL Sentral'),
  _Station(Offset(358, 142), 'Putra Heights'),
];

const _spStations = [
  _Station(Offset(38, 55), 'Sentul Timur'),
  _Station(Offset(88, 75), 'Sentul'),
  _Station(Offset(165, 125), 'Titiwangsa'),
  _Station(Offset(198, 175), 'Hang Tuah'),
  _Station(Offset(210, 235), 'Chan Sow Lin'),
  _Station(Offset(215, 295), 'Sri Petaling'),
  _Station(Offset(210, 360), 'Bukit Jalil'),
];

const _mkStations = [
  _Station(Offset(45, 200), 'Kwasa Damansara'),
  _Station(Offset(148, 218), 'Semantan'),
  _Station(Offset(248, 238), 'Merdeka'),
  _Station(Offset(295, 248), 'Bukit Bintang'),
  _Station(Offset(354, 360), 'Kajang'),
];

const _mpStations = [
  _Station(Offset(55, 385), 'Putrajaya Sentral'),
  _Station(Offset(178, 270), 'Muzium Negara'),
  _Station(Offset(218, 258), 'Pasar Rakyat'),
  _Station(Offset(285, 268), 'Hospital KL'),
];

const _moStations = [
  _Station(Offset(338, 98), 'KL Sentral'),
  _Station(Offset(288, 168), 'Imbi'),
  _Station(Offset(265, 186), 'BB Monorail'),
  _Station(Offset(242, 300), 'Titiwangsa'),
];

final _interchanges = [
  _Interchange(const Offset(245, 62), 'Masjid Jamek'),
  _Interchange(const Offset(338, 98), 'KL Sentral'),
  _Interchange(const Offset(165, 125), 'Titiwangsa'),
  _Interchange(const Offset(295, 248), 'Bukit Bintang'),
];

class _Interchange {
  final Offset offset;
  final String label;
  const _Interchange(this.offset, this.label);
}

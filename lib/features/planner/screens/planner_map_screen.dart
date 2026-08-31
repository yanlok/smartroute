import 'package:flutter/material.dart';

import '../../../core/constants/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';

class PlannerMapScreen extends StatefulWidget {
  final String from;
  final String to;
  final VoidCallback onBack;
  final void Function(String from, String to) onChangeJourney;
  final VoidCallback onFindRoutes;

  const PlannerMapScreen({
    super.key,
    required this.from,
    required this.to,
    required this.onBack,
    required this.onChangeJourney,
    required this.onFindRoutes,
  });

  @override
  State<PlannerMapScreen> createState() => _PlannerMapScreenState();
}

class _PlannerMapScreenState extends State<PlannerMapScreen> {
  late String _from = widget.from;
  late String _to = widget.to;

  void _updateFrom(String value) {
    setState(() => _from = value);
    widget.onChangeJourney(_from, _to);
  }

  void _updateTo(String value) {
    setState(() => _to = value);
    widget.onChangeJourney(_from, _to);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: AppShadows.header,
          ),
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.chevron_left_rounded),
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text('Journey preview', style: AppTypography.titleMedium),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    _MapLocationField(
                      value: _from,
                      label: 'Current location',
                      icon: Icons.my_location_rounded,
                      color: AppColors.primary,
                      onChanged: _updateFrom,
                      onSelected: _updateFrom,
                    ),
                    const SizedBox(height: 8),
                    _MapLocationField(
                      value: _to,
                      label: 'Where do you want to go?',
                      icon: Icons.place_rounded,
                      color: AppColors.secondary,
                      onChanged: _updateTo,
                      onSelected: _updateTo,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: AppColors.background,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('JOURNEY OVERVIEW', style: AppTypography.captionBlack),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F0E8),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.card,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: CustomPaint(
                        painter: _MalaysiaJourneyPainter(from: _from, to: _to),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MapLegend(
                        icon: Icons.my_location_rounded,
                        color: AppColors.primary,
                        label: _from,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MapLegend(
                        icon: Icons.place_rounded,
                        color: AppColors.secondary,
                        label: _to,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onFindRoutes,
                    icon: const Icon(Icons.route_rounded, size: 18),
                    label: const Text('Show Route Options'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MapLocationField extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSelected;

  const _MapLocationField({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.onChanged,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: value),
      optionsBuilder: (textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        return plannerLocations
            .map((location) => location['name']!)
            .where(
              (name) => query.isEmpty || name.toLowerCase().contains(query),
            );
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          onSubmitted: (_) => onSubmitted(),
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: color, size: 18),
            suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 210),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: options.map((option) {
                  final location = plannerLocations.firstWhere(
                    (item) => item['name'] == option,
                  );
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      _transportIcon(location['mode']!),
                      color: _transportColor(location['mode']!),
                      size: 18,
                    ),
                    title: Text(option, style: AppTypography.bodyMedium),
                    subtitle: Text(
                      '${location['mode']} · ${location['line']}',
                      style: AppTypography.captionMedium,
                    ),
                    onTap: () => onSelected(option),
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MapLegend extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _MapLegend({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.captionBold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MalaysiaJourneyPainter extends CustomPainter {
  final String from;
  final String to;

  const _MalaysiaJourneyPainter({required this.from, required this.to});

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 390;
    final scaleY = size.height / 520;
    final outline = Paint()
      ..color = const Color(0xFFB6CFB8)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = const Color(0xFF91B596)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final peninsula = Path()
      ..moveTo(90 * scaleX, 48 * scaleY)
      ..lineTo(215 * scaleX, 45 * scaleY)
      ..lineTo(250 * scaleX, 125 * scaleY)
      ..lineTo(224 * scaleX, 222 * scaleY)
      ..lineTo(190 * scaleX, 330 * scaleY)
      ..lineTo(145 * scaleX, 420 * scaleY)
      ..lineTo(105 * scaleX, 355 * scaleY)
      ..lineTo(112 * scaleX, 275 * scaleY)
      ..lineTo(74 * scaleX, 190 * scaleY)
      ..close();
    final borneo = Path()
      ..moveTo(250 * scaleX, 245 * scaleY)
      ..lineTo(355 * scaleX, 230 * scaleY)
      ..lineTo(370 * scaleX, 305 * scaleY)
      ..lineTo(315 * scaleX, 370 * scaleY)
      ..lineTo(240 * scaleX, 338 * scaleY)
      ..close();
    canvas.drawPath(peninsula, outline);
    canvas.drawPath(peninsula, border);
    canvas.drawPath(borneo, outline);
    canvas.drawPath(borneo, border);

    final fromPoint = _pointFor(from, size);
    final toPoint = _pointFor(to, size);
    final routePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(fromPoint, toPoint, routePaint);
    _drawMarker(
      canvas,
      fromPoint,
      AppColors.primary,
      Icons.my_location_rounded,
    );
    _drawMarker(canvas, toPoint, AppColors.secondary, Icons.place_rounded);

    final labelStyle = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    canvas.drawText('MALAYSIA', Offset(130 * scaleX, 235 * scaleY), labelStyle);
    canvas.drawText(
      'SABAH / SARAWAK',
      Offset(265 * scaleX, 385 * scaleY),
      labelStyle,
    );
  }

  Offset _pointFor(String name, Size size) {
    final points = <String, Offset>{
      'Current location': const Offset(160, 220),
      'Asia Jaya': const Offset(142, 235),
      'Kelana Jaya': const Offset(125, 245),
      'Subang Jaya': const Offset(112, 230),
      'KL Sentral': const Offset(155, 210),
      'KLCC': const Offset(172, 190),
      'Pavilion Kuala Lumpur': const Offset(175, 198),
      'Pavilion Bukit Jalil': const Offset(145, 245),
      'Pavilion Damansara Heights': const Offset(150, 195),
      'Pavilion Square': const Offset(178, 205),
      'Pavilion Embassy': const Offset(182, 178),
      'Bukit Bintang': const Offset(178, 202),
      'Kajang': const Offset(235, 245),
      'Sunway Pyramid': const Offset(95, 270),
      'USJ 7': const Offset(78, 285),
      'Petaling Jaya': const Offset(125, 255),
    };
    final point = points[name] ?? const Offset(160, 220);
    return Offset(point.dx * size.width / 390, point.dy * size.height / 520);
  }

  void _drawMarker(Canvas canvas, Offset point, Color color, IconData icon) {
    final paint = Paint()..color = color;
    canvas.drawCircle(point, 11, paint);
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      point - Offset(iconPainter.width / 2, iconPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _MalaysiaJourneyPainter oldDelegate) =>
      oldDelegate.from != from || oldDelegate.to != to;
}

IconData _transportIcon(String mode) => mode == 'Bus' || mode == 'BRT'
    ? Icons.directions_bus_rounded
    : Icons.train_rounded;

Color _transportColor(String mode) {
  switch (mode) {
    case 'MRT':
      return AppColors.mkLine;
    case 'Monorail':
      return AppColors.mlLine;
    case 'Bus':
    case 'BRT':
      return AppColors.busLine;
    case 'KTM':
      return AppColors.spLine;
    default:
      return AppColors.kjLine;
  }
}

extension on Canvas {
  void drawText(String text, Offset offset, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(this, offset);
  }
}

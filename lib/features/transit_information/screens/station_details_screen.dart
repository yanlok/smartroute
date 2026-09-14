import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/transit_presentation.dart';
import '../../../shared/models/transit_models.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/transit_google_map.dart';

class StationDetailsScreen extends StatefulWidget {
  final TransitStop station;
  final TransitNetwork network;
  final VoidCallback onBack;

  const StationDetailsScreen({
    super.key,
    required this.station,
    required this.network,
    required this.onBack,
  });

  @override
  State<StationDetailsScreen> createState() => _StationDetailsScreenState();
}

class _StationDetailsScreenState extends State<StationDetailsScreen> {
  String? _selectedRouteId;

  List<TransitRoute> get _servedRoutes => [
    for (final routeId in widget.station.routeIds)
      ?widget.network.routesById[routeId],
  ]..sort((a, b) => a.displayName.compareTo(b.displayName));

  @override
  void initState() {
    super.initState();
    _selectedRouteId = _servedRoutes.firstOrNull?.id;
  }

  void _selectRoute(String routeId) {
    if (_selectedRouteId == routeId) return;
    setState(() => _selectedRouteId = routeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppPageHeader(
            title: TransitPresentation.formatStopName(widget.station.name),
            subtitle: 'Station details · ${widget.station.gtfsId}',
            onBack: widget.onBack,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.sectionLg,
                AppSpacing.pageHorizontal,
                AppSpacing.pageBottom,
              ),
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.card,
                  ),
                  child: TransitGoogleMap(
                    markers: [
                      TransitMapMarker(
                        id: widget.station.id,
                        label: TransitPresentation.formatStopName(
                          widget.station.name,
                        ),
                        coordinate: widget.station.coordinate,
                        kind: TransitMapMarkerKind.origin,
                      ),
                    ],
                    lines: [
                      for (final route in _servedRoutes)
                        if (route.shape.isNotEmpty)
                          TransitMapLine(
                            id: route.id,
                            color: TransitPresentation.routeColor(route),
                            points: route.shape,
                          ),
                    ],
                    initialCenter: widget.station.coordinate,
                    enableInteractionControls: true,
                    height: 220,
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionLg),
                const SizedBox(height: AppSpacing.sectionSm),
                Text('STATION INFORMATION', style: _sectionStyle),
                const SizedBox(height: AppSpacing.gapMd),
                _StationInformationCard(
                  scheduleWindow: _scheduledServiceWindow(context),
                ),
                const SizedBox(height: AppSpacing.sectionXl),
                Text('SERVED LINES', style: _sectionStyle),
                const SizedBox(height: AppSpacing.gapMd),
                if (_servedRoutes.isEmpty)
                  const _EmptyStationSection(
                    message: 'No lines are currently listed for this station.',
                  )
                else
                  for (final route in _servedRoutes) ...[
                    _RouteChoice(
                      route: route,
                      isSelected: route.id == _selectedRouteId,
                      onTap: () => _selectRoute(route.id),
                    ),
                    const SizedBox(height: AppSpacing.gapSm),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle get _sectionStyle => AppTypography.captionBlack.copyWith(
    color: AppColors.textSecondary,
    letterSpacing: 1.1,
  );

  String _scheduledServiceWindow(BuildContext context) {
    int? first;
    int? last;
    for (final pattern in widget.network.patterns) {
      final stopIndex = pattern.stopIds.indexOf(widget.station.id);
      if (stopIndex < 0) continue;
      final offset = pattern.offsetMinutes[stopIndex] * 60;
      final start = pattern.startSeconds + offset;
      final end = pattern.effectiveEndSeconds + offset;
      first = first == null || start < first ? start : first;
      last = last == null || end > last ? end : last;
    }
    if (first == null || last == null) return 'No scheduled service data';
    return '${_formatServiceTime(context, first)} – ${_formatServiceTime(context, last)}';
  }

  String _formatServiceTime(BuildContext context, int seconds) {
    final dayOffset = seconds ~/ Duration.secondsPerDay;
    final time = _formatTimeOfDay(context, seconds);
    return switch (dayOffset) {
      0 => time,
      1 => '$time (next day)',
      _ => '$time (+$dayOffset days)',
    };
  }

  String _formatTimeOfDay(BuildContext context, int seconds) {
    final minuteOfDay = (seconds ~/ 60) % Duration.minutesPerDay;
    return TimeOfDay(
      hour: minuteOfDay ~/ Duration.minutesPerHour,
      minute: minuteOfDay % Duration.minutesPerHour,
    ).format(context);
  }
}

class _StationInformationCard extends StatelessWidget {
  final String scheduleWindow;

  const _StationInformationCard({required this.scheduleWindow});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.cardPadding),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.border),
      boxShadow: AppShadows.card,
    ),
    child: Row(
      children: [
        const Icon(Icons.schedule_rounded, color: AppColors.secondary),
        const SizedBox(width: AppSpacing.gapMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scheduled service hours', style: AppTypography.bodyLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                scheduleWindow,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RouteChoice extends StatelessWidget {
  final TransitRoute route;
  final bool isSelected;
  final VoidCallback onTap;

  const _RouteChoice({
    required this.route,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = TransitPresentation.routeColor(route);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.gapMd),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? color : AppColors.borderLight,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                ),
              ),
              const SizedBox(width: AppSpacing.gapMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(route.displayName, style: AppTypography.bodyLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Line serving this station',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check_circle_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStationSection extends StatelessWidget {
  final String message;

  const _EmptyStationSection({required this.message});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.cardPadding),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: Text(
      message,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
    ),
  );
}

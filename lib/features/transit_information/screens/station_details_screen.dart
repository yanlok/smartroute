import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/transit_presentation.dart';
import '../../../shared/models/notice_models.dart';
import '../../../shared/models/transit_models.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/transit_google_map.dart';
import '../../alerts/application/notice_controller.dart';
import '../../user_management/application/saved_journey_controller.dart';

class StationDetailsScreen extends StatefulWidget {
  final TransitStop station;
  final TransitNetwork network;
  final String userId;
  final SavedJourneyController savedJourneys;
  final NoticeController notices;
  final String? initialRouteId;
  final VoidCallback onBack;
  final VoidCallback onOpenAlerts;
  final VoidCallback onViewFavoriteStations;

  const StationDetailsScreen({
    super.key,
    required this.station,
    required this.network,
    required this.userId,
    required this.savedJourneys,
    required this.notices,
    this.initialRouteId,
    required this.onBack,
    required this.onOpenAlerts,
    required this.onViewFavoriteStations,
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
    _selectedRouteId = _initialRouteId();
  }

  @override
  void didUpdateWidget(covariant StationDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.station.id != widget.station.id ||
        oldWidget.initialRouteId != widget.initialRouteId) {
      _selectedRouteId = _initialRouteId();
    }
  }

  String? _initialRouteId() =>
      _servedRoutes.any((route) => route.id == widget.initialRouteId)
      ? widget.initialRouteId
      : _servedRoutes.firstOrNull?.id;

  void _selectRoute(String routeId) {
    if (_selectedRouteId == routeId) return;
    setState(() => _selectedRouteId = routeId);
  }

  TransitRoute? get _selectedRoute =>
      widget.network.routesById[_selectedRouteId];

  TransitPattern? get _selectedPattern {
    final routeId = _selectedRouteId;
    if (routeId == null) return null;
    final patterns = widget.network.patterns
        .where(
          (pattern) =>
              pattern.routeId == routeId &&
              pattern.stopIds.contains(widget.station.id),
        )
        .toList();
    patterns.sort((a, b) {
      final aIndex = a.stopIds.indexOf(widget.station.id);
      final bIndex = b.stopIds.indexOf(widget.station.id);
      final remaining = (b.stopIds.length - bIndex).compareTo(
        a.stopIds.length - aIndex,
      );
      return remaining != 0 ? remaining : a.direction.compareTo(b.direction);
    });
    return patterns.firstOrNull;
  }

  Future<void> _toggleFavorite() async {
    final route = _selectedRoute;
    if (route == null) return;
    final wasFavorite = widget.savedJourneys.containsStation(
      widget.station.id,
      route.id,
    );
    final operation = widget.savedJourneys.toggleFavoriteStation(
      userId: widget.userId,
      station: widget.station,
      route: route,
    );
    if (mounted) setState(() {});
    final saved = await operation;
    if (!mounted) return;
    setState(() {});
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    if (!saved) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.savedJourneys.errorMessage ??
                'Favourite station could not be updated.',
          ),
        ),
      );
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          wasFavorite
              ? 'Removed from favourite stations'
              : 'Added to favourite stations',
        ),
        action: wasFavorite
            ? null
            : SnackBarAction(
                label: 'VIEW',
                onPressed: widget.onViewFavoriteStations,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = widget.savedJourneys.containsStationId(
      widget.station.id,
    );
    final notice = isFavorite
        ? widget.notices
              .activeNoticesForRouteIds(widget.station.routeIds)
              .firstOrNull
        : null;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppPageHeader(
            title: TransitPresentation.formatStopName(widget.station.name),
            subtitle: 'Station details · ${widget.station.gtfsId}',
            onBack: widget.onBack,
            action: IconButton(
              tooltip:
                  _selectedRoute != null &&
                      widget.savedJourneys.containsStation(
                        widget.station.id,
                        _selectedRoute!.id,
                      )
                  ? 'Remove favourite station'
                  : 'Add favourite station',
              onPressed: _selectedRoute == null || widget.savedJourneys.isSaving
                  ? null
                  : _toggleFavorite,
              icon: Icon(
                _selectedRoute != null &&
                        widget.savedJourneys.containsStation(
                          widget.station.id,
                          _selectedRoute!.id,
                        )
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color:
                    _selectedRoute != null &&
                        widget.savedJourneys.containsStation(
                          widget.station.id,
                          _selectedRoute!.id,
                        )
                    ? AppColors.primary
                    : AppColors.primary,
              ),
            ),
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
                if (notice != null) ...[
                  _StationNoticeBanner(
                    notice: notice,
                    onTap: widget.onOpenAlerts,
                  ),
                  const SizedBox(height: AppSpacing.sectionLg),
                ],
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
                const SizedBox(height: AppSpacing.sectionLg),
                Text('PREVIOUS & NEXT STOPS', style: _sectionStyle),
                const SizedBox(height: AppSpacing.gapMd),
                _StationSequenceCard(
                  station: widget.station,
                  network: widget.network,
                  pattern: _selectedPattern,
                ),
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

class _StationNoticeBanner extends StatelessWidget {
  final ServiceNotice notice;
  final VoidCallback onTap;

  const _StationNoticeBanner({required this.notice, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.containerPadding),
        decoration: BoxDecoration(
          color: AppColors.amberBg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.campaign_rounded,
              color: AppColors.amber,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.gapMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notice.title,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    notice.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.amber,
              size: 20,
            ),
          ],
        ),
      ),
    ),
  );
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

class _StationSequenceCard extends StatelessWidget {
  final TransitStop station;
  final TransitNetwork network;
  final TransitPattern? pattern;

  const _StationSequenceCard({
    required this.station,
    required this.network,
    required this.pattern,
  });

  @override
  Widget build(BuildContext context) {
    final selectedPattern = pattern;
    if (selectedPattern == null) {
      return const _EmptyStationSection(
        message: 'Stop sequence is not available for this line.',
      );
    }
    final index = selectedPattern.stopIds.indexOf(station.id);
    final previous = index > 0
        ? network.stopsById[selectedPattern.stopIds[index - 1]]
        : null;
    final next = selectedPattern.stopIds
        .skip(index + 1)
        .take(3)
        .map((id) => network.stopsById[id])
        .whereType<TransitStop>()
        .toList();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Towards ${selectedPattern.headsign}',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.gapMd),
          _SequenceStopRow(
            marker: 'P',
            label: previous == null
                ? 'Start of this direction'
                : TransitPresentation.formatStopName(previous.name),
            caption: 'Previous stop',
            muted: previous == null,
          ),
          const _SequenceDivider(),
          if (next.isEmpty)
            const _SequenceStopRow(
              marker: '1',
              label: 'End of this direction',
              caption: 'No next stop',
              muted: true,
            )
          else
            for (var i = 0; i < next.length; i++) ...[
              _SequenceStopRow(
                marker: '${i + 1}',
                label: TransitPresentation.formatStopName(next[i].name),
                caption: i == 0 ? 'Next stop' : 'Then',
              ),
              if (i < next.length - 1) const _SequenceDivider(),
            ],
        ],
      ),
    );
  }
}

class _SequenceStopRow extends StatelessWidget {
  final String marker;
  final String label;
  final String caption;
  final bool muted;

  const _SequenceStopRow({
    required this.marker,
    required this.label,
    required this.caption,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.secondaryLight,
          shape: BoxShape.circle,
        ),
        child: Text(marker, style: AppTypography.captionBold),
      ),
      const SizedBox(width: AppSpacing.gapMd),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              caption,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.bodyLarge.copyWith(
                color: muted ? AppColors.textTertiary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _SequenceDivider extends StatelessWidget {
  const _SequenceDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(left: AppSpacing.lg),
    child: SizedBox(
      height: AppSpacing.gapMd,
      child: VerticalDivider(color: AppColors.border),
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

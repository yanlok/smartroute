import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/transit_presentation.dart';
import '../../../shared/models/arrival_reminder.dart';
import '../../../shared/models/transit_models.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/transit_google_map.dart';
import '../../alerts/application/arrival_reminder_controller.dart';
import '../application/station_arrivals_controller.dart';

class StationDetailsScreen extends StatefulWidget {
  final TransitStop station;
  final TransitNetwork network;
  final ArrivalReminderController reminders;
  final VoidCallback onBack;

  const StationDetailsScreen({
    super.key,
    required this.station,
    required this.network,
    required this.reminders,
    required this.onBack,
  });

  @override
  State<StationDetailsScreen> createState() => _StationDetailsScreenState();
}

class _StationDetailsScreenState extends State<StationDetailsScreen> {
  String? _selectedRouteId;
  int _leadTimeMinutes = 5;
  late final StationArrivalsController _stationArrivals;
  ScheduledStationArrival? _selectedArrival;

  List<TransitRoute> get _servedRoutes => [
    for (final routeId in widget.station.routeIds)
      ?widget.network.routesById[routeId],
  ]..sort((a, b) => a.displayName.compareTo(b.displayName));

  @override
  void initState() {
    super.initState();
    _selectedRouteId = _servedRoutes.firstOrNull?.id;
    widget.reminders.addListener(_onRemindersChanged);
    _stationArrivals = StationArrivalsController(
      network: widget.network,
      stationId: widget.station.id,
    );
    _stationArrivals.addListener(_onStationArrivalsChanged);
    _stationArrivals.start();
  }

  @override
  void dispose() {
    widget.reminders.removeListener(_onRemindersChanged);
    _stationArrivals
      ..removeListener(_onStationArrivalsChanged)
      ..dispose();
    super.dispose();
  }

  void _onRemindersChanged() {
    if (mounted) setState(() {});
  }

  void _onStationArrivalsChanged() {
    final selectedKey = _selectedArrival?.dedupeKey;
    if (selectedKey != null &&
        !_stationArrivals.arrivals.any(
          (arrival) => arrival.dedupeKey == selectedKey,
        )) {
      _selectedArrival = null;
    }
    if (mounted) setState(() {});
  }

  void _selectRoute(String routeId) {
    if (_selectedRouteId == routeId) return;
    setState(() => _selectedRouteId = routeId);
  }

  void _selectArrival(ScheduledStationArrival arrival) {
    setState(() {
      _selectedArrival = arrival;
      _selectedRouteId = arrival.routeId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final arrivals = _stationArrivals.arrivals;
    final nextArrivalByRoute = <String, DateTime>{};
    for (final arrival in arrivals) {
      nextArrivalByRoute.putIfAbsent(
        arrival.routeId,
        () => arrival.scheduledArrival,
      );
    }
    final selectedArrival = _selectedArrival;
    final selectedArrivalRoute = selectedArrival == null
        ? null
        : widget.network.routesById[selectedArrival.routeId];
    final triggeredReminder = _triggeredReminder(now);
    final reminderRoute = triggeredReminder == null
        ? selectedArrivalRoute
        : widget.network.routesById[triggeredReminder.routeId];
    final reminderArrival =
        triggeredReminder?.expectedArrival ?? selectedArrival?.scheduledArrival;
    final arrivalIsImminent =
        reminderArrival != null &&
        reminderArrival.isAfter(now) &&
        reminderArrival.difference(now) <= const Duration(minutes: 5);
    final showArrivalBell =
        reminderRoute != null &&
        (triggeredReminder != null || arrivalIsImminent);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppPageHeader(
            title: TransitPresentation.formatStopName(widget.station.name),
            subtitle: 'Station details · ${widget.station.gtfsId}',
            onBack: widget.onBack,
            action: showArrivalBell
                ? Badge(
                    smallSize: 8,
                    child: IconButton(
                      tooltip: 'Arrival reminder ready',
                      onPressed: () => _showArrivalReminder(
                        route: reminderRoute,
                        expectedArrival: reminderArrival,
                        isDemo: triggeredReminder?.isDemo ?? false,
                      ),
                      icon: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : null,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _stationArrivals.refresh,
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
                      message:
                          'No lines are currently listed for this station.',
                    )
                  else
                    for (final route in _servedRoutes) ...[
                      _RouteChoice(
                        route: route,
                        isSelected: route.id == _selectedRouteId,
                        nextArrival: nextArrivalByRoute[route.id],
                        onTap: () => _selectRoute(route.id),
                      ),
                      const SizedBox(height: AppSpacing.gapSm),
                    ],
                  const SizedBox(height: AppSpacing.sectionXl),
                  Row(
                    children: [
                      Expanded(
                        child: Text('UPCOMING ARRIVALS', style: _sectionStyle),
                      ),
                      IconButton(
                        tooltip: 'Refresh upcoming arrivals',
                        onPressed: _stationArrivals.isLoading
                            ? null
                            : _stationArrivals.refresh,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.gapMd),
                  _UpcomingArrivals(
                    controller: _stationArrivals,
                    network: widget.network,
                    selectedArrivalKey: selectedArrival?.dedupeKey,
                    onSelect: _selectArrival,
                  ),
                  const SizedBox(height: AppSpacing.sectionXl),
                  Text('ARRIVAL REMINDER', style: _sectionStyle),
                  const SizedBox(height: AppSpacing.gapMd),
                  Container(
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
                          selectedArrival == null ||
                                  selectedArrivalRoute == null
                              ? 'Select an upcoming arrival to set a reminder.'
                              : 'Selected ${selectedArrivalRoute.displayName} arrival ${_formatArrivalTime(context, selectedArrival.scheduledArrival)}',
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.gapSm),
                        Text(
                          'Choose when SmartRoute should remind you before the scheduled arrival.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.gapMd),
                        Wrap(
                          spacing: AppSpacing.gapSm,
                          children: [5, 10, 15]
                              .map(
                                (minutes) => ChoiceChip(
                                  label: Text('$minutes min before'),
                                  selected: _leadTimeMinutes == minutes,
                                  onSelected: (_) => setState(
                                    () => _leadTimeMinutes = minutes,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: AppSpacing.sectionLg),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed:
                                selectedArrival == null ||
                                    selectedArrivalRoute == null ||
                                    widget.reminders.isSaving
                                ? null
                                : () => _createReminder(selectedArrival),
                            icon: const Icon(
                              Icons.notifications_active_outlined,
                            ),
                            label: const Text('Remind Me'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createReminder(ScheduledStationArrival arrival) async {
    final route = widget.network.routesById[arrival.routeId];
    if (route == null || !arrival.scheduledArrival.isAfter(DateTime.now())) {
      return;
    }
    final created = await widget.reminders.create(
      stationId: widget.station.id,
      routeId: route.id,
      expectedArrival: arrival.scheduledArrival,
      leadTimeMinutes: _leadTimeMinutes,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created
              ? 'Arrival reminder saved for ${route.shortName.isEmpty ? route.displayName : route.shortName}.'
              : (widget.reminders.errorMessage ??
                    'Arrival reminder could not be saved.'),
        ),
      ),
    );
  }

  ArrivalReminder? _triggeredReminder(DateTime now) {
    for (final reminder in widget.reminders.reminders) {
      if (reminder.stationId == widget.station.id &&
          reminder.statusAt(now) == ArrivalReminderStatus.triggered) {
        return reminder;
      }
    }
    return null;
  }

  void _showArrivalReminder({
    required TransitRoute route,
    required DateTime? expectedArrival,
    required bool isDemo,
  }) {
    final minutes = expectedArrival
        ?.difference(DateTime.now())
        .inMinutes
        .clamp(0, 999);
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.notifications_active_rounded,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(height: AppSpacing.gapMd),
            Text('Arrival reminder ready', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.gapSm),
            Text(
              '${TransitPresentation.formatStopName(widget.station.name)} on ${route.displayName}${minutes == null ? '' : ' is due in $minutes min'}.'
              '${isDemo ? ' This is the Track Live Route demo notification.' : ''}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sectionLg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
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

String _formatArrivalTime(BuildContext context, DateTime arrival) {
  final localArrival = arrival.toLocal();
  final time = TimeOfDay.fromDateTime(localArrival).format(context);
  final today = DateUtils.dateOnly(DateTime.now());
  final arrivalDate = DateUtils.dateOnly(localArrival);
  if (arrivalDate == today) return time;
  if (arrivalDate == today.add(const Duration(days: 1))) {
    return '$time tomorrow';
  }
  return '$time on ${MaterialLocalizations.of(context).formatMediumDate(localArrival)}';
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

class _UpcomingArrivals extends StatelessWidget {
  final StationArrivalsController controller;
  final TransitNetwork network;
  final String? selectedArrivalKey;
  final ValueChanged<ScheduledStationArrival> onSelect;

  const _UpcomingArrivals({
    required this.controller,
    required this.network,
    required this.selectedArrivalKey,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      if (controller.isLoading && controller.arrivals.isEmpty) {
        return const _ArrivalMessageCard(
          message: 'Loading scheduled arrivals...',
          loading: true,
        );
      }
      if (controller.errorMessage != null) {
        return _ArrivalMessageCard(
          message: controller.errorMessage!,
          onRetry: controller.refresh,
        );
      }
      if (controller.arrivals.isEmpty) {
        return const _ArrivalMessageCard(
          message: 'No upcoming scheduled arrivals for this station.',
        );
      }
      return Column(
        children: [
          for (var index = 0; index < controller.arrivals.length; index++) ...[
            _StationArrivalCard(
              arrival: controller.arrivals[index],
              route: network.routesById[controller.arrivals[index].routeId],
              isSelected:
                  controller.arrivals[index].dedupeKey == selectedArrivalKey,
              onTap: () => onSelect(controller.arrivals[index]),
            ),
            if (index < controller.arrivals.length - 1)
              const SizedBox(height: AppSpacing.gapSm),
          ],
        ],
      );
    },
  );
}

class _StationArrivalCard extends StatelessWidget {
  final ScheduledStationArrival arrival;
  final TransitRoute? route;
  final bool isSelected;
  final VoidCallback onTap;

  const _StationArrivalCard({
    required this.arrival,
    required this.route,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final routeColor = route == null
        ? AppColors.secondary
        : TransitPresentation.routeColor(route!);
    final headsign = arrival.pattern.headsign.trim();
    final direction = headsign.isEmpty
        ? 'Scheduled service'
        : 'Towards $headsign';
    final eta = arrival.etaMinutesAt(DateTime.now());

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? routeColor : AppColors.borderLight,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 56,
                decoration: BoxDecoration(
                  color: routeColor,
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                ),
              ),
              const SizedBox(width: AppSpacing.gapMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route?.displayName ?? arrival.routeId,
                      style: AppTypography.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      direction,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Scheduled ${_formatArrivalTime(context, arrival.scheduledArrival)}',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    eta == 0 ? 'Due' : '$eta min',
                    style: AppTypography.bodyLarge.copyWith(color: routeColor),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.gapSm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.circular),
                    ),
                    child: Text(
                      'SCHEDULED',
                      style: AppTypography.captionBold.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrivalMessageCard extends StatelessWidget {
  final String message;
  final bool loading;
  final VoidCallback? onRetry;

  const _ArrivalMessageCard({
    required this.message,
    this.loading = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.cardPadding),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: Row(
      children: [
        if (loading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          const Icon(Icons.schedule_outlined, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.gapMd),
        Expanded(
          child: Text(
            message,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(width: AppSpacing.gapSm),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ],
    ),
  );
}

class _RouteChoice extends StatelessWidget {
  final TransitRoute route;
  final bool isSelected;
  final DateTime? nextArrival;
  final VoidCallback onTap;

  const _RouteChoice({
    required this.route,
    required this.isSelected,
    required this.nextArrival,
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
                      nextArrival == null
                          ? 'No scheduled arrival today'
                          : 'Next: ${_formatArrivalTime(context, nextArrival!)}',
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

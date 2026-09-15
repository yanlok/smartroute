import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/transit_presentation.dart';
import '../../../shared/models/transit_models.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/mode_rail.dart';
import '../../../shared/widgets/transit_google_map.dart';
import '../../../shared/widgets/transit_route_tile.dart';
import '../../alerts/application/notice_controller.dart';
import '../../transit_network/application/transit_network_controller.dart';
import '../../user_management/application/saved_journey_controller.dart';
import 'station_details_screen.dart';

class TransitInformationScreen extends StatefulWidget {
  final TransitNetworkController controller;
  final NoticeController notices;
  final String userId;
  final SavedJourneyController savedJourneys;
  final String? initialRouteId;
  final String? initialStopId;
  final ValueChanged<String> onOpenProgress;

  const TransitInformationScreen({
    super.key,
    required this.controller,
    required this.notices,
    required this.userId,
    required this.savedJourneys,
    required this.onOpenProgress,
    this.initialRouteId,
    this.initialStopId,
  });

  @override
  State<TransitInformationScreen> createState() =>
      _TransitInformationScreenState();
}

class _TransitInformationScreenState extends State<TransitInformationScreen> {
  TransitMode? _mode;
  String? _selectedRouteId;
  String? _selectedStopId;
  String _query = '';
  final _searchController = TextEditingController();

  bool _mapExpanded = false;

  String? _highlightedRouteId;

  @override
  void initState() {
    super.initState();
    _selectedRouteId = widget.initialRouteId;
    _selectedStopId = widget.initialStopId;
    widget.controller.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TransitInformationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRouteId != null &&
        widget.initialRouteId != oldWidget.initialRouteId) {
      _selectedRouteId = widget.initialRouteId;
    }
    if (widget.initialStopId != null &&
        widget.initialStopId != oldWidget.initialStopId) {
      _selectedStopId = widget.initialStopId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, widget.notices]),
      builder: (context, _) {
        final network = widget.controller.network;
        if (network != null && _selectedStopId != null) {
          final stop = network.stopsById[_selectedStopId];
          if (stop != null) {
            return StationDetailsScreen(
              station: stop,
              network: network,
              userId: widget.userId,
              savedJourneys: widget.savedJourneys,
              initialRouteId: _selectedRouteId,
              onBack: () => setState(() => _selectedStopId = null),
            );
          }
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              if (_selectedRouteId == null)
                const AppPageHeader(
                  title: 'Explore Network',
                  subtitle: 'Lines, stations and network map',
                ),
              Expanded(
                child: network == null
                    ? _LoadingState(
                        loading: widget.controller.isLoading,
                        error: widget.controller.errorMessage,
                        onRetry: widget.controller.retry,
                      )
                    : _selectedRouteId == null
                    ? _catalogue(network)
                    : _routeDetail(network),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _catalogue(TransitNetwork network) {
    final query = _query.trim().toLowerCase();
    final routes = network.routes.where((route) {
      if (_mode != null && route.mode != _mode) return false;
      return query.isEmpty ||
          route.displayName.toLowerCase().contains(query) ||
          route.shortName.toLowerCase().contains(query);
    }).toList()..sort((a, b) => a.displayName.compareTo(b.displayName));
    final stations =
        query.isEmpty
              ? <TransitStop>[]
              : network.stops
                    .where(
                      (stop) =>
                          stop.name.toLowerCase().contains(query) ||
                          stop.gtfsId.toLowerCase().contains(query),
                    )
                    .where(
                      (stop) =>
                          _mode == null ||
                          stop.routeIds.any(
                            (routeId) =>
                                network.routesById[routeId]?.mode == _mode,
                          ),
                    )
                    .take(30)
                    .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    final overviewLines = <TransitMapLine>[];
    final overviewMarkers = <TransitMapMarker>[];

    if (_mode == null) {
      for (final route in network.routes) {
        if ((route.mode == TransitMode.lrt ||
                route.mode == TransitMode.mrt ||
                route.mode == TransitMode.monorail ||
                route.mode == TransitMode.brt) &&
            route.shape.isNotEmpty) {
          overviewLines.add(
            TransitMapLine(
              id: route.id,
              color: TransitPresentation.routeColor(route),
              points: route.shape,
            ),
          );
        }
      }
      final railRouteIds = network.routes
          .where((r) => r.mode != TransitMode.bus)
          .map((r) => r.id)
          .toSet();
      final majorHubs = <TransitStop>[];
      for (final stop in network.stops) {
        final railCount = stop.routeIds.where(railRouteIds.contains).length;
        if (railCount >= 2) {
          majorHubs.add(stop);
        }
      }
      for (final stop in majorHubs.take(6)) {
        overviewMarkers.add(
          TransitMapMarker(
            id: stop.id,
            label: TransitPresentation.formatStopName(stop.name),
            coordinate: stop.coordinate,
            kind: TransitMapMarkerKind.transfer,
            onTap: () => _showStop(stop),
          ),
        );
      }
    } else if (_mode == TransitMode.bus) {
      overviewLines.clear();
      overviewMarkers.clear();
    } else {
      for (final route in routes.take(8)) {
        if (route.shape.isNotEmpty) {
          overviewLines.add(
            TransitMapLine(
              id: route.id,
              color: TransitPresentation.routeColor(route),
              points: route.shape,
            ),
          );
        }
      }
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.gapMd,
            AppSpacing.pageHorizontal,
            AppSpacing.gapMd,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeInOut,
                    height: _mapExpanded ? 380 : 220,
                    child: TransitGoogleMap(
                      key: const ValueKey('transit-overview-map'),
                      markers: overviewMarkers,
                      lines: overviewLines,
                      initialCenter: const TransitCoordinate(3.1390, 101.6869),
                      enableInteractionControls: true,
                      activeRouteId: _highlightedRouteId,
                      onLineTap: (routeId) =>
                          setState(() => _highlightedRouteId = routeId),
                      height: _mapExpanded ? 380 : 220,
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(AppRadius.circular),
                      elevation: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.circular),
                        onTap: () =>
                            setState(() => _mapExpanded = !_mapExpanded),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            _mapExpanded
                                ? Icons.fullscreen_exit_rounded
                                : Icons.fullscreen_rounded,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        if (overviewLines.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.gapMd),
            child: SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal,
                ),
                itemCount: overviewLines.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.gapSm),
                itemBuilder: (context, index) {
                  final line = overviewLines[index];
                  final r = network.routesById[line.id];
                  final isHighlighted = _highlightedRouteId == line.id;
                  final rColor = r != null
                      ? TransitPresentation.routeColor(r)
                      : line.color;
                  return InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                    onTap: () {
                      setState(() {
                        _highlightedRouteId = isHighlighted ? null : line.id;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.gapMd,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? rColor
                            : rColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.circular),
                        border: Border.all(
                          color: isHighlighted
                              ? rColor
                              : rColor.withValues(alpha: 0.35),
                          width: isHighlighted ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.polyline_rounded,
                            size: 13,
                            color: isHighlighted ? Colors.white : rColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            r?.shortName.isNotEmpty == true
                                ? r!.shortName
                                : (r?.displayName ?? line.id),
                            style: AppTypography.captionBold.copyWith(
                              color: isHighlighted ? Colors.white : rColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

        if (_highlightedRouteId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              0,
              AppSpacing.pageHorizontal,
              AppSpacing.gapMd,
            ),
            child: _HighlightBanner(
              routeName:
                  network.routesById[_highlightedRouteId]?.displayName ??
                  _highlightedRouteId!,
              routeColor:
                  _highlightedRouteId != null &&
                      network.routesById[_highlightedRouteId] != null
                  ? TransitPresentation.routeColor(
                      network.routesById[_highlightedRouteId]!,
                    )
                  : AppColors.primary,
              onOpen: () => setState(() {
                _selectedRouteId = _highlightedRouteId;
                _highlightedRouteId = null;
              }),
              onDismiss: () => setState(() => _highlightedRouteId = null),
            ),
          ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.gapSm,
            AppSpacing.pageHorizontal,
            AppSpacing.pageBottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search line, station or route',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textTertiary,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                ),
              ),

              const SizedBox(height: AppSpacing.sectionMd),

              ModeRail(
                showAllOption: true,
                isAllSelected: _mode == null,
                onSelectAll: () => setState(() => _mode = null),
                selectedModes: _mode == null ? {} : {_mode!},
                onToggleMode: (mode) {
                  setState(() {
                    _mode = _mode == mode ? null : mode;
                  });
                },
              ),

              const SizedBox(height: AppSpacing.sectionLg),

              Row(
                children: [
                  Text(
                    '${routes.length} LINES',
                    style: AppTypography.captionBlack.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 1.1,
                    ),
                  ),
                  if (_mode != null) ...[
                    const SizedBox(width: AppSpacing.gapSm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.gapSm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: TransitPresentation.modeColor(
                          _mode!,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.circular),
                      ),
                      child: Text(
                        _mode!.label,
                        style: AppTypography.captionBold.copyWith(
                          color: TransitPresentation.modeColor(_mode!),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: AppSpacing.gapMd),

              if (routes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xxl4),
                  child: Center(
                    child: Text('No matching lines on the network.'),
                  ),
                )
              else
                for (final route in routes)
                  TransitRouteTile(
                    route: route,
                    stopCount: network.stops
                        .where((stop) => stop.routeIds.contains(route.id))
                        .length,
                    onTap: () => setState(() => _selectedRouteId = route.id),
                  ),
              if (query.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sectionXl),
                Text(
                  '${stations.length} STATIONS',
                  style: AppTypography.captionBlack.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.gapMd),
                if (stations.isEmpty)
                  Text(
                    'No matching stations on the network.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                else
                  for (final station in stations)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(
                        TransitPresentation.formatStopName(station.name),
                        style: AppTypography.bodyLarge,
                      ),
                      subtitle: Text(
                        '${station.routeIds.length} served lines',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => setState(() => _selectedStopId = station.id),
                    ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _routeDetail(TransitNetwork network) {
    final route = network.routesById[_selectedRouteId];
    if (route == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedRouteId = null);
      });
      return const SizedBox.shrink();
    }
    final pattern = network.patterns
        .where((item) => item.routeId == route.id)
        .firstOrNull;
    final stopIds =
        pattern?.stopIds ??
        [
          for (final stop in network.stops)
            if (stop.routeIds.contains(route.id)) stop.id,
        ];
    final routeNotices = widget.notices.notices
        .where(
          (notice) =>
              notice.routeId == route.id && notice.isActiveAt(DateTime.now()),
        )
        .toList();
    final markers = <TransitMapMarker>[
      for (final stopId in stopIds)
        if (network.stopsById[stopId] case final stop?)
          TransitMapMarker(
            id: stop.id,
            label: TransitPresentation.formatStopName(stop.name),
            coordinate: stop.coordinate,
            kind: TransitMapMarkerKind.stop,
            onTap: () => _showStop(stop),
          ),
    ];

    final isSubscribed = widget.notices.subscribedRouteIds.contains(route.id);

    return Column(
      children: [
        AppPageHeader(
          title: route.displayName,
          subtitle: '${route.mode.label} · ${route.operatorName}',
          onBack: () => setState(() => _selectedRouteId = null),
          action: IconButton(
            tooltip: isSubscribed ? 'Unfollow route' : 'Follow route',
            onPressed: () =>
                widget.notices.setSubscribed(route.id, !isSubscribed),
            icon: Icon(
              isSubscribed
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_none_rounded,
              color: AppColors.primary,
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.sectionMd,
            AppSpacing.pageHorizontal,
            0,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.card,
            ),
            child: TransitGoogleMap(
              markers: markers,
              lines: [
                TransitMapLine(
                  id: route.id,
                  color: TransitPresentation.routeColor(route),
                  points: route.shape,
                ),
              ],
              initialCenter: markers.firstOrNull?.coordinate,
              enableInteractionControls: true,
              height: 260,
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
              if (routeNotices.isNotEmpty) ...[
                _NoticeBanner(title: routeNotices.first.title),
                const SizedBox(height: AppSpacing.sectionLg),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () => widget.onOpenProgress(route.id),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.buttonVerticalMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  icon: const Icon(Icons.location_searching_rounded),
                  label: Text(
                    'Track Live Route',
                    style: AppTypography.bodyLarge,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sectionXl),
              Text(
                '${stopIds.length} STOPS · ${pattern?.headsign.isNotEmpty == true ? 'TOWARDS ${pattern!.headsign.toUpperCase()}' : 'SERVICE PATTERN'}',
                style: AppTypography.captionBlack.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.gapMd),
              for (var index = 0; index < stopIds.length; index++)
                if (network.stopsById[stopIds[index]] case final stop?)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.gapSm),
                    child: Material(
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: const BorderSide(color: AppColors.borderLight),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.cardPadding,
                          vertical: 2,
                        ),
                        leading: CircleAvatar(
                          radius: 13,
                          backgroundColor: TransitPresentation.routeColor(
                            route,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: AppTypography.captionBold.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        title: Text(
                          TransitPresentation.formatStopName(stop.name),
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          stop.routeIds.length > 1
                              ? 'Interchange · ${stop.routeIds.length} routes'
                              : stop.gtfsId,
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textTertiary,
                        ),
                        onTap: () => _showStop(stop),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  void _showStop(TransitStop stop) {
    setState(() => _selectedStopId = stop.id);
  }
}

class _NoticeBanner extends StatelessWidget {
  final String title;

  const _NoticeBanner({required this.title});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.containerPadding),
    decoration: BoxDecoration(
      color: AppColors.amberBg,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.campaign_rounded, color: AppColors.amber, size: 20),
        const SizedBox(width: AppSpacing.gapMd),
        Expanded(
          child: Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _HighlightBanner extends StatelessWidget {
  final String routeName;
  final Color routeColor;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  const _HighlightBanner({
    required this.routeName,
    required this.routeColor,
    required this.onOpen,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) => AnimatedSize(
    duration: const Duration(milliseconds: 200),
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPadding,
        vertical: AppSpacing.gapSm,
      ),
      decoration: BoxDecoration(
        color: routeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: routeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: routeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.gapMd),
          Expanded(
            child: Text(
              routeName,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.gapSm),
          TextButton(
            onPressed: onOpen,
            style: TextButton.styleFrom(
              foregroundColor: routeColor,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gapMd,
                vertical: AppSpacing.xs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Open detail',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: routeColor,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 16),
            color: AppColors.textTertiary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    ),
  );
}

class _LoadingState extends StatelessWidget {
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  const _LoadingState({
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: loading
        ? const CircularProgressIndicator(color: AppColors.primary)
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error ?? 'Transit network is empty.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.gapMd),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
  );
}

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

class TransitInformationScreen extends StatefulWidget {
  final TransitNetworkController controller;
  final NoticeController notices;
  final String? initialRouteId;
  final ValueChanged<String> onOpenProgress;

  const TransitInformationScreen({
    super.key,
    required this.controller,
    required this.notices,
    required this.onOpenProgress,
    this.initialRouteId,
  });

  @override
  State<TransitInformationScreen> createState() =>
      _TransitInformationScreenState();
}

class _TransitInformationScreenState extends State<TransitInformationScreen> {
  TransitMode? _mode;
  String? _selectedRouteId;
  String _query = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedRouteId = widget.initialRouteId;
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
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, widget.notices]),
      builder: (context, _) {
        final network = widget.controller.network;
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

    // Curate overview network lines for map presence
    final overviewLines = <TransitMapLine>[];
    final overviewMarkers = <TransitMapMarker>[];

    if (_mode == null) {
      // Show rail lines for a clear geographic network representation
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
      // Add key interchange stops
      for (final stop in network.stops) {
        if (stop.routeIds.length >= 3) {
          overviewMarkers.add(
            TransitMapMarker(
              id: stop.id,
              label: TransitPresentation.formatStopName(stop.name),
              coordinate: stop.coordinate,
              kind: TransitMapMarkerKind.transfer,
              onTap: () => _showStop(stop, network),
            ),
          );
        }
      }
    } else {
      // Show lines for selected mode
      for (final route in routes.take(12)) {
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
        // Network Geographic Canvas Map (Top 35%)
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
            child: TransitGoogleMap(
              markers: overviewMarkers,
              lines: overviewLines,
              initialCenter: const TransitCoordinate(3.1390, 101.6869),
              height: 220,
            ),
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
              // Search Bar
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

              // Mode Filter Rail
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

              // Results Count Header
              Row(
                children: [
                  Text(
                    '${routes.length} ROUTES',
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
                    child: Text('No matching routes on the network.'),
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
            onTap: () => _showStop(stop, network),
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
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.sectionLg,
              AppSpacing.pageHorizontal,
              AppSpacing.pageBottom,
            ),
            children: [
              TransitGoogleMap(
                markers: markers,
                lines: [
                  TransitMapLine(
                    id: route.id,
                    color: TransitPresentation.routeColor(route),
                    points: route.shape,
                  ),
                ],
                initialCenter: markers.firstOrNull?.coordinate,
                height: 250,
              ),
              const SizedBox(height: AppSpacing.sectionLg),
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
                  icon: Icon(
                    route.mode == TransitMode.bus ||
                            route.mode == TransitMode.brt
                        ? Icons.location_searching_rounded
                        : Icons.timeline_rounded,
                  ),
                  label: Text(
                    route.mode == TransitMode.bus ||
                            route.mode == TransitMode.brt
                        ? 'Track official vehicle positions'
                        : 'View scheduled journey progress',
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
                        onTap: () => _showStop(stop, network),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showStop(TransitStop stop, TransitNetwork network) async {
    final served = [
      for (final routeId in stop.routeIds) ?network.routesById[routeId],
    ];
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TransitPresentation.formatStopName(stop.name),
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Official GTFS stop ${stop.gtfsId} (${stop.name})',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sectionLg),
            Text(
              'SERVED ROUTES',
              style: AppTypography.captionBlack.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: AppSpacing.gapMd),
            Wrap(
              spacing: AppSpacing.gapMd,
              runSpacing: AppSpacing.gapMd,
              children: [
                for (final route in served)
                  ActionChip(
                    avatar: Icon(
                      TransitPresentation.modeIcon(route.mode),
                      size: 14,
                      color: TransitPresentation.routeColor(route),
                    ),
                    label: Text(
                      route.shortName.isEmpty
                          ? route.displayName
                          : route.shortName,
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    side: BorderSide(
                      color: TransitPresentation.routeColor(
                        route,
                      ).withValues(alpha: 0.4),
                    ),
                    backgroundColor: AppColors.surface,
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() => _selectedRouteId = route.id);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
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

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/transit_presentation.dart';
import '../../../shared/models/transit_models.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/transit_google_map.dart';
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

  @override
  void initState() {
    super.initState();
    _selectedRouteId = widget.initialRouteId;
    widget.controller.load();
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
        return Column(
          children: [
            const AppPageHeader(
              title: 'Transit',
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.sectionLg,
        AppSpacing.pageHorizontal,
        AppSpacing.pageBottom,
      ),
      children: [
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            hintText: 'Search 237 official routes',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.sectionLg),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _mode == null,
                onSelected: (_) => setState(() => _mode = null),
              ),
              for (final mode in TransitMode.values) ...[
                const SizedBox(width: AppSpacing.gapMd),
                ChoiceChip(
                  label: Text(mode.label),
                  selected: _mode == mode,
                  onSelected: (_) => setState(() => _mode = mode),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sectionLg),
        Text('${routes.length} routes', style: AppTypography.captionBlack),
        const SizedBox(height: AppSpacing.gapMd),
        if (routes.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xxl4),
            child: Center(child: Text('No matching routes.')),
          )
        else
          for (final route in routes)
            _RouteTile(
              route: route,
              stopCount: network.stops
                  .where((stop) => stop.routeIds.contains(route.id))
                  .length,
              onTap: () => setState(() => _selectedRouteId = route.id),
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
            label: stop.name,
            coordinate: stop.coordinate,
            kind: TransitMapMarkerKind.stop,
            onTap: () => _showStop(stop, network),
          ),
    ];
    return Column(
      children: [
        Material(
          color: AppColors.surface,
          child: ListTile(
            leading: IconButton(
              tooltip: 'All routes',
              onPressed: () => setState(() => _selectedRouteId = null),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            title: Text(route.displayName, style: AppTypography.bodyLarge),
            subtitle: Text('${route.mode.label} · ${route.operatorName}'),
            trailing: IconButton(
              tooltip: widget.notices.subscribedRouteIds.contains(route.id)
                  ? 'Unfollow route'
                  : 'Follow route',
              onPressed: () => widget.notices.setSubscribed(
                route.id,
                !widget.notices.subscribedRouteIds.contains(route.id),
              ),
              icon: Icon(
                widget.notices.subscribedRouteIds.contains(route.id)
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                color: AppColors.primary,
              ),
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
              if (routeNotices.isNotEmpty)
                _NoticeBanner(title: routeNotices.first.title),
              if (routeNotices.isNotEmpty)
                const SizedBox(height: AppSpacing.sectionLg),
              FilledButton.tonalIcon(
                onPressed: () => widget.onOpenProgress(route.id),
                icon: Icon(
                  route.mode == TransitMode.bus || route.mode == TransitMode.brt
                      ? Icons.location_searching_rounded
                      : Icons.timeline_rounded,
                ),
                label: Text(
                  route.mode == TransitMode.bus || route.mode == TransitMode.brt
                      ? 'Track official vehicle positions'
                      : 'View scheduled journey progress',
                ),
              ),
              const SizedBox(height: AppSpacing.sectionXl),
              Text(
                '${stopIds.length} STOPS · ${pattern?.headsign.isNotEmpty == true ? 'TOWARDS ${pattern!.headsign.toUpperCase()}' : 'SERVICE PATTERN'}',
                style: AppTypography.captionBlack,
              ),
              const SizedBox(height: AppSpacing.gapMd),
              for (var index = 0; index < stopIds.length; index++)
                if (network.stopsById[stopIds[index]] case final stop?)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 13,
                      backgroundColor: TransitPresentation.routeColor(route),
                      child: Text(
                        '${index + 1}',
                        style: AppTypography.captionBold.copyWith(
                          color: AppColors.surface,
                        ),
                      ),
                    ),
                    title: Text(stop.name),
                    subtitle: Text(
                      stop.routeIds.length > 1
                          ? 'Interchange · ${stop.routeIds.length} routes'
                          : stop.gtfsId,
                    ),
                    onTap: () => _showStop(stop, network),
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
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stop.name, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Official GTFS stop ${stop.gtfsId}',
              style: AppTypography.labelMedium,
            ),
            const SizedBox(height: AppSpacing.sectionLg),
            Text('SERVED ROUTES', style: AppTypography.captionBlack),
            const SizedBox(height: AppSpacing.gapMd),
            Wrap(
              spacing: AppSpacing.gapMd,
              runSpacing: AppSpacing.gapMd,
              children: [
                for (final route in served)
                  ActionChip(
                    label: Text(
                      route.shortName.isEmpty
                          ? route.displayName
                          : route.shortName,
                    ),
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

class _RouteTile extends StatelessWidget {
  final TransitRoute route;
  final int stopCount;
  final VoidCallback onTap;

  const _RouteTile({
    required this.route,
    required this.stopCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: AppSpacing.gapMd),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      side: const BorderSide(color: AppColors.borderLight),
    ),
    child: ListTile(
      onTap: onTap,
      leading: Container(
        width: AppSpacing.xs,
        height: 42,
        decoration: BoxDecoration(
          color: TransitPresentation.routeColor(route),
          borderRadius: BorderRadius.circular(AppRadius.circular),
        ),
      ),
      title: Text(route.displayName),
      subtitle: Text('${route.mode.label} · $stopCount stops'),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
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
    ),
    child: Row(
      children: [
        const Icon(Icons.campaign_rounded, color: AppColors.amber),
        const SizedBox(width: AppSpacing.gapMd),
        Expanded(child: Text(title)),
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
              Text(error ?? 'Transit network is empty.'),
              const SizedBox(height: AppSpacing.gapMd),
              OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
  );
}

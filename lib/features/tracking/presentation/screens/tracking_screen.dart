import 'package:flutter/material.dart';

import '../../../../core/constants/navigation_types.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/tracking_controller.dart';
import '../../data/repositories/line_directory_repository_impl.dart';
import '../../data/repositories/tracking_repository_impl.dart';
import '../../domain/models/live_vehicle.dart';
import '../../domain/models/tracking_station.dart';
import '../widgets/live_map_painter.dart';
import '../widgets/transit_line_color_resolver.dart';
import '../widgets/upcoming_stops_list.dart';
import '../widgets/vehicle_info_card.dart';

/// Single-line tracking view.
///
/// Owns a [TrackingController] (Phase 3) and a pulse animation.
/// Renders the [LiveMapPainter], the [VehicleInfoCard] for the
/// leading vehicle, and the [UpcomingStopsList] for upcoming
/// stations. Tapping a station row pushes [ArrivalsScreen] for
/// the per-station countdown.
class TrackingScreen extends StatefulWidget {
  /// The line id to focus on. The screen does NOT load the line
  /// catalogue — the parent (typically the line picker) is
  /// responsible for choosing a line.
  final String lineId;

  /// Optional pre-built controller. If `null`, the screen builds
  /// its own with the default in-memory repositories. Tests and
  /// future dependency-wired main shells pass a fully formed
  /// controller here.
  final TrackingController? controller;

  /// Invoked when the user taps the back button.
  final VoidCallback onBack;

  /// Invoked when the user wants to drill into the per-line map
  /// of all lines. The parent AppShell typically navigates to
  /// the line picker when this fires.
  final ValueChanged<AppScreen> onNavigate;

  const TrackingScreen({
    super.key,
    required this.lineId,
    required this.onBack,
    required this.onNavigate,
    this.controller,
  });

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  late final TrackingController _controller;
  late final AnimationController _pulseController;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = TrackingController(
        trackingRepository: TrackingRepositoryImpl(),
        directoryRepository: LineDirectoryRepositoryImpl(),
      );
      _ownsController = true;
    }
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _controller.selectLine(widget.lineId);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, _pulseController]),
      builder: (context, _) {
        final line = _controller.selectedLine;
        final colorToken = line?.colorToken ?? 'kjLine';
        final lineColor = TransitLineColorResolver.resolve(colorToken);
        final vehicle = _controller.currentVehicle;
        final stations = _controller.stations;

        return Column(
          children: [
            _buildHeader(colorToken, line?.name ?? 'Live Tracking'),
            _buildMap(lineColor, stations, vehicle),
            const SizedBox(height: AppSpacing.xl),
            if (vehicle != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pageHorizontal,
                ),
                child: VehicleInfoCard(
                  vehicle: vehicle,
                  lineCode: line?.code ?? '—',
                  colorToken: colorToken,
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.pageHorizontal,
              ),
              child: UpcomingStopsList(
                stops: _upcomingStationsFromVehicle(stations, vehicle),
                onStationTap: _onStopTapped,
              ),
            ),
            const SizedBox(height: AppSpacing.pageBottom),
          ],
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────

  Widget _buildHeader(String colorToken, String title) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.header,
      ),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.cardPadding,
            ),
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
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(title, style: AppTypography.titleMedium)),
                _SimulatedBadge(colorToken: colorToken),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Map ────────────────────────────────────────────────────────────

  Widget _buildMap(
    Color lineColor,
    List<TrackingStation> stations,
    LiveVehicle? vehicle,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pageHorizontal,
      ),
      child: Semantics(
        label: 'Simulated live tracking map — not real-time data.',
        child: AspectRatio(
          aspectRatio: 390 / 196,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.mutedBg,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: AppShadows.card,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: LiveMapPainter(
                      stations: stations,
                      vehicle: vehicle,
                      pulseValue: _pulseController.value,
                      lineColor: lineColor,
                    ),
                    size: Size.infinite,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────

  List<TrackingStation> _upcomingStationsFromVehicle(
    List<TrackingStation> stations,
    LiveVehicle? vehicle,
  ) {
    if (stations.isEmpty) return const <TrackingStation>[];
    if (vehicle == null) {
      return stations.take(4).toList();
    }
    // Show the current station + 3 upcoming. The "current" station
    // is the one nearest to the vehicle's positionFraction.
    final n = stations.length;
    final currentIdx = (vehicle.positionFraction * (n - 1)).round().clamp(
      0,
      n - 1,
    );
    return stations.skip(currentIdx).take(4).toList();
  }

  void _onStopTapped(TrackingStation station) {
    widget.onNavigate(AppScreen.tracking);
  }
}

/// Replaces the legacy "LIVE" pill. Renders a "SIM" badge in
/// amber to make it unambiguous that the data is simulated.
class _SimulatedBadge extends StatelessWidget {
  final String colorToken;
  const _SimulatedBadge({required this.colorToken});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Simulated live tracking — not real-time data.',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.amberBg,
          borderRadius: BorderRadius.circular(AppRadius.circular),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSpacing.dotSmall,
              height: AppSpacing.dotSmall,
              decoration: const BoxDecoration(
                color: AppColors.amber,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'SIM',
              style: AppTypography.captionBold.copyWith(color: AppColors.amber),
            ),
          ],
        ),
      ),
    );
  }
}

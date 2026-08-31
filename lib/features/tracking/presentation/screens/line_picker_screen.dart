import 'package:flutter/material.dart';

import '../../../../core/constants/navigation_types.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../application/line_picker_controller.dart';
import '../../data/datasources/mock_line_directory_data_source.dart';
import '../../data/datasources/mock_tracking_data_source.dart';
import '../../data/repositories/line_directory_repository_impl.dart';
import '../../data/repositories/tracking_repository_impl.dart';
import '../../domain/models/line_operational_status.dart';
import '../../domain/models/transit_line.dart';
import '../widgets/line_picker_tile.dart';
import 'tracking_screen.dart';

/// Lists every supported transit line so the user can choose one
/// to track. Tapping a row pushes the [TrackingScreen] for that
/// line.
class LinePickerScreen extends StatefulWidget {
  /// Optional pre-built controller. If `null`, the screen builds
  /// its own with the default in-memory repositories.
  final LinePickerController? controller;

  /// Invoked when the user taps the back button.
  final VoidCallback onBack;

  /// Optional callback to navigate to a different top-level screen
  /// (the AppShell is responsible for the actual routing).
  final ValueChanged<AppScreen> onNavigate;

  const LinePickerScreen({
    super.key,
    required this.onBack,
    required this.onNavigate,
    this.controller,
  });

  @override
  State<LinePickerScreen> createState() => _LinePickerScreenState();
}

class _LinePickerScreenState extends State<LinePickerScreen> {
  late final LinePickerController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = LinePickerController(
        directoryRepository: LineDirectoryRepositoryImpl(),
        trackingRepository: TrackingRepositoryImpl(
          dataSource: MockTrackingDataSource(
            directory: const MockLineDirectoryDataSource(),
          ),
        ),
      );
      _ownsController = true;
    }
    _controller.load();
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Column(
          children: [
            _buildHeader(),
            if (_controller.isLoading && !_controller.hasLoaded)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_controller.errorMessage != null)
              _ErrorState(
                message: _controller.errorMessage!,
                onRetry: _controller.refresh,
              )
            else
              Expanded(
                child: _LineList(
                  lines: _controller.lines,
                  stationCountByLineId: _stationCountByLineId(),
                  statusByLineId: _controller.statuses,
                  onTap: _onLineTapped,
                ),
              ),
          ],
        );
      },
    );
  }

  Map<String, int> _stationCountByLineId() {
    final out = <String, int>{};
    for (final line in _controller.lines) {
      out[line.id] = line.stationCount;
    }
    return out;
  }

  void _onLineTapped(TransitLine line) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrackingScreen(
          lineId: line.id,
          onBack: () => Navigator.of(context).pop(),
          onNavigate: (screen) {
            // The tracking screen may request to navigate to
            // other top-level screens. We only support
            // returning to the line picker for now; deeper
            // arrival navigation lives in the tracking screen
            // itself.
            widget.onNavigate(screen);
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Live Tracking',
                    style: AppTypography.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineList extends StatelessWidget {
  final List<TransitLine> lines;
  final Map<String, int> stationCountByLineId;
  final Map<String, dynamic> statusByLineId;
  final ValueChanged<TransitLine> onTap;

  const _LineList({
    required this.lines,
    required this.stationCountByLineId,
    required this.statusByLineId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xl,
        AppSpacing.pageHorizontal,
        AppSpacing.pageBottom,
      ),
      itemCount: lines.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sectionMd),
      itemBuilder: (context, i) {
        final line = lines[i];
        final status = statusByLineId[line.id];
        final (label, fg, bg) = _statusStyle(status);
        return LinePickerTile(
          line: line,
          stationCount: stationCountByLineId[line.id] ?? 0,
          statusLabel: label,
          statusColor: fg,
          statusBackground: bg,
          onTap: () => onTap(line),
        );
      },
    );
  }

  (String, Color, Color) _statusStyle(dynamic status) {
    if (status == null) {
      return ('Loading…', AppColors.textSecondary, AppColors.mutedBg);
    }
    switch (status.status as LineOperationalStatus) {
      case LineOperationalStatus.onTime:
        return (
          'On Time',
          AppColors.statusOnTimeText,
          AppColors.statusOnTimeBg,
        );
      case LineOperationalStatus.minorDelay:
        return (
          'Minor Delay',
          AppColors.statusMinorDelayText,
          AppColors.statusMinorDelayBg,
        );
      case LineOperationalStatus.majorDelay:
        return (
          'Major Delay',
          AppColors.statusMajorDelayText,
          AppColors.statusMajorDelayBg,
        );
      case LineOperationalStatus.suspended:
        return (
          'Suspended',
          AppColors.statusSuspendedText,
          AppColors.statusSuspendedBg,
        );
    }
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.iconGray,
              size: 40,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              message,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () {
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxl,
                  vertical: AppSpacing.buttonVerticalMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text('Retry', style: AppTypography.bodyLarge),
            ),
          ],
        ),
      ),
    );
  }
}

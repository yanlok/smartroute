import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/arrivals_controller.dart';
import '../../data/datasources/mock_line_directory_data_source.dart';
import '../../data/datasources/mock_tracking_data_source.dart';
import '../../data/repositories/tracking_repository_impl.dart';
import '../../domain/models/transit_line.dart';
import '../widgets/countdown_tile.dart';

/// Per-station arrivals list. Driven by an [ArrivalsController]
/// that subscribes to the (simulated) arrivals stream from
/// [TrackingRepositoryImpl].
class ArrivalsScreen extends StatefulWidget {
  final String lineId;
  final String stationId;
  final TransitLine? line;
  final ArrivalsController? controller;
  final VoidCallback onBack;

  const ArrivalsScreen({
    super.key,
    required this.lineId,
    required this.stationId,
    required this.onBack,
    this.line,
    this.controller,
  });

  @override
  State<ArrivalsScreen> createState() => _ArrivalsScreenState();
}

class _ArrivalsScreenState extends State<ArrivalsScreen> {
  late final ArrivalsController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = ArrivalsController(
        trackingRepository: TrackingRepositoryImpl(
          dataSource: MockTrackingDataSource(
            directory: const MockLineDirectoryDataSource(),
          ),
        ),
        lineId: widget.lineId,
        stationId: widget.stationId,
      );
      _ownsController = true;
    }
    _controller.start();
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
    final lineCode = widget.line?.code ?? widget.lineId.toUpperCase();
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Column(
          children: [
            _buildHeader(lineCode),
            Expanded(child: _buildBody(lineCode)),
          ],
        );
      },
    );
  }

  Widget _buildHeader(String lineCode) {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.stationId, style: AppTypography.titleMedium),
                      Text(
                        'Upcoming · $lineCode',
                        style: AppTypography.labelMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(String lineCode) {
    if (_controller.isLoading && _controller.arrivals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _controller.errorMessage!,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _controller.retry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_controller.arrivals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl3),
          child: Text(
            'No upcoming vehicles (simulated).',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.xl,
        AppSpacing.pageHorizontal,
        AppSpacing.pageBottom,
      ),
      itemCount: _controller.arrivals.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sectionMd),
      itemBuilder: (context, i) {
        return CountdownTile(
          arrival: _controller.arrivals[i],
          lineCode: lineCode,
        );
      },
    );
  }
}

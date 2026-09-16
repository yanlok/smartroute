import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../application/tracking_session_controller.dart';
import '../../domain/models/tracking_session.dart';

String _formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day}/${local.month}/${local.year}';
}

/// Bottom sheet listing past commute tracking logs with delete support.
/// Logs are revealed in pages of [pageSize]; more pages load as the user
/// scrolls toward the bottom.
class TrackingHistorySheet extends StatefulWidget {
  final TrackingSessionController controller;

  const TrackingHistorySheet({super.key, required this.controller});

  /// Number of logs revealed per page while scrolling.
  static const int pageSize = 10;

  static Future<void> show(
    BuildContext context, {
    required TrackingSessionController controller,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: TrackingHistorySheet(controller: controller),
        ),
      ),
    );
  }

  @override
  State<TrackingHistorySheet> createState() => _TrackingHistorySheetState();
}

class _TrackingHistorySheetState extends State<TrackingHistorySheet> {
  final ScrollController _scrollController = ScrollController();
  int _visibleCount = TrackingHistorySheet.pageSize;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  /// Reveals the next page. A short delay keeps the "Loading more…" state
  /// visible so the paged reveal is obvious even though the data is local.
  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    final total = widget.controller.pastSessions.length;
    if (_visibleCount >= total) return;
    setState(() => _isLoadingMore = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _isLoadingMore = false;
      final latestTotal = widget.controller.pastSessions.length;
      _visibleCount = math.min(
        _visibleCount + TrackingHistorySheet.pageSize,
        latestTotal,
      );
    });
  }

  /// On large screens the first page may not fill the viewport, which would
  /// leave the list unscrollable and the remaining pages unreachable. Grow the
  /// page until the list scrolls (or every log is shown).
  void _fillViewportIfPossible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      if (_scrollController.position.maxScrollExtent <= 0) {
        _loadMore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final sessions = widget.controller.pastSessions;
        final visibleSessions = sessions
            .take(_visibleCount)
            .toList(growable: false);
        final hasMore = visibleSessions.length < sessions.length;
        final result = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.cardPadding,
                AppSpacing.gapLg,
                AppSpacing.cardPadding,
                AppSpacing.gapSm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Session History',
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: sessions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.sectionLg),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.route_rounded,
                              size: 36,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: AppSpacing.gapMd),
                            Text(
                              'No commute logs yet.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Track a live route to start your history.',
                              style: AppTypography.captionMedium.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(AppSpacing.cardPadding),
                      itemCount: visibleSessions.length + (hasMore ? 1 : 0),
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.gapSm),
                      itemBuilder: (context, index) {
                        if (index >= visibleSessions.length) {
                          return _MoreFooter(isLoading: _isLoadingMore);
                        }
                        final session = visibleSessions[index];
                        return _HistoryTile(
                          session: session,
                          onDelete: widget.controller.isSaving
                              ? null
                              : () => _confirmDelete(context, session),
                        );
                      },
                    ),
            ),
            if (widget.controller.errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.cardPadding,
                  0,
                  AppSpacing.cardPadding,
                  AppSpacing.gapMd,
                ),
                child: Text(
                  widget.controller.errorMessage!,
                  style: AppTypography.captionMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        );
        _fillViewportIfPossible();
        return result;
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TrackingSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Delete this log?',
          style: AppTypography.headlineSmall.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          '${session.routeName} on ${_formatDate(session.startedAt)} will be '
          'permanently removed.',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.controller.deleteSession(session);
    }
  }
}

class _HistoryTile extends StatelessWidget {
  final TrackingSession session;
  final VoidCallback? onDelete;

  const _HistoryTile({required this.session, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isCompleted = session.status == TrackingSessionStatus.completed;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.gapMd),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.successBg : AppColors.mutedBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 16,
              color: isCompleted ? AppColors.success : AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.gapMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.routeName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDate(session.startedAt)} · '
                  '${session.originStopName} → '
                  '${session.destinationStopName ?? session.originStopName}',
                  style: AppTypography.captionMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (session.notes != null && session.notes!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    session.notes!,
                    style: AppTypography.captionMedium.copyWith(
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.gapSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _durationText(session),
                style: AppTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(AppRadius.circular),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: onDelete == null
                        ? AppColors.textTertiary
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _durationText(TrackingSession session) {
    final minutes = session.durationMinutes;
    if (minutes == null) {
      return session.status == TrackingSessionStatus.completed
          ? 'Completed'
          : 'Cancelled';
    }
    return '$minutes min';
  }
}

/// End-of-list marker shown while more logs remain unloaded.
class _MoreFooter extends StatelessWidget {
  final bool isLoading;

  const _MoreFooter({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.gapLg),
      child: Center(
        child: isLoading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: AppSpacing.gapMd),
                  Text(
                    'Loading more…',
                    style: AppTypography.captionMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              )
            : Text(
                'More logs · keep scrolling',
                style: AppTypography.captionMedium.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
      ),
    );
  }
}

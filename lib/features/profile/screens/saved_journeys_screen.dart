import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/transit_presentation.dart';
import '../../../shared/models/journey_models.dart';
import '../../../shared/models/transit_models.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../user_management/application/saved_journey_controller.dart';
import '../../user_management/domain/models/saved_journey.dart';

class SavedJourneysScreen extends StatelessWidget {
  final String userId;
  final SavedJourneyController controller;
  final TransitNetwork? network;
  final VoidCallback onBack;
  final Future<void> Function(String originStopId, String destinationStopId)
  onReplan;

  const SavedJourneysScreen({
    super.key,
    required this.userId,
    required this.controller,
    required this.network,
    required this.onBack,
    required this.onReplan,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppPageHeader(
          title: 'Saved Journeys',
          subtitle: 'Reuse or remove your favourite journeys',
          onBack: onBack,
        ),
        Expanded(
          child: ColoredBox(
            color: AppColors.background,
            child: ListenableBuilder(
              listenable: controller,
              builder: (context, _) => RefreshIndicator(
                onRefresh: () => controller.load(userId),
                child: _body(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    if (controller.isLoading && controller.favorites.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 220),
          Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ],
      );
    }
    if (controller.errorMessage != null && controller.favorites.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        children: [
          const SizedBox(height: AppSpacing.xxl4),
          _MessageCard(
            icon: Icons.error_outline_rounded,
            title: 'Saved journeys could not be loaded',
            body: controller.errorMessage!,
            actionLabel: 'Retry',
            onAction: () => controller.load(userId),
          ),
        ],
      );
    }
    if (controller.favorites.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        children: const [
          SizedBox(height: AppSpacing.xxl4),
          _MessageCard(
            icon: Icons.bookmark_border_rounded,
            title: 'No saved journeys yet',
            body: 'Save a route from Route Details to see it here.',
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.sectionLg,
        AppSpacing.pageHorizontal,
        AppSpacing.pageBottom,
      ),
      itemCount: controller.favorites.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.gapMd),
      itemBuilder: (context, index) {
        final favorite = controller.favorites[index];
        return _SavedJourneyCard(
          favorite: favorite,
          network: network,
          disabled: controller.isSaving,
          onOpen: () =>
              onReplan(favorite.originStopId, favorite.destinationStopId),
          onDelete: () => _delete(context, favorite),
        );
      },
    );
  }

  Future<void> _delete(BuildContext context, FavoriteJourney favorite) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove saved journey?'),
        content: Text('Remove ${favorite.label} from your saved journeys?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm_remove_saved_journey'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await controller.removeFavorite(favorite);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Saved journey removed.'
              : controller.errorMessage ??
                    'Saved journey could not be removed.',
        ),
      ),
    );
  }
}

class _SavedJourneyCard extends StatelessWidget {
  final FavoriteJourney favorite;
  final TransitNetwork? network;
  final bool disabled;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _SavedJourneyCard({
    required this.favorite,
    required this.network,
    required this.disabled,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final origin = network?.stopsById[favorite.originStopId];
    final destination = network?.stopsById[favorite.destinationStopId];
    final originName = TransitPresentation.formatStopName(
      origin?.name ?? favorite.originStopId,
    );
    final destinationName = TransitPresentation.formatStopName(
      destination?.name ?? favorite.destinationStopId,
    );
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        key: Key('saved_journey_${favorite.id}'),
        onTap: disabled ? null : onOpen,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.primary,
                child: Icon(Icons.alt_route_rounded),
              ),
              const SizedBox(width: AppSpacing.gapXl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(favorite.label, style: AppTypography.bodyLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$originName to $destinationName',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      favorite.objective.label,
                      style: AppTypography.captionBold.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: Key('remove_saved_journey_${favorite.id}'),
                tooltip: 'Remove saved journey',
                onPressed: disabled ? null : onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageCard({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.cardPadding),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.border),
      boxShadow: AppShadows.card,
    ),
    child: Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: AppSpacing.xxl4),
        const SizedBox(height: AppSpacing.gapMd),
        Text(title, style: AppTypography.bodyLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          body,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.gapMd),
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    ),
  );
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/transit_presentation.dart';
import '../../../shared/models/transit_models.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/journey_rail.dart';
import '../../../shared/widgets/mode_rail.dart';
import '../../user_management/application/saved_journey_controller.dart';
import '../application/planner_controller.dart';

class PlannerScreen extends StatefulWidget {
  final PlannerController controller;
  final SavedJourneyController savedJourneys;
  final String userId;
  final bool locationEnabled;
  final VoidCallback onRoutesReady;

  const PlannerScreen({
    super.key,
    required this.controller,
    required this.savedJourneys,
    required this.userId,
    required this.locationEnabled,
    required this.onRoutesReady,
  });

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.controller, widget.savedJourneys]),
      builder: (context, _) {
        final controller = widget.controller;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              const AppPageHeader(
                title: 'Plan journey',
                subtitle: 'Official Klang Valley transit network',
              ),
              Expanded(
                child: controller.isLoading && controller.network == null
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: controller.load,
                        color: AppColors.primary,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.pageHorizontal,
                            AppSpacing.sectionLg,
                            AppSpacing.pageHorizontal,
                            AppSpacing.pageBottom,
                          ),
                          children: [
                            // Spatial Journey Composer Rail
                            JourneyComposerRail(
                              origin: controller.origin,
                              destination: controller.destination,
                              onOriginTap: () => _chooseStop(true),
                              onDestinationTap: () => _chooseStop(false),
                              onSwap: controller.swapStops,
                              onLocation: _useLocation,
                              isLocating: controller.isLocating,
                            ),

                            // Quick Start Suggestions (from saved favorites / recents)
                            if (widget.savedJourneys.favorites.isNotEmpty ||
                                widget.savedJourneys.recentSearches.isNotEmpty)
                              _buildQuickStartSection(controller),

                            const SizedBox(height: AppSpacing.sectionXl),

                            // Transport Modes Rail
                            Text(
                              'TRANSPORT MODES',
                              style: AppTypography.captionBlack.copyWith(
                                color: AppColors.textSecondary,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.gapMd),
                            ModeRail(
                              selectedModes: controller.allowedModes,
                              onToggleMode: (mode) {
                                final currentlySelected = controller
                                    .allowedModes
                                    .contains(mode);
                                controller.setModeEnabled(
                                  mode,
                                  !currentlySelected,
                                );
                              },
                            ),

                            if (controller.errorMessage != null) ...[
                              const SizedBox(height: AppSpacing.sectionLg),
                              _PlannerErrorMessage(
                                message: controller.errorMessage!,
                              ),
                            ],

                            const SizedBox(height: AppSpacing.sectionXl),

                            // Primary Action Button
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed:
                                    controller.canPlan && !controller.isLoading
                                    ? _plan
                                    : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: AppColors.primary
                                      .withValues(alpha: 0.35),
                                  disabledForegroundColor: Colors.white
                                      .withValues(alpha: 0.6),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.buttonVertical,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                  elevation: 0,
                                ),
                                icon: controller.isLoading
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.alt_route_rounded,
                                        size: 20,
                                      ),
                                label: Text(
                                  controller.isLoading
                                      ? 'Finding routes…'
                                      : 'Compare SmartRoute options',
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.sectionLg),

                            // Truth & Routing Credibility Affordance
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.verified_outlined,
                                  size: 14,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  'Official Malaysian GTFS · SmartRoute routing',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.captionMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStartSection(PlannerController controller) {
    final network = controller.network;
    final favorites = widget.savedJourneys.favorites.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sectionLg),
        Text(
          'QUICK START',
          style: AppTypography.captionBlack.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.gapSm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final fav in favorites) ...[
                ActionChip(
                  avatar: const Icon(
                    Icons.favorite_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    fav.label,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  backgroundColor: AppColors.surface,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.circular),
                  ),
                  onPressed: () {
                    final origin = network?.stopsById[fav.originStopId];
                    final dest = network?.stopsById[fav.destinationStopId];
                    if (origin != null) controller.selectOrigin(origin);
                    if (dest != null) controller.selectDestination(dest);
                  },
                ),
                const SizedBox(width: AppSpacing.gapSm),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _plan() async {
    final success = await widget.controller.plan(
      userId: widget.userId,
      savedJourneys: widget.savedJourneys,
    );
    if (success && mounted) widget.onRoutesReady();
  }

  Future<void> _useLocation() async {
    await widget.controller.useCurrentLocation(
      preferenceEnabled: widget.locationEnabled,
    );
  }

  Future<void> _chooseStop(bool origin) async {
    final selected = await showModalBottomSheet<TransitStop>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) => _StopPicker(
        controller: widget.controller,
        title: origin ? 'Select origin station or stop' : 'Select destination',
      ),
    );
    if (selected == null) return;
    origin
        ? widget.controller.selectOrigin(selected)
        : widget.controller.selectDestination(selected);
  }
}

class _StopPicker extends StatefulWidget {
  final PlannerController controller;
  final String title;

  const _StopPicker({required this.controller, required this.title});

  @override
  State<_StopPicker> createState() => _StopPickerState();
}

class _StopPickerState extends State<_StopPicker> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.controller.searchStops(_searchController.text);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.sectionLg,
        AppSpacing.pageHorizontal,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.sectionLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionMd),
          TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search 6,352 official stops',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textTertiary,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.sectionMd),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Text(
                      'No matching stops found.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.borderLight),
                    itemBuilder: (context, index) {
                      final stop = results[index];
                      final display = TransitPresentation.formatStopName(
                        stop.name,
                      );
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(AppSpacing.gapSm),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(
                            Icons.place_outlined,
                            size: 20,
                            color: AppColors.secondary,
                          ),
                        ),
                        title: Text(
                          display,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${stop.routeIds.length} served route${stop.routeIds.length == 1 ? '' : 's'} · ${stop.gtfsId}',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textTertiary,
                        ),
                        onTap: () => Navigator.of(context).pop(stop),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlannerErrorMessage extends StatelessWidget {
  final String message;

  const _PlannerErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.containerPadding),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.gapMd),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

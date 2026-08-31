import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/transit_models.dart';
import '../../../shared/widgets/app_page_header.dart';
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
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        return Column(
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
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.pageHorizontal,
                          AppSpacing.sectionLg,
                          AppSpacing.pageHorizontal,
                          AppSpacing.pageBottom,
                        ),
                        children: [
                          _JourneyFields(
                            origin: controller.origin,
                            destination: controller.destination,
                            onOrigin: () => _chooseStop(true),
                            onDestination: () => _chooseStop(false),
                            onSwap: controller.swapStops,
                            onLocation: _useLocation,
                            isLocating: controller.isLocating,
                          ),
                          const SizedBox(height: AppSpacing.sectionXl),
                          Text(
                            'TRANSPORT MODES',
                            style: AppTypography.captionBlack,
                          ),
                          const SizedBox(height: AppSpacing.gapMd),
                          Wrap(
                            spacing: AppSpacing.gapMd,
                            runSpacing: AppSpacing.gapMd,
                            children: [
                              for (final mode in TransitMode.values)
                                FilterChip(
                                  selected: controller.allowedModes.contains(
                                    mode,
                                  ),
                                  label: Text(mode.label),
                                  onSelected: (selected) =>
                                      controller.setModeEnabled(mode, selected),
                                  selectedColor: AppColors.primaryLight,
                                  checkmarkColor: AppColors.primary,
                                  side: BorderSide(
                                    color:
                                        controller.allowedModes.contains(mode)
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                            ],
                          ),
                          if (controller.errorMessage != null) ...[
                            const SizedBox(height: AppSpacing.sectionLg),
                            _MessageCard(message: controller.errorMessage!),
                          ],
                          const SizedBox(height: AppSpacing.sectionXl),
                          FilledButton.icon(
                            onPressed:
                                controller.canPlan && !controller.isLoading
                                ? _plan
                                : null,
                            icon: const Icon(Icons.alt_route_rounded),
                            label: Text(
                              controller.isLoading
                                  ? 'Finding routes…'
                                  : 'Compare SmartRoute options',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.gapMd),
                          Text(
                            'SmartRoute computes routes from official GTFS. Google Maps presents the result.',
                            textAlign: TextAlign.center,
                            style: AppTypography.captionMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        );
      },
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
      builder: (context) => _StopPicker(controller: widget.controller),
    );
    if (selected == null) return;
    origin
        ? widget.controller.selectOrigin(selected)
        : widget.controller.selectDestination(selected);
  }
}

class _JourneyFields extends StatelessWidget {
  final TransitStop? origin;
  final TransitStop? destination;
  final VoidCallback onOrigin;
  final VoidCallback onDestination;
  final VoidCallback onSwap;
  final VoidCallback onLocation;
  final bool isLocating;

  const _JourneyFields({
    required this.origin,
    required this.destination,
    required this.onOrigin,
    required this.onDestination,
    required this.onSwap,
    required this.onLocation,
    required this.isLocating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          _StopButton(
            icon: Icons.trip_origin_rounded,
            label: 'FROM',
            value: origin?.name ?? 'Choose origin stop or station',
            onTap: onOrigin,
          ),
          const Divider(height: AppSpacing.sectionXl),
          _StopButton(
            icon: Icons.location_on_rounded,
            label: 'TO',
            value: destination?.name ?? 'Choose destination',
            onTap: onDestination,
          ),
          const SizedBox(height: AppSpacing.sectionLg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLocating ? null : onLocation,
                  icon: isLocating
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                  label: const Text('Nearby origin'),
                ),
              ),
              const SizedBox(width: AppSpacing.gapMd),
              IconButton.filledTonal(
                tooltip: 'Swap origin and destination',
                onPressed: onSwap,
                icon: const Icon(Icons.swap_vert_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _StopButton({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.gapSm),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppSpacing.gapXl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.captionBlack),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _StopPicker extends StatefulWidget {
  final PlannerController controller;

  const _StopPicker({required this.controller});

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
        children: [
          Text('Select a stop or station', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sectionLg),
          TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Search 6,352 official stops',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.gapMd),
          Expanded(
            child: results.isEmpty
                ? const Center(child: Text('No matching stops found.'))
                : ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final stop = results[index];
                      return ListTile(
                        title: Text(stop.name),
                        subtitle: Text(
                          '${stop.routeIds.length} served route${stop.routeIds.length == 1 ? '' : 's'}',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
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

class _MessageCard extends StatelessWidget {
  final String message;

  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.containerPadding),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary),
          const SizedBox(width: AppSpacing.gapMd),
          Expanded(child: Text(message, style: AppTypography.bodySmall)),
        ],
      ),
    );
  }
}

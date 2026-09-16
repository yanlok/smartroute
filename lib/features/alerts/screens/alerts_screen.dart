import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/notice_models.dart';
import '../../../shared/models/transit_models.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../transit_network/application/transit_network_controller.dart';
import '../application/notice_controller.dart';

class AlertsScreen extends StatefulWidget {
  final NoticeController controller;
  final TransitNetworkController transitController;
  final bool notificationsEnabled;
  final ValueChanged<String> onOpenRoute;

  const AlertsScreen({
    super.key,
    required this.controller,
    required this.transitController,
    required this.notificationsEnabled,
    required this.onOpenRoute,
  });

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  NoticeCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.controller,
        widget.transitController,
      ]),
      builder: (context, _) {
        final network = widget.transitController.network;
        return Column(
          children: [
            AppPageHeader(
              title: 'Alerts',
              subtitle: 'All active transit service notices',
              action: widget.controller.unreadCount > 0
                  ? _UnreadBadge(count: widget.controller.unreadCount)
                  : null,
            ),
            _CategoryFilters(
              selected: _selectedCategory,
              onSelected: (category) {
                setState(() => _selectedCategory = category);
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: widget.controller.reload,
                child: _ServiceNoticesList(
                  controller: widget.controller,
                  network: network,
                  notificationsEnabled: widget.notificationsEnabled,
                  category: _selectedCategory,
                  onOpenNotice: _openNotice,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openNotice(ServiceNotice notice) async {
    await widget.controller.markRead(notice);
    if (!mounted) return;
    final route = widget.transitController.network?.routesById[notice.routeId];
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) => SingleChildScrollView(
        child: _ServiceNoticeSheet(
          notice: notice,
          route: route,
          onViewRoute: () {
            Navigator.of(sheetContext).pop();
            widget.onOpenRoute(notice.routeId);
          },
        ),
      ),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  final NoticeCategory? selected;
  final ValueChanged<NoticeCategory?> onSelected;

  const _CategoryFilters({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.pageHorizontal,
      AppSpacing.sectionMd,
      AppSpacing.pageHorizontal,
      AppSpacing.gapSm,
    ),
    child: Row(
      children: [
        _FilterChip(
          label: 'All',
          selected: selected == null,
          onSelected: () => onSelected(null),
        ),
        for (final category in NoticeCategory.values) ...[
          const SizedBox(width: AppSpacing.gapSm),
          _FilterChip(
            label: _categoryFilterLabel(category),
            selected: selected == category,
            onSelected: () => onSelected(category),
          ),
        ],
      ],
    ),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onSelected(),
    selectedColor: AppColors.primary,
    backgroundColor: AppColors.surface,
    side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
    labelStyle: AppTypography.labelMedium.copyWith(
      color: selected ? AppColors.surface : AppColors.textSecondary,
    ),
    showCheckmark: false,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.circular),
    ),
  );
}

class _ServiceNoticesList extends StatelessWidget {
  final NoticeController controller;
  final TransitNetwork? network;
  final bool notificationsEnabled;
  final NoticeCategory? category;
  final ValueChanged<ServiceNotice> onOpenNotice;

  const _ServiceNoticesList({
    required this.controller,
    required this.network,
    required this.notificationsEnabled,
    required this.category,
    required this.onOpenNotice,
  });

  @override
  Widget build(BuildContext context) {
    final notices = controller.activeNotices
        .where((notice) => category == null || notice.category == category)
        .toList();
    final favorites = notices.where(controller.isFavoriteNotice).toList();
    final active = notices
        .where((notice) => !controller.isFavoriteNotice(notice))
        .toList();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageHorizontal,
        AppSpacing.sectionLg,
        AppSpacing.pageHorizontal,
        AppSpacing.pageBottom,
      ),
      children: [
        if (!notificationsEnabled)
          const _StateMessage(
            icon: Icons.notifications_off_outlined,
            title: 'In-app alerts are paused',
            body:
                'Enable notifications in Profile to see relevant route notices.',
          )
        else if (controller.isLoading)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xxl4),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (controller.errorMessage != null)
          _StateMessage(
            icon: Icons.cloud_off_rounded,
            title: 'Service notices could not be refreshed',
            body: controller.errorMessage!,
          )
        else if (notices.isEmpty)
          _StateMessage(
            icon: Icons.notifications_none_rounded,
            title: category == null
                ? 'No active service notices'
                : 'No active ${_categoryFilterLabel(category!).toLowerCase()} notices',
            body: 'Pull down to check for the latest transit updates.',
          )
        else ...[
          if (favorites.isNotEmpty) ...[
            const _SectionLabel(title: 'RELEVANT TO YOUR FAVOURITES'),
            for (final notice in favorites) ...[
              _NoticeCard(
                notice: notice,
                route: network?.routesById[notice.routeId],
                isRead: controller.isRead(notice),
                onTap: () => onOpenNotice(notice),
              ),
              const SizedBox(height: AppSpacing.gapXl),
            ],
          ],
          if (active.isNotEmpty) ...[
            const _SectionLabel(title: 'ACTIVE ALERTS'),
            for (final notice in active) ...[
              _NoticeCard(
                notice: notice,
                route: network?.routesById[notice.routeId],
                isRead: controller.isRead(notice),
                onTap: () => onOpenNotice(notice),
              ),
              const SizedBox(height: AppSpacing.gapXl),
            ],
          ],
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      top: AppSpacing.gapSm,
      bottom: AppSpacing.gapMd,
    ),
    child: Text(
      title,
      style: AppTypography.labelMedium.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _NoticeCard extends StatelessWidget {
  final ServiceNotice notice;
  final TransitRoute? route;
  final bool isRead;
  final VoidCallback onTap;

  const _NoticeCard({
    required this.notice,
    required this.route,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _noticeColors(notice.severity);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: isRead ? AppColors.borderLight : colors.$2),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.iconContainerSmall),
              decoration: BoxDecoration(
                color: colors.$1,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(_categoryIcon(notice.category), color: colors.$2),
            ),
            const SizedBox(width: AppSpacing.gapXl),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _categoryLabel(notice.category),
                          style: AppTypography.labelLarge.copyWith(
                            color: colors.$2,
                          ),
                        ),
                      ),
                      if (!isRead) ...[
                        const CircleAvatar(
                          radius: 4,
                          backgroundColor: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'New',
                          style: AppTypography.captionBold.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ] else
                        Text(
                          'Read',
                          style: AppTypography.captionMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    route?.displayName ?? notice.routeId,
                    style: AppTypography.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.gapSm),
                  Text(
                    notice.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gapMd),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_severityLabel(notice.severity)} severity · ${_relativeNoticeTime(notice)}',
                          style: AppTypography.captionBold.copyWith(
                            color: colors.$2,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textTertiary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceNoticeSheet extends StatelessWidget {
  final ServiceNotice notice;
  final TransitRoute? route;
  final VoidCallback onViewRoute;

  const _ServiceNoticeSheet({
    required this.notice,
    required this.route,
    required this.onViewRoute,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _noticeColors(notice.severity);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl2,
        AppSpacing.xxl2,
        AppSpacing.xxl2,
        AppSpacing.pageBottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.circular),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sectionLg),
          Text('SERVICE NOTICE', style: AppTypography.labelMedium),
          const SizedBox(height: AppSpacing.gapMd),
          Row(
            children: [
              Icon(_categoryIcon(notice.category), color: colors.$2),
              const SizedBox(width: AppSpacing.gapSm),
              _StatusChip(
                color: colors.$2,
                label: _categoryLabel(notice.category),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionLg),
          Text(notice.title, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.gapMd),
          Text(notice.body, style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.sectionLg),
          _NoticeDetailRow(
            label: 'Affected Route',
            value: route?.displayName ?? notice.routeId,
          ),
          _NoticeDetailRow(
            label: 'Severity',
            value: _severityLabel(notice.severity),
          ),
          _NoticeDetailRow(
            label: 'Active Period',
            value:
                '${_formatDateTime(context, notice.startsAt)} – ${notice.endsAt == null ? 'Until further notice' : _formatDateTime(context, notice.endsAt!)}',
          ),
          const _NoticeDetailRow(label: 'Status', value: 'ACTIVE'),
          const SizedBox(height: AppSpacing.sectionLg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onViewRoute,
              icon: const Icon(Icons.route_rounded),
              label: const Text('View Route'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _NoticeDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.gapMd),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.gapSm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.circular),
    ),
    child: Text(label, style: AppTypography.captionBold.copyWith(color: color)),
  );
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.gapMd,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.circular),
    ),
    child: Text(
      '$count new',
      style: AppTypography.captionBold.copyWith(color: AppColors.surface),
    ),
  );
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _StateMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl4),
    child: Column(
      children: [
        Icon(icon, size: 42, color: AppColors.textTertiary),
        const SizedBox(height: AppSpacing.sectionLg),
        Text(title, style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.gapMd),
        Text(
          body,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

(Color, Color) _noticeColors(NoticeSeverity severity) => switch (severity) {
  NoticeSeverity.info => (
    AppColors.severityInfoBg,
    AppColors.severityInfoColor,
  ),
  NoticeSeverity.warning => (
    AppColors.severityWarningBg,
    AppColors.severityWarningColor,
  ),
  NoticeSeverity.severe => (
    AppColors.severityCriticalBg,
    AppColors.severityCriticalColor,
  ),
};

IconData _categoryIcon(NoticeCategory category) => switch (category) {
  NoticeCategory.delay => Icons.warning_amber_rounded,
  NoticeCategory.maintenance => Icons.build_rounded,
  NoticeCategory.service => Icons.info_outline_rounded,
};

String _categoryLabel(NoticeCategory category) => switch (category) {
  NoticeCategory.delay => 'Delay',
  NoticeCategory.maintenance => 'Maintenance',
  NoticeCategory.service => 'Service Announcement',
};

String _categoryFilterLabel(NoticeCategory category) => switch (category) {
  NoticeCategory.delay => 'Delay',
  NoticeCategory.maintenance => 'Maintenance',
  NoticeCategory.service => 'Service',
};

String _severityLabel(NoticeSeverity severity) => switch (severity) {
  NoticeSeverity.info => 'Low',
  NoticeSeverity.warning => 'Medium',
  NoticeSeverity.severe => 'High',
};

String _relativeNoticeTime(ServiceNotice notice) {
  final difference = DateTime.now().difference(notice.updatedAt);
  if (difference.isNegative || difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
  if (difference.inHours < 24) return '${difference.inHours} hr ago';
  if (difference.inDays == 1) return 'Yesterday';
  return '${difference.inDays} days ago';
}

String _formatDateTime(BuildContext context, DateTime time) {
  final local = time.toLocal();
  final date = MaterialLocalizations.of(context).formatMediumDate(local);
  final clock = TimeOfDay.fromDateTime(local).format(context);
  return '$date, $clock';
}

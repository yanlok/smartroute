import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/transit_presentation.dart';
import '../../../shared/models/arrival_reminder.dart';
import '../../../shared/models/notice_models.dart';
import '../../../shared/models/transit_models.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../transit_network/application/transit_network_controller.dart';
import '../application/arrival_reminder_controller.dart';
import '../application/notice_controller.dart';

enum _AlertsTab { serviceNotices, arrivalReminders }

class AlertsScreen extends StatefulWidget {
  final NoticeController controller;
  final ArrivalReminderController reminders;
  final TransitNetworkController transitController;
  final bool notificationsEnabled;
  final ValueChanged<String> onOpenRoute;
  final ValueChanged<String> onOpenStation;

  const AlertsScreen({
    super.key,
    required this.controller,
    required this.reminders,
    required this.transitController,
    required this.notificationsEnabled,
    required this.onOpenRoute,
    required this.onOpenStation,
  });

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  _AlertsTab _selectedTab = _AlertsTab.serviceNotices;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.controller,
        widget.reminders,
        widget.transitController,
      ]),
      builder: (context, _) {
        final network = widget.transitController.network;
        return Column(
          children: [
            AppPageHeader(
              title: 'Alerts',
              subtitle: _selectedTab == _AlertsTab.serviceNotices
                  ? 'Notices for routes you follow or save'
                  : 'Scheduled reminders for station arrivals',
              action:
                  _selectedTab == _AlertsTab.serviceNotices &&
                      widget.controller.unreadCount > 0
                  ? _UnreadBadge(count: widget.controller.unreadCount)
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.sectionMd,
                AppSpacing.pageHorizontal,
                AppSpacing.gapSm,
              ),
              child: _AlertsTabs(
                selected: _selectedTab,
                onSelected: (tab) => setState(() => _selectedTab = tab),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => Future.wait([
                  widget.controller.reload(),
                  widget.reminders.reload(),
                ]),
                child: _selectedTab == _AlertsTab.serviceNotices
                    ? _ServiceNoticesList(
                        controller: widget.controller,
                        network: network,
                        notificationsEnabled: widget.notificationsEnabled,
                        onOpenNotice: _openNotice,
                      )
                    : _ArrivalRemindersList(
                        controller: widget.reminders,
                        network: network,
                        onOpenStation: widget.onOpenStation,
                        onDisable: _disableReminder,
                        onDelete: _deleteReminder,
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

  Future<void> _disableReminder(ArrivalReminder reminder) async {
    final success = await widget.reminders.disable(reminder);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Arrival reminder disabled.'
              : (widget.reminders.errorMessage ??
                    'Arrival reminder could not be disabled.'),
        ),
      ),
    );
  }

  Future<void> _deleteReminder(ArrivalReminder reminder) async {
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete arrival reminder?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (delete != true) return;
    final success = await widget.reminders.delete(reminder);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Arrival reminder deleted.'
              : (widget.reminders.errorMessage ??
                    'Arrival reminder could not be deleted.'),
        ),
      ),
    );
  }
}

class _AlertsTabs extends StatelessWidget {
  final _AlertsTab selected;
  final ValueChanged<_AlertsTab> onSelected;

  const _AlertsTabs({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.xs),
    decoration: BoxDecoration(
      color: AppColors.mutedBg,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        _AlertTabButton(
          label: 'Service Notices',
          icon: Icons.campaign_outlined,
          selected: selected == _AlertsTab.serviceNotices,
          onTap: () => onSelected(_AlertsTab.serviceNotices),
        ),
        const SizedBox(width: AppSpacing.xs),
        _AlertTabButton(
          label: 'Arrival Reminders',
          icon: Icons.alarm_outlined,
          selected: selected == _AlertsTab.arrivalReminders,
          onTap: () => onSelected(_AlertsTab.arrivalReminders),
        ),
      ],
    ),
  );
}

class _AlertTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AlertTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: selected ? AppColors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.gapSm,
            horizontal: AppSpacing.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMedium.copyWith(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ServiceNoticesList extends StatelessWidget {
  final NoticeController controller;
  final TransitNetwork? network;
  final bool notificationsEnabled;
  final ValueChanged<ServiceNotice> onOpenNotice;

  const _ServiceNoticesList({
    required this.controller,
    required this.network,
    required this.notificationsEnabled,
    required this.onOpenNotice,
  });

  @override
  Widget build(BuildContext context) {
    final notices = controller.relevantNotices;
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
          const _StateMessage(
            icon: Icons.notifications_none_rounded,
            title: 'No active notices for your journeys',
            body:
                'Follow a line in Transit or save a journey to personalize alerts.',
          )
        else
          for (final notice in notices) ...[
            _NoticeCard(
              notice: notice,
              route: network?.routesById[notice.routeId],
              isRead: controller.isRead(notice),
              onTap: () => onOpenNotice(notice),
            ),
            const SizedBox(height: AppSpacing.gapXl),
          ],
      ],
    );
  }
}

class _ArrivalRemindersList extends StatelessWidget {
  final ArrivalReminderController controller;
  final TransitNetwork? network;
  final ValueChanged<String> onOpenStation;
  final ValueChanged<ArrivalReminder> onDisable;
  final ValueChanged<ArrivalReminder> onDelete;

  const _ArrivalRemindersList({
    required this.controller,
    required this.network,
    required this.onOpenStation,
    required this.onDisable,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.pageHorizontal,
      AppSpacing.sectionLg,
      AppSpacing.pageHorizontal,
      AppSpacing.pageBottom,
    ),
    children: [
      if (controller.isLoading)
        const Padding(
          padding: EdgeInsets.all(AppSpacing.xxl4),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        )
      else if (controller.errorMessage != null)
        _StateMessage(
          icon: Icons.cloud_off_rounded,
          title: 'Arrival reminders could not be refreshed',
          body: controller.errorMessage!,
        )
      else if (controller.reminders.isEmpty)
        const _StateMessage(
          icon: Icons.alarm_add_outlined,
          title: 'No arrival reminders yet',
          body: 'Open a station in Transit Information and tap Remind Me.',
        )
      else
        for (final reminder in controller.reminders) ...[
          _ArrivalReminderCard(
            reminder: reminder,
            station: network?.stopsById[reminder.stationId],
            route: network?.routesById[reminder.routeId],
            onOpenStation: () => onOpenStation(reminder.stationId),
            onDisable: () => onDisable(reminder),
            onDelete: () => onDelete(reminder),
          ),
          const SizedBox(height: AppSpacing.gapXl),
        ],
    ],
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
              child: Icon(Icons.campaign_rounded, color: colors.$2),
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
                          notice.title,
                          style: AppTypography.bodyLarge,
                        ),
                      ),
                      if (!isRead)
                        const CircleAvatar(
                          radius: 4,
                          backgroundColor: AppColors.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${notice.source == NoticeSource.official ? 'OFFICIAL' : 'SMARTROUTE NOTICE'} · ${route?.displayName ?? notice.routeId}',
                    style: AppTypography.captionBold.copyWith(color: colors.$2),
                  ),
                  const SizedBox(height: AppSpacing.gapMd),
                  Text(
                    notice.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
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

class _ArrivalReminderCard extends StatelessWidget {
  final ArrivalReminder reminder;
  final TransitStop? station;
  final TransitRoute? route;
  final VoidCallback onOpenStation;
  final VoidCallback onDisable;
  final VoidCallback onDelete;

  const _ArrivalReminderCard({
    required this.reminder,
    required this.station,
    required this.route,
    required this.onOpenStation,
    required this.onDisable,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = reminder.statusAt(DateTime.now());
    final color = _reminderStatusColor(status);
    final routeColor = route == null
        ? AppColors.primary
        : TransitPresentation.routeColor(route!);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.iconContainerSmall),
                decoration: BoxDecoration(
                  color: routeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.alarm_rounded, color: routeColor),
              ),
              const SizedBox(width: AppSpacing.gapMd),
              Expanded(
                child: Text(
                  station == null
                      ? reminder.stationId
                      : TransitPresentation.formatStopName(station!.name),
                  style: AppTypography.bodyLarge,
                ),
              ),
              _StatusChip(status: status, color: color),
            ],
          ),
          const SizedBox(height: AppSpacing.gapMd),
          Text(
            route?.displayName ?? reminder.routeId,
            style: AppTypography.labelLarge.copyWith(color: routeColor),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Expected ${_formatDateTime(context, reminder.expectedArrival)} · ${reminder.leadTimeMinutes} min before',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (reminder.isDemo) ...[
            const SizedBox(height: AppSpacing.gapSm),
            Text(
              'DEMO ARRIVAL NOTIFICATION',
              style: AppTypography.captionBold.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sectionLg),
          Wrap(
            spacing: AppSpacing.gapSm,
            runSpacing: AppSpacing.gapSm,
            children: [
              OutlinedButton(
                onPressed: onOpenStation,
                child: const Text('View Station Details'),
              ),
              if (status != ArrivalReminderStatus.disabled &&
                  status != ArrivalReminderStatus.expired)
                TextButton(onPressed: onDisable, child: const Text('Disable')),
              TextButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
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
    final delayLabel = switch (notice.severity) {
      NoticeSeverity.info => null,
      NoticeSeverity.warning => 'Delays possible',
      NoticeSeverity.severe => 'Major delay or disruption',
    };
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
          _StatusChip(
            status: null,
            color: colors.$2,
            label: notice.severity.name,
          ),
          const SizedBox(height: AppSpacing.gapMd),
          Text(notice.title, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.gapMd),
          Text(notice.body, style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.sectionLg),
          _NoticeDetailRow(
            icon: Icons.route_outlined,
            label: 'Affected route',
            value: route?.displayName ?? notice.routeId,
          ),
          _NoticeDetailRow(
            icon: Icons.schedule_outlined,
            label: 'Active period',
            value:
                '${_formatDateTime(context, notice.startsAt)} – ${notice.endsAt == null ? 'Until further notice' : _formatDateTime(context, notice.endsAt!)}',
          ),
          if (delayLabel != null)
            _NoticeDetailRow(
              icon: Icons.timer_outlined,
              label: 'Delay status',
              value: delayLabel,
            ),
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
  final IconData icon;
  final String label;
  final String value;

  const _NoticeDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.gapMd),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.gapMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.labelMedium),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  final ArrivalReminderStatus? status;
  final Color color;
  final String? label;

  const _StatusChip({required this.status, required this.color, this.label});

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
    child: Text(
      label ?? status!.name.toUpperCase(),
      style: AppTypography.captionBold.copyWith(color: color),
    ),
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

Color _reminderStatusColor(ArrivalReminderStatus status) => switch (status) {
  ArrivalReminderStatus.active => AppColors.primary,
  ArrivalReminderStatus.triggered => AppColors.secondary,
  ArrivalReminderStatus.expired => AppColors.textSecondary,
  ArrivalReminderStatus.disabled => AppColors.textTertiary,
};

String _formatDateTime(BuildContext context, DateTime time) {
  final local = time.toLocal();
  final date = MaterialLocalizations.of(context).formatMediumDate(local);
  final clock = TimeOfDay.fromDateTime(local).format(context);
  return '$date, $clock';
}

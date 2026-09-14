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

class AlertsScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, transitController]),
      builder: (context, _) {
        final network = transitController.network;
        final notices = controller.relevantNotices;
        return Column(
          children: [
            AppPageHeader(
              title: 'Alerts',
              subtitle: 'Notices for routes you follow or save',
              action: controller.unreadCount == 0
                  ? null
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.gapMd,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.circular),
                      ),
                      child: Text(
                        '${controller.unreadCount} new',
                        style: AppTypography.captionBold.copyWith(
                          color: AppColors.surface,
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.reload,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.pageHorizontal,
                    AppSpacing.sectionLg,
                    AppSpacing.pageHorizontal,
                    AppSpacing.pageBottom,
                  ),
                  children: [
                    if (!notificationsEnabled)
                      const _PreferenceMessage()
                    else if (controller.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl4),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else if (controller.errorMessage != null)
                      _ErrorMessage(message: controller.errorMessage!)
                    else if (notices.isEmpty)
                      const _EmptyAlerts()
                    else
                      for (final notice in notices) ...[
                        _NoticeCard(
                          notice: notice,
                          route: network?.routesById[notice.routeId],
                          isRead: controller.isRead(notice),
                          onTap: () async {
                            await controller.markRead(notice);
                            onOpenRoute(notice.routeId);
                          },
                        ),
                        const SizedBox(height: AppSpacing.gapXl),
                      ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
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
    final colors = switch (notice.severity) {
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

class _PreferenceMessage extends StatelessWidget {
  const _PreferenceMessage();

  @override
  Widget build(BuildContext context) => const _StateMessage(
    icon: Icons.notifications_off_outlined,
    title: 'In-app alerts are paused',
    body: 'Enable notifications in Profile to see relevant route notices.',
  );
}

class _EmptyAlerts extends StatelessWidget {
  const _EmptyAlerts();

  @override
  Widget build(BuildContext context) => const _StateMessage(
    icon: Icons.notifications_none_rounded,
    title: 'No active notices for your journeys',
    body: 'Follow a line in Transit or save a journey to personalize alerts.',
  );
}

class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) => _StateMessage(
    icon: Icons.cloud_off_rounded,
    title: 'Alerts could not be refreshed',
    body: message,
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

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class AlertsScreen extends StatefulWidget {
  final VoidCallback onBack;
  const AlertsScreen({super.key, required this.onBack});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  _VehicleType _selectedVehicle = _VehicleType.all;
  late List<_TransitNotification> _notifications;
  bool _favouriteRouteAlerts = true;

  @override
  void initState() {
    super.initState();
    _notifications = List.of(_sampleNotifications);
  }

  List<_TransitNotification> get _visibleNotifications => _selectedVehicle == _VehicleType.all
      ? _notifications
      : _notifications.where((notification) => notification.vehicle == _selectedVehicle).toList();

  int get _unreadCount => _notifications.where((notification) => !notification.isRead).length;

  void _markRead(String id) {
    setState(() {
      _notifications = [
        for (final notification in _notifications)
          notification.id == id ? notification.copyWith(isRead: true) : notification,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _visibleNotifications;
    return Column(
      children: [
        _Header(onBack: widget.onBack, unreadCount: _unreadCount),
        _VehicleSelector(
          selectedVehicle: _selectedVehicle,
          onSelected: (vehicle) => setState(() => _selectedVehicle = vehicle),
        ),
        Expanded(
          child: Container(
            color: AppColors.background,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.sectionLg,
                AppSpacing.pageHorizontal,
                AppSpacing.pageBottom,
              ),
              children: [
                _FavouriteRoutePreference(
                  enabled: _favouriteRouteAlerts,
                  onChanged: (enabled) => setState(() => _favouriteRouteAlerts = enabled),
                ),
                const SizedBox(height: AppSpacing.sectionLg),
                Text(
                  _selectedVehicle == _VehicleType.all
                      ? 'ALL TRANSIT NOTIFICATIONS'
                      : '${_selectedVehicle.label.toUpperCase()} NOTIFICATIONS',
                  style: AppTypography.captionBlack,
                ),
                const SizedBox(height: AppSpacing.gapMd),
                if (notifications.isEmpty)
                  const _EmptyNotifications()
                else
                  for (final notification in notifications) ...[
                    _NotificationCard(notification: notification, onTap: () => _markRead(notification.id)),
                    const SizedBox(height: AppSpacing.gapXl),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final int unreadCount;
  const _Header({required this.onBack, required this.unreadCount});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: AppColors.surface, boxShadow: AppShadows.header),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, AppSpacing.pageHorizontal, AppSpacing.gapXl),
              child: Row(
                children: [
                  IconButton(tooltip: 'Back', onPressed: onBack, icon: const Icon(Icons.chevron_left_rounded)),
                  const SizedBox(width: AppSpacing.gapXs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transit notifications', style: AppTypography.titleMedium),
                        Text('Static prototype alerts', style: AppTypography.labelMedium),
                      ],
                    ),
                  ),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gapMd, vertical: AppSpacing.gapXs),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.circular)),
                      child: Text('$unreadCount new', style: AppTypography.captionBold.copyWith(color: AppColors.surface)),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _VehicleSelector extends StatelessWidget {
  final _VehicleType selectedVehicle;
  final ValueChanged<_VehicleType> onSelected;
  const _VehicleSelector({required this.selectedVehicle, required this.onSelected});

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surface,
        padding: const EdgeInsets.fromLTRB(AppSpacing.pageHorizontal, 0, AppSpacing.pageHorizontal, AppSpacing.gapXl),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final vehicle in _VehicleType.values) ...[
                _VehicleButton(
                  vehicle: vehicle,
                  isSelected: vehicle == selectedVehicle,
                  onPressed: () => onSelected(vehicle),
                ),
                const SizedBox(width: AppSpacing.gapSm),
              ],
            ],
          ),
        ),
      );
}

class _VehicleButton extends StatelessWidget {
  final _VehicleType vehicle;
  final bool isSelected;
  final VoidCallback onPressed;
  const _VehicleButton({required this.vehicle, required this.isSelected, required this.onPressed});

  @override
  Widget build(BuildContext context) => Semantics(
        selected: isSelected,
        button: true,
        label: '${vehicle.label} notifications',
        child: Material(
          color: isSelected ? AppColors.primary : AppColors.mutedBg,
          borderRadius: BorderRadius.circular(AppRadius.circular),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppRadius.circular),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gapXl, vertical: AppSpacing.gapSm),
              child: Row(
                children: [
                  Icon(vehicle.icon, size: 16, color: isSelected ? AppColors.surface : AppColors.mutedForeground),
                  const SizedBox(width: AppSpacing.gapXs),
                  Text(vehicle.label, style: AppTypography.labelSmallBold.copyWith(color: isSelected ? AppColors.surface : AppColors.mutedForeground)),
                ],
              ),
            ),
          ),
        ),
      );
}

class _FavouriteRoutePreference extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const _FavouriteRoutePreference({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            const Icon(Icons.bookmark_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: AppSpacing.gapMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Favourite route alerts', style: AppTypography.bodyLarge),
                  const SizedBox(height: AppSpacing.gapXs),
                  Text('Receive updates for saved routes.', style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            Switch(value: enabled, onChanged: onChanged),
          ],
        ),
      );
}

class _NotificationCard extends StatelessWidget {
  final _TransitNotification notification;
  final VoidCallback onTap;
  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final style = _NotificationStyle.fromPriority(notification.priority);
    return Semantics(
      button: true,
      label: '${notification.kind.label}: ${notification.title}',
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: notification.isRead ? AppColors.borderLight : style.color),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.iconContainerSmall),
                  decoration: BoxDecoration(color: style.background, borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Icon(notification.kind.icon, size: 18, color: style.color),
                ),
                const SizedBox(width: AppSpacing.gapMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(notification.vehicle.icon, size: 13, color: notification.vehicle.color),
                          const SizedBox(width: AppSpacing.gapXs),
                          Expanded(child: Text(notification.route, style: AppTypography.captionBold.copyWith(color: AppColors.textSecondary))),
                          Text(notification.time, style: AppTypography.captionMedium.copyWith(color: AppColors.textTertiary)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.gapSm),
                      Text(notification.title, style: AppTypography.bodyLarge),
                      const SizedBox(height: AppSpacing.gapXs),
                      Text(notification.description, style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary, height: 1.4)),
                    ],
                  ),
                ),
                if (!notification.isRead) ...[
                  const SizedBox(width: AppSpacing.gapSm),
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.gapXs),
                    child: Icon(Icons.circle, color: AppColors.primary, size: 8),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.sectionXxl),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Column(
          children: [
            const Icon(Icons.notifications_off_outlined, size: 32, color: AppColors.iconGray),
            const SizedBox(height: AppSpacing.gapMd),
            Text('No notifications for this service', style: AppTypography.bodyLarge),
          ],
        ),
      );
}

enum _VehicleType {
  all('All', Icons.apps_rounded, AppColors.iconDark),
  bus('Bus', Icons.directions_bus_rounded, AppColors.busLine),
  lrt('LRT', Icons.train_rounded, AppColors.kjLine),
  mrt('MRT', Icons.subway_rounded, AppColors.mkLine),
  monorail('Monorail', Icons.tram_rounded, AppColors.mlLine);

  final String label;
  final IconData icon;
  final Color color;
  const _VehicleType(this.label, this.icon, this.color);
}

enum _NotificationKind {
  serviceDisruption('Service disruption', Icons.report_problem_outlined),
  delay('Delay alert', Icons.schedule_rounded),
  routeChange('Route change', Icons.alt_route_rounded),
  maintenance('Maintenance', Icons.build_outlined),
  approaching('Bus approaching', Icons.directions_bus_rounded),
  stopReminder('Stop reminder', Icons.location_on_outlined),
  journeyReminder('Journey reminder', Icons.notifications_active_outlined),
  favouriteRoute('Favourite route alert', Icons.bookmark_outline_rounded),
  stopClosure('Stop closure', Icons.location_off_outlined);

  final String label;
  final IconData icon;
  const _NotificationKind(this.label, this.icon);
}

enum _NotificationPriority { information, warning, critical }

class _TransitNotification {
  final String id;
  final _VehicleType vehicle;
  final _NotificationKind kind;
  final _NotificationPriority priority;
  final String route;
  final String title;
  final String description;
  final String time;
  final bool isRead;
  const _TransitNotification({
    required this.id,
    required this.vehicle,
    required this.kind,
    required this.priority,
    required this.route,
    required this.title,
    required this.description,
    required this.time,
    this.isRead = false,
  });

  _TransitNotification copyWith({bool? isRead}) => _TransitNotification(
        id: id, vehicle: vehicle, kind: kind, priority: priority, route: route,
        title: title, description: description, time: time, isRead: isRead ?? this.isRead,
      );
}

class _NotificationStyle {
  final Color color;
  final Color background;
  const _NotificationStyle({required this.color, required this.background});
  factory _NotificationStyle.fromPriority(_NotificationPriority priority) {
    switch (priority) {
      case _NotificationPriority.information:
        return const _NotificationStyle(color: AppColors.severityInfoColor, background: AppColors.severityInfoBg);
      case _NotificationPriority.warning:
        return const _NotificationStyle(color: AppColors.severityWarningColor, background: AppColors.severityWarningBg);
      case _NotificationPriority.critical:
        return const _NotificationStyle(color: AppColors.severityCriticalColor, background: AppColors.severityCriticalBg);
    }
  }
}

const _sampleNotifications = [
  _TransitNotification(id: 'bus-arriving', vehicle: _VehicleType.bus, kind: _NotificationKind.approaching, priority: _NotificationPriority.information, route: 'Bus 400 · SS15', title: 'Bus arriving in 4 min', description: 'Board at SS15, Stop T142. Low-floor bus scheduled.', time: 'Now'),
  _TransitNotification(id: 'bus-route', vehicle: _VehicleType.bus, kind: _NotificationKind.routeChange, priority: _NotificationPriority.warning, route: 'Bus 400', title: 'Route diversion in effect', description: 'Service is using Jalan Kemajuan due to road works.', time: '8 min ago'),
  _TransitNotification(id: 'bus-closure', vehicle: _VehicleType.bus, kind: _NotificationKind.stopClosure, priority: _NotificationPriority.critical, route: 'Bus 400 · Stop T142', title: 'Stop temporarily closed', description: 'Use the temporary stop opposite Subang Parade.', time: '20 min ago'),
  _TransitNotification(id: 'lrt-disruption', vehicle: _VehicleType.lrt, kind: _NotificationKind.serviceDisruption, priority: _NotificationPriority.critical, route: 'Kelana Jaya Line · KJ 5', title: 'Service disruption cleared', description: 'Trains are resuming normal frequency between Bangsar and KL Sentral.', time: '12 min ago'),
  _TransitNotification(id: 'lrt-reminder', vehicle: _VehicleType.lrt, kind: _NotificationKind.stopReminder, priority: _NotificationPriority.information, route: 'Kelana Jaya Line · KJ 5', title: 'Your stop is next', description: 'Prepare to alight at KL Sentral. Exit E connects to the main concourse.', time: 'Now'),
  _TransitNotification(id: 'mrt-delay', vehicle: _VehicleType.mrt, kind: _NotificationKind.delay, priority: _NotificationPriority.warning, route: 'MRT Kajang Line', title: '5–8 minute delay', description: 'Services between Semantan and Tun Razak Exchange are running later than scheduled.', time: '10 min ago'),
  _TransitNotification(id: 'mrt-journey', vehicle: _VehicleType.mrt, kind: _NotificationKind.journeyReminder, priority: _NotificationPriority.information, route: 'MRT Putrajaya Line', title: 'Leave in 10 minutes', description: 'Your saved journey to KLCC is due to depart at 08:20.', time: 'Today'),
  _TransitNotification(id: 'mrt-favourite', vehicle: _VehicleType.mrt, kind: _NotificationKind.favouriteRoute, priority: _NotificationPriority.information, route: 'MRT Kajang Line', title: 'Favourite route is running normally', description: 'Your saved route from Cochrane to Muzium Negara is on time.', time: '1 hr ago', isRead: true),
  _TransitNotification(id: 'mono-maintenance', vehicle: _VehicleType.monorail, kind: _NotificationKind.maintenance, priority: _NotificationPriority.warning, route: 'KL Monorail', title: 'Scheduled maintenance tonight', description: 'Service will end early at 23:30 for planned track maintenance.', time: '2 hr ago', isRead: true),
];

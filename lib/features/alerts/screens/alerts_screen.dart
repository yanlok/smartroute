import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/constants/mock_data.dart';
import '../../../shared/models/app_models.dart';
import 'package:flutter/material.dart';

class AlertsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const AlertsScreen({super.key, required this.onBack});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  late List<AlertItem> _alerts;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _alerts = List.from(alertsData);
  }

  List<AlertItem> get _filtered {
    switch (_filter) {
      case 'unread':
        return _alerts.where((a) => !a.read).toList();
      case 'delays':
        return _alerts
            .where((a) =>
                a.severity == AlertSeverity.warning ||
                a.severity == AlertSeverity.critical)
            .toList();
      case 'info':
        return _alerts
            .where((a) => a.severity == AlertSeverity.info)
            .toList();
      default:
        return _alerts;
    }
  }

  int get _unreadCount => _alerts.where((a) => !a.read).length;

  void _markRead(String id) {
    setState(() {
      _alerts = _alerts
          .map((a) => a.id == id ? a.copyWith(read: true) : a)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _filtered;

    return Column(
      children: [
        // ── Header ──
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: AppShadows.header,
          ),
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).padding.top,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBack,
                      icon:
                          const Icon(Icons.chevron_left_rounded, size: 20),
                      color: AppColors.textSecondary,
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('Notifications',
                          style: AppTypography.titleMedium),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('$_unreadCount new',
                          style: AppTypography.captionBlack.copyWith(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              // Filter chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: ['all', 'unread', 'delays', 'info'].map((f) {
                    final active = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? AppColors.primary : AppColors.mutedBg,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                          ),
                          child: Text(
                            f[0].toUpperCase() + f.substring(1),
                            style: AppTypography.captionBold.copyWith(
                              color: active
                                  ? Colors.white
                                  : AppColors.mutedForeground,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // ── Alert List ──
        Expanded(
          child: Container(
            color: AppColors.background,
            child: visible.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final alert = visible[index];
                    final severityConfig = _severityConfig(alert.severity);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _markRead(alert.id),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                            border: Border(
                              left: !alert.read
                                  ? const BorderSide(
                                      color: AppColors.primary, width: 4)
                                  : BorderSide.none,
                              top: const BorderSide(
                                  color: AppColors.borderLight),
                              right: const BorderSide(
                                  color: AppColors.borderLight),
                              bottom: const BorderSide(
                                  color: AppColors.borderLight),
                            ),
                            boxShadow: AppShadows.card,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: severityConfig.bg,
                                  borderRadius: BorderRadius.circular(
                                      AppRadius.md),
                                ),
                                child: Icon(severityConfig.icon,
                                    size: 16, color: severityConfig.color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: Color(int.parse(
                                                '0xFF${alert.lineColor.replaceFirst('#', '')}')),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(alert.line,
                                            style: AppTypography.captionBold.copyWith(
                                                color: AppColors.textSecondary)),
                                        const Spacer(),
                                        Text(alert.time,
                                            style: AppTypography.captionMedium.copyWith(
                                                color: AppColors.iconGray)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(alert.title,
                                        style: AppTypography.bodyLarge),
                                    const SizedBox(height: 2),
                                    Text(alert.description,
                                        style: AppTypography.labelMedium.copyWith(
                                            color: AppColors.textSecondary,
                                            height: 1.4)),
                                  ],
                                ),
                              ),
                              if (!alert.read) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ),
      ],
    );
  }

  _SeverityConfig _severityConfig(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return _SeverityConfig(
          icon: Icons.info_outline_rounded,
          bg: AppColors.severityInfoBg,
          color: AppColors.severityInfoColor,
        );
      case AlertSeverity.warning:
        return _SeverityConfig(
          icon: Icons.warning_amber_rounded,
          bg: AppColors.severityWarningBg,
          color: AppColors.severityWarningColor,
        );
      case AlertSeverity.critical:
        return _SeverityConfig(
          icon: Icons.close_rounded,
          bg: AppColors.severityCriticalBg,
          color: AppColors.severityCriticalColor,
        );
    }
  }
}

class _SeverityConfig {
  final IconData icon;
  final Color bg;
  final Color color;
  const _SeverityConfig({
    required this.icon,
    required this.bg,
    required this.color,
  });
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 12),
          Text('No alerts here',
              style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          Text("You're all caught up!",
              style: AppTypography.labelMedium.copyWith(color: AppColors.iconGray)),
        ],
      ),
    );
  }
}

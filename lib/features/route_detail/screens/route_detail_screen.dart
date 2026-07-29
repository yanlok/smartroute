import '../../../core/constants/navigation_types.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class RouteDetailScreen extends StatelessWidget {
  final void Function(AppScreen) onNavigate;
  final VoidCallback onBack;

  const RouteDetailScreen({
    super.key,
    required this.onNavigate,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      color: AppColors.textSecondary,
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Route Details',
                              style: AppTypography.titleMedium),
                          Text('Fastest · 28 min · RM 2.50',
                              style: AppTypography.labelMedium),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.bookmark_border_rounded, size: 16),
                      color: AppColors.iconDark,
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.share_rounded, size: 16),
                      color: AppColors.iconDark,
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Body ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Summary banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: AppColors.gradientPrimary),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SummaryItem(label: 'Total Journey', value: '28 min'),
                          _SummaryItem(label: 'Total Fare', value: 'RM 2.50'),
                          _SummaryItem(label: 'Transfers', value: '1'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.only(top: 12),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                                color: AppColors.white20, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text('Departs ',
                                style: AppTypography.labelMedium.copyWith(color: AppColors.white65)),
                            Text('10:32 AM',
                                style: AppTypography.labelSmallBold.copyWith(color: Colors.white)),
                            Text(' · Arrives ',
                                style: AppTypography.labelMedium.copyWith(color: AppColors.white65)),
                            Text('11:00 AM',
                                style: AppTypography.labelSmallBold.copyWith(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Timeline
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STEP-BY-STEP JOURNEY',
                          style: AppTypography.captionBlack),
                      SizedBox(height: 16),

                      // Step 1: Walk
                      _TimelineStep(
                        icon: '🚶',
                        iconBgColor: Color(0xFFF9FAFB),
                        iconBorderColor: AppColors.divider,
                        title: 'Walk to Asia Jaya LRT',
                        time: '10:32 AM',
                        subtitle: '320m · about 4 min · Head north on Jalan SS 6/6',
                        connectorHeight: 40,
                      ),

                      // Step 2: Board LRT
                      _BoardTrainStep(),

                      // Step 3: Arrive
                      _TimelineStep(
                        icon: '📍',
                        iconBgColor: AppColors.secondary,
                        iconBorderColor: AppColors.secondary,
                        title: 'Arrive at Destination',
                        time: '11:00 AM',
                        timeColor: AppColors.secondary,
                        subtitle: '6 min walk (480m) from KL Sentral exit E',
                        showConnector: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onNavigate(AppScreen.tracking),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: AppColors.gradientPrimary),
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                            boxShadow: AppShadows.trackButton,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.sensors_rounded,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text('Track Live',
                                  style: AppTypography.bodyLarge),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.bookmark_border_rounded),
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.share_rounded),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: AppTypography.captionBold.copyWith(color: AppColors.white65)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTypography.monoLarge.copyWith(color: Colors.white)),
      ],
    );
  }
}

class _BoardTrainStep extends StatelessWidget {
  const _BoardTrainStep();

  @override
  Widget build(BuildContext context) {
    return _TimelineStep(
      icon: '🚆',
      iconBgColor: const Color(0xFF009FE3),
      iconWidget: const Icon(Icons.train_rounded,
          color: Colors.white, size: 16),
      title: 'Kelana Jaya Line',
      time: '10:36 AM',
      subtitle: 'Platform 1 · Towards Putra Heights',
      connectorHeight: 112,
      extra: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x08009FE3),
          borderRadius:
              BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: const Color(0x25009FE3)),
        ),
	        child: Column(
	          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text('Asia Jaya',
                    style: AppTypography.captionBold),
                Text('10:36',
                    style: AppTypography.labelMedium),
              ],
            ),
            SizedBox(height: 8),
            _StopRow(stop: 'Taman Paramount'),
            _StopRow(stop: 'Taman Jaya'),
            _StopRow(stop: 'Universiti'),
            _StopRow(stop: 'Bangsar'),
            SizedBox(height: 4),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text('KL Sentral',
                    style: AppTypography.captionBold),
                Text('10:54',
                    style: AppTypography.labelMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  final String stop;
  const _StopRow({required this.stop});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0x60009FE3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(stop,
              style: AppTypography.labelMedium),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String icon;
  final Color iconBgColor;
  final Color iconBorderColor;
  final Widget? iconWidget;
  final String title;
  final String time;
  final Color? timeColor;
  final String subtitle;
  final double? connectorHeight;
  final bool showConnector;
  final Widget? extra;

  const _TimelineStep({
    required this.icon,
    required this.iconBgColor,
    this.iconBorderColor = AppColors.divider,
    this.iconWidget,
    required this.title,
    required this.time,
    this.timeColor,
    required this.subtitle,
    this.connectorHeight,
    this.showConnector = true,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon column
        SizedBox(
          width: 36,
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: iconBorderColor, width: 2),
                ),
                child: Center(
                  child: iconWidget ?? Text(icon, style: const TextStyle(fontSize: 16)),
                ),
              ),
              if (showConnector)
                Container(
                  width: 2,
                  height: connectorHeight ?? 40,
                  color: iconBorderColor.withValues(alpha: 0.3),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title == 'Kelana Jaya Line') ...[
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF009FE3),
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                  child: Text('KJ',
                                      style: AppTypography.captionBold),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(title,
                                      style: AppTypography.bodyLarge),
                                ),
                              ],
                            ),
                          ] else
                            Text(title,
                                style: AppTypography.bodyLarge),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(time,
                        style: AppTypography.labelSmallBold.copyWith(
                          color: timeColor ?? AppColors.iconGray,
                        )),
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTypography.labelMedium),
                if (extra != null) extra!,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

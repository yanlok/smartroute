import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.onBack,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifications = true;
  bool _location = true;

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
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Profile',
                      style: AppTypography.titleMedium),
                ),
              ),
            ],
          ),
        ),

        // ── Body ──
        Expanded(
          child: Container(
            color: AppColors.background,
            child: SingleChildScrollView(
            child: Column(
              children: [
                // Profile card
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: AppColors.gradientProfile),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.white25,
                            borderRadius:
                                BorderRadius.circular(AppRadius.lg),
                          ),
                          child: const Center(
                            child: Text('YL',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Yih Loong',
                                  style: AppTypography.headlineSmall.copyWith(color: Colors.white)),
                              const SizedBox(height: 4),
                              Text('yih.loong@gmail.com',
                                  style: AppTypography.bodyMedium.copyWith(color: AppColors.white65)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.shield_rounded,
                                      size: 12,
                                      color: AppColors.yellowBadge),
                                  const SizedBox(width: 6),
                                  Text('SmartRoute Premium',
                                      style: AppTypography.captionBold.copyWith(color: AppColors.yellowBadge)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Travel stats
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
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
                        Text('TRAVEL STATS',
                            style: AppTypography.captionBlack),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _StatCard(
                                emoji: '🚆', value: '247', label: 'Trips'),
                            const SizedBox(width: 12),
                            _StatCard(
                                emoji: '📍',
                                value: '1,240km',
                                label: 'Distance'),
                            const SizedBox(width: 12),
                            _StatCard(
                                emoji: '🌿',
                                value: '89kg',
                                label: 'CO₂ Saved'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment methods
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
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
                        Text('PAYMENT METHODS',
                            style: AppTypography.captionBlack),
                        const SizedBox(height: 12),
                        _PaymentRow(
                          icon: Icons.credit_card_rounded,
                          iconColor: AppColors.primary,
                          iconBg: AppColors.primaryLight,
                          label: 'MyRapid Card',
                          sub: 'Balance: RM 23.10',
                          action: 'Top Up',
                          actionColor: AppColors.primary,
                          actionTextColor: Colors.white,
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Divider(color: Color(0xFFF9FAFB)),
                        ),
                        const SizedBox(height: 12),
                        _PaymentRow(
                          icon: Icons.account_balance_wallet_rounded,
                          iconColor: AppColors.secondary,
                          iconBg: AppColors.secondaryLight,
                          label: "Touch 'n Go eWallet",
                          sub: 'Linked · RM 85.60',
                          trailing: const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Settings
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: AppShadows.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text('SETTINGS',
                              style: AppTypography.captionBlack),
                        ),
                        _SettingsToggle(
                          title: 'Push Notifications',
                          subtitle: 'Delays, alerts, updates',
                          value: _notifications,
                          onChanged: (v) =>
                              setState(() => _notifications = v),
                        ),
                        const _SettingsDivider(),
                        _SettingsToggle(
                          title: 'Location Services',
                          subtitle: 'For nearby stations & live eta',
                          value: _location,
                          onChanged: (v) =>
                              setState(() => _location = v),
                        ),
                        const _SettingsDivider(),
                        const _SettingsRow(
                          title: 'Language',
                          note: 'English (Malaysia)',
                        ),
                        const _SettingsDivider(),
                        const _SettingsRow(title: 'Help & Support'),
                        const _SettingsDivider(),
                        const _SettingsRow(
                            title: 'About SmartRoute',
                            note: 'v2.4.1'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sign out
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onLogout,
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: const Text('Sign Out',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                            color: Color(0xFFFEE2E2)),
                        backgroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.mutedBg,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value,
                style: AppTypography.monoMedium),
            const SizedBox(height: 2),
            Text(label,
                style: AppTypography.captionMedium),
          ],
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String sub;
  final String? action;
  final Color? actionColor;
  final Color? actionTextColor;
  final Widget? trailing;

  const _PaymentRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.sub,
    this.action,
    this.actionColor,
    this.actionTextColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTypography.bodyLarge),
              const SizedBox(height: 2),
              Text(sub,
                  style: AppTypography.labelMedium),
            ],
          ),
        ),
        if (trailing != null) trailing!,
        if (action != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: actionColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(action!,
                style: AppTypography.bodySmall.copyWith(
                    color: actionTextColor ?? Colors.white)),
          ),
      ],
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.bodyLarge),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTypography.labelMedium),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 24,
              decoration: BoxDecoration(
                color:
                    value ? AppColors.primary : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.card,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String title;
  final String? note;
  const _SettingsRow({required this.title, this.note});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: AppTypography.bodyLarge),
          ),
          if (note != null)
            Text(note!,
                style: AppTypography.labelMedium),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded,
              size: 16, color: Color(0xFFD1D5DB)),
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
        color: Color(0xFFF9FAFB), height: 1, thickness: 1);
  }
}

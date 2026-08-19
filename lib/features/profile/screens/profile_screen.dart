import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../user_management/application/profile_controller.dart';
import '../../user_management/domain/models/app_user.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser authUser;
  final ProfileController profileController;
  final VoidCallback onBack;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.authUser,
    required this.profileController,
    required this.onBack,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    widget.profileController.addListener(_onProfileStateChanged);
    _checkAndLoadProfile();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profileController != widget.profileController) {
      oldWidget.profileController.removeListener(_onProfileStateChanged);
      widget.profileController.addListener(_onProfileStateChanged);
    }
    if (oldWidget.authUser.id != widget.authUser.id ||
        oldWidget.profileController != widget.profileController) {
      _checkAndLoadProfile();
    }
  }

  @override
  void dispose() {
    widget.profileController.removeListener(_onProfileStateChanged);
    super.dispose();
  }

  void _onProfileStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _checkAndLoadProfile() {
    if (!widget.profileController.isLoadedFor(widget.authUser.id) &&
        !widget.profileController.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            !widget.profileController.isLoadedFor(widget.authUser.id) &&
            !widget.profileController.isLoading) {
          widget.profileController.load(userId: widget.authUser.id);
        }
      });
    }
  }

  String _getInitials(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) {
      final name = parts[0];
      return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'U';
    }
    final first = parts[0].isNotEmpty ? parts[0].substring(0, 1) : '';
    final second = parts[1].isNotEmpty ? parts[1].substring(0, 1) : '';
    return '$first$second'.toUpperCase();
  }

  String _formatLanguage(String languageCode) {
    if (languageCode == 'ms') {
      return 'Bahasa Melayu';
    }
    return 'English (Malaysia)';
  }

  void _showEditNameDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => _EditNameDialog(
        initialName: widget.profileController.profile?.fullName ?? '',
        photoUrl: widget.profileController.profile?.photoUrl,
        userId: widget.authUser.id,
        profileController: widget.profileController,
      ),
    );
  }

  void _showLanguageSelector() {
    final currentLang = widget.profileController.preferences?.language ?? 'en';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(
                    'Select Language',
                    style: AppTypography.titleMedium,
                  ),
                ),
                const Divider(),
                ListTile(
                  key: const Key('language_option_en'),
                  title: const Text('English (Malaysia)'),
                  trailing: currentLang == 'en'
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: widget.profileController.isSaving
                      ? null
                      : () async {
                          Navigator.of(bottomSheetContext).pop();
                          await widget.profileController.setLanguage(
                            userId: widget.authUser.id,
                            language: 'en',
                          );
                        },
                ),
                ListTile(
                  key: const Key('language_option_ms'),
                  title: const Text('Bahasa Melayu'),
                  trailing: currentLang == 'ms'
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: widget.profileController.isSaving
                      ? null
                      : () async {
                          Navigator.of(bottomSheetContext).pop();
                          await widget.profileController.setLanguage(
                            userId: widget.authUser.id,
                            language: 'ms',
                          );
                        },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.profileController;

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
              SizedBox(height: MediaQuery.of(context).padding.top),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Profile', style: AppTypography.titleMedium),
                ),
              ),
            ],
          ),
        ),

        // ── Body ──
        Expanded(
          child: Container(
            color: AppColors.background,
            child: _buildBodyContent(controller),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyContent(ProfileController controller) {
    // 1. Initial loading state
    if (controller.isLoading && !controller.isLoaded) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('profile_loading_indicator'),
          color: AppColors.primary,
        ),
      );
    }

    // 2. Load failure state
    if (!controller.isLoaded && controller.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.statusMajorDelayText,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                controller.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                key: const Key('profile_retry_button'),
                onPressed: () => controller.load(userId: widget.authUser.id),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Loaded profile and preferences
    final profile = controller.profile;
    final preferences = controller.preferences;

    if (profile == null || preferences == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Inline non-blocking error banner (if a save failed while loaded)
          if (controller.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.statusSuspendedBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.statusSuspendedText,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        controller.errorMessage!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.statusSuspendedText,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: AppColors.statusSuspendedText,
                      onPressed: () => controller.clearError(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),

          // Real Profile Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.gradientProfile,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  // Real avatar with initials
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.white25,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(profile.fullName),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                profile.fullName,
                                key: const Key('profile_fullname_text'),
                                style: AppTypography.headlineSmall.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              key: const Key('profile_edit_name_button'),
                              icon: const Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: controller.isSaving
                                  ? null
                                  : _showEditNameDialog,
                              tooltip: 'Edit Name',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.authUser.email,
                          key: const Key('profile_email_text'),
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.white65,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Real Settings
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
                    child: Text('SETTINGS', style: AppTypography.captionBlack),
                  ),
                  _SettingsToggle(
                    key: const Key('notifications_toggle'),
                    title: 'Push Notifications',
                    subtitle: 'Delays, alerts, updates',
                    value: preferences.notificationsEnabled,
                    disabled: controller.isSaving,
                    onChanged: (v) => controller.setNotificationsEnabled(
                      userId: widget.authUser.id,
                      enabled: v,
                    ),
                  ),
                  const _SettingsDivider(),
                  _SettingsToggle(
                    key: const Key('location_toggle'),
                    title: 'Location Services',
                    subtitle: 'For nearby stations & live eta',
                    value: preferences.locationEnabled,
                    disabled: controller.isSaving,
                    onChanged: (v) => controller.setLocationEnabled(
                      userId: widget.authUser.id,
                      enabled: v,
                    ),
                  ),
                  const _SettingsDivider(),
                  _SettingsRow(
                    key: const Key('language_row'),
                    title: 'Language',
                    note: _formatLanguage(preferences.language),
                    onTap: controller.isSaving ? null : _showLanguageSelector,
                  ),
                  const _SettingsDivider(),
                  const _SettingsRow(title: 'Help & Support'),
                  const _SettingsDivider(),
                  const _SettingsRow(title: 'About SmartRoute'),
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
                key: const Key('profile_signout_button'),
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: Color(0xFFFEE2E2)),
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
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

// ─── Sub-widgets ─────────────────────────────────────────────────────────

class _SettingsToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool disabled;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    this.disabled = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: disabled ? null : () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyLarge),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.labelMedium),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 24,
              decoration: BoxDecoration(
                color: value ? AppColors.primary : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
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
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String title;
  final String? note;
  final VoidCallback? onTap;

  const _SettingsRow({super.key, required this.title, this.note, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(title, style: AppTypography.bodyLarge)),
            if (note != null) Text(note!, style: AppTypography.labelMedium),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Color(0xFFD1D5DB),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(color: Color(0xFFF9FAFB), height: 1, thickness: 1);
  }
}

class _EditNameDialog extends StatefulWidget {
  final String initialName;
  final String? photoUrl;
  final String userId;
  final ProfileController profileController;

  const _EditNameDialog({
    required this.initialName,
    required this.photoUrl,
    required this.userId,
    required this.profileController,
  });

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _textController;
  String? _localError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final entered = _textController.text.trim();
    if (entered.isEmpty) {
      setState(() {
        _localError = 'Full name is required';
      });
      return;
    }
    if (entered.length < 2) {
      setState(() {
        _localError = 'Full name must be at least 2 characters';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _localError = null;
    });

    final success = await widget.profileController.updateProfile(
      userId: widget.userId,
      fullName: entered,
      photoUrl: widget.photoUrl,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (!success && mounted) {
      setState(() {
        _isSubmitting = false;
        _localError =
            widget.profileController.errorMessage ??
            'Unable to update your profile. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Text('Edit Full Name', style: AppTypography.titleMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            key: const Key('edit_name_textfield'),
            controller: _textController,
            enabled: !_isSubmitting,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your full name',
              errorText: _localError,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('cancel_edit_name_button'),
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('save_edit_name_button'),
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

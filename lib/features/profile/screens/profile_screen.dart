import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_typography.dart';
import '../../user_management/application/profile_controller.dart';
import '../../user_management/domain/models/app_user.dart';
import '../../transit_network/application/transit_network_controller.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser authUser;
  final ProfileController profileController;
  final VoidCallback onBack;
  final VoidCallback onLogout;
  final bool isAdmin;
  final VoidCallback? onAdmin;
  final TransitNetworkController? transitController;

  const ProfileScreen({
    super.key,
    required this.authUser,
    required this.profileController,
    required this.onBack,
    required this.onLogout,
    this.isAdmin = false,
    this.onAdmin,
    this.transitController,
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

  void _showAbout() {
    final metadata = widget.transitController?.network?.metadata;
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About & data sources', style: AppTypography.titleMedium),
            const SizedBox(height: 16),
            const _SourceRow(
              title: 'Transit network & schedules',
              value: 'Malaysia government open data · data.gov.my · Prasarana',
            ),
            const _SourceRow(
              title: 'Realtime where available',
              value: 'Official Rapid KL GTFS-Realtime vehicle positions',
            ),
            const _SourceRow(
              title: 'Geographic presentation',
              value: 'Google Maps',
            ),
            const _SourceRow(
              title: 'User data',
              value: 'SmartRoute · Supabase',
            ),
            if (metadata != null)
              _SourceRow(
                title: 'Bundled snapshot',
                value:
                    '${metadata.routeCount} routes · ${metadata.stopCount} stops · ${metadata.generatedAt.toLocal()}',
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.profileController;

    return Column(
      children: [
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
    if (controller.isLoading && !controller.isLoaded) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('profile_loading_indicator'),
          color: AppColors.primary,
        ),
      );
    }

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

          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                gradient: const LinearGradient(
                  colors: AppColors.gradientDarkHero,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.white15,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.white20),
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.headlineSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                    title: 'In-app notifications',
                    subtitle: 'Relevant notices for followed journeys',
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
                    subtitle: 'Nearby origin and map location',
                    value: preferences.locationEnabled,
                    disabled: controller.isSaving,
                    onChanged: (v) => controller.setLocationEnabled(
                      userId: widget.authUser.id,
                      enabled: v,
                    ),
                  ),
                  const _SettingsDivider(),
                  _SettingsRow(
                    title: 'About & data sources',
                    onTap: _showAbout,
                  ),
                  if (widget.isAdmin && widget.onAdmin != null) ...[
                    const _SettingsDivider(),
                    _SettingsRow(
                      title: 'Admin workspace',
                      onTap: widget.onAdmin,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

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
  final VoidCallback? onTap;

  const _SettingsRow({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(title, style: AppTypography.bodyLarge)),
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

class _SourceRow extends StatelessWidget {
  final String title;
  final String value;

  const _SourceRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.bodyLarge),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
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

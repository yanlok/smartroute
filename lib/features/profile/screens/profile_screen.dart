import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../user_management/application/auth_controller.dart';
import '../../user_management/application/profile_controller.dart';
import '../../user_management/application/saved_journey_controller.dart';
import '../../user_management/domain/models/avatar_upload.dart';
import '../../user_management/domain/models/app_user.dart';
import '../../transit_network/application/transit_network_controller.dart';

class ProfileScreen extends StatefulWidget {
  final AppUser authUser;
  final AuthController authController;
  final ProfileController profileController;
  final SavedJourneyController savedJourneys;
  final VoidCallback onBack;
  final VoidCallback onLogout;
  final VoidCallback onSavedJourneys;
  final bool isAdmin;
  final VoidCallback? onAdmin;
  final TransitNetworkController? transitController;
  final Future<AvatarUpload?> Function()? pickAvatar;

  const ProfileScreen({
    super.key,
    required this.authUser,
    required this.authController,
    required this.profileController,
    required this.savedJourneys,
    required this.onBack,
    required this.onLogout,
    required this.onSavedJourneys,
    this.isAdmin = false,
    this.onAdmin,
    this.transitController,
    this.pickAvatar,
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

  Future<AvatarUpload?> _pickAvatarFromGallery() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (image == null) return null;
    return AvatarUpload(
      bytes: await image.readAsBytes(),
      fileName: image.name,
      mimeType: image.mimeType,
    );
  }

  Future<void> _showAvatarActions() async {
    final hasPhoto = widget.profileController.profile?.photoUrl != null;
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('choose_avatar_action'),
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(context).pop('choose'),
            ),
            if (hasPhoto)
              ListTile(
                key: const Key('remove_avatar_action'),
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Remove profile photo'),
                onTap: () => Navigator.of(context).pop('remove'),
              ),
          ],
        ),
      ),
    );
    if (action == 'choose') await _chooseAvatar();
    if (action == 'remove') await _removeAvatar();
  }

  Future<void> _chooseAvatar() async {
    try {
      final image = await (widget.pickAvatar ?? _pickAvatarFromGallery)();
      if (image == null || !mounted) return;
      final success = await widget.profileController.uploadAvatar(
        userId: widget.authUser.id,
        image: image,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Profile photo updated.'
                : widget.profileController.errorMessage ??
                      'Profile photo could not be updated.',
          ),
        ),
      );
    } on PlatformException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The photo gallery could not be opened.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The selected photo could not be read.')),
      );
    }
  }

  Future<void> _removeAvatar() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove profile photo?'),
        content: const Text('Your initials will be shown instead.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm_remove_avatar'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await widget.profileController.removeAvatar(
      userId: widget.authUser.id,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Profile photo removed.'
              : widget.profileController.errorMessage ??
                    'Profile photo could not be removed.',
        ),
      ),
    );
  }

  Future<void> _showLanguagePicker() async {
    final selected = widget.profileController.preferences?.language ?? 'en';
    final value = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Language preference', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.gapMd),
            ListTile(
              key: const Key('language_english'),
              title: const Text('English'),
              trailing: selected == 'en'
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(context).pop('en'),
            ),
            ListTile(
              key: const Key('language_malay'),
              title: const Text('Bahasa Melayu'),
              trailing: selected == 'ms'
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () => Navigator.of(context).pop('ms'),
            ),
            Text(
              'This saves your preference. Full app translation is not available yet.',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
    if (value == null || value == selected) return;
    final success = await widget.profileController.setLanguage(
      userId: widget.authUser.id,
      language: value,
    );
    if (!mounted || success) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.profileController.errorMessage ??
              'Language preference could not be updated.',
        ),
      ),
    );
  }

  Future<void> _showChangePassword() async {
    widget.authController.clearPasswordError();
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ChangePasswordDialog(
        email: widget.authUser.email,
        controller: widget.authController,
      ),
    );
    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
    }
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
                  _ProfileAvatar(
                    fullName: profile.fullName,
                    photoUrl: profile.photoUrl,
                    loading: controller.isAvatarSaving,
                    onEdit: _showAvatarActions,
                    initials: _getInitials(profile.fullName),
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
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          key: const Key('profile_role_display'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.gapMd,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white15,
                            borderRadius: BorderRadius.circular(
                              AppRadius.circular,
                            ),
                          ),
                          child: Text(
                            widget.isAdmin ? 'Admin' : 'Passenger',
                            style: AppTypography.captionBold.copyWith(
                              color: Colors.white,
                            ),
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
                    key: const Key('language_row'),
                    title: 'Language',
                    subtitle: 'Preference only; app text remains in English',
                    value: preferences.language == 'ms'
                        ? 'Bahasa Melayu'
                        : 'English',
                    onTap: controller.isSaving ? null : _showLanguagePicker,
                  ),
                  const _SettingsDivider(),
                  _SettingsRow(
                    key: const Key('saved_journeys_row'),
                    title: 'Saved Journeys',
                    subtitle:
                        '${widget.savedJourneys.favorites.length} saved journey${widget.savedJourneys.favorites.length == 1 ? '' : 's'}',
                    onTap: widget.onSavedJourneys,
                  ),
                  const _SettingsDivider(),
                  _SettingsRow(
                    key: const Key('change_password_row'),
                    title: 'Change Password',
                    subtitle: 'Update your Supabase account password',
                    onTap: widget.authController.isChangingPassword
                        ? null
                        : _showChangePassword,
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

class _ProfileAvatar extends StatelessWidget {
  final String fullName;
  final String? photoUrl;
  final bool loading;
  final VoidCallback onEdit;
  final String initials;

  const _ProfileAvatar({
    required this.fullName,
    required this.photoUrl,
    required this.loading,
    required this.onEdit,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedPhoto = photoUrl?.trim();
    return SizedBox(
      width: AppSpacing.avatarSize + AppSpacing.gapMd,
      height: AppSpacing.avatarSize + AppSpacing.gapMd,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Container(
                width: AppSpacing.avatarSize,
                height: AppSpacing.avatarSize,
                decoration: BoxDecoration(
                  color: AppColors.white15,
                  border: Border.all(color: AppColors.white20),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: resolvedPhoto != null && resolvedPhoto.isNotEmpty
                    ? Image.network(
                        resolvedPhoto,
                        key: const Key('profile_avatar_image'),
                        fit: BoxFit.cover,
                        semanticLabel: '$fullName profile photo',
                        errorBuilder: (_, _, _) => _initials(),
                      )
                    : _initials(),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                key: const Key('profile_avatar_edit_button'),
                onTap: loading ? null : onEdit,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.gapSm),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: AppSpacing.xxl,
                  ),
                ),
              ),
            ),
          ),
          if (loading)
            const Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: AppSpacing.xxl3,
                  height: AppSpacing.xxl3,
                  child: CircularProgressIndicator(
                    key: Key('profile_avatar_loading'),
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _initials() => Center(
    child: Text(
      initials,
      key: const Key('profile_avatar_initials'),
      style: AppTypography.headlineMedium.copyWith(color: Colors.white),
    ),
  );
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
  final String? subtitle;
  final String? value;
  final VoidCallback? onTap;

  const _SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyLarge),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              Text(
                value!,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            const SizedBox(width: AppSpacing.xs),
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

class _ChangePasswordDialog extends StatefulWidget {
  final String email;
  final AuthController controller;

  const _ChangePasswordDialog({required this.email, required this.controller});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _currentVisible = false;
  bool _newVisible = false;
  bool _confirmVisible = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final success = await widget.controller.changePassword(
      email: widget.email,
      currentPassword: _currentController.text,
      newPassword: _newController.text,
      confirmPassword: _confirmController.text,
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isSubmitting = false;
      _errorMessage =
          widget.controller.passwordErrorMessage ??
          'Password could not be changed. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Text('Change Password', style: AppTypography.titleMedium),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PasswordField(
              key: const Key('current_password_field'),
              controller: _currentController,
              label: 'Current password',
              visible: _currentVisible,
              enabled: !_isSubmitting,
              toggleKey: const Key('toggle_current_password'),
              onToggle: () =>
                  setState(() => _currentVisible = !_currentVisible),
            ),
            const SizedBox(height: AppSpacing.gapXl),
            _PasswordField(
              key: const Key('new_password_field'),
              controller: _newController,
              label: 'New password',
              visible: _newVisible,
              enabled: !_isSubmitting,
              toggleKey: const Key('toggle_new_password'),
              onToggle: () => setState(() => _newVisible = !_newVisible),
            ),
            const SizedBox(height: AppSpacing.gapXl),
            _PasswordField(
              key: const Key('confirm_password_field'),
              controller: _confirmController,
              label: 'Confirm new password',
              visible: _confirmVisible,
              enabled: !_isSubmitting,
              toggleKey: const Key('toggle_confirm_password'),
              onToggle: () =>
                  setState(() => _confirmVisible = !_confirmVisible),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.gapMd),
              Text(
                _errorMessage!,
                key: const Key('change_password_error'),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.statusMajorDelayText,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('save_password_button'),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: AppSpacing.xxl,
                  height: AppSpacing.xxl,
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

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool visible;
  final bool enabled;
  final Key toggleKey;
  final VoidCallback onToggle;

  const _PasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.visible,
    required this.enabled,
    required this.toggleKey,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    obscureText: !visible,
    enableSuggestions: false,
    autocorrect: false,
    autofillHints: label == 'Current password'
        ? const [AutofillHints.password]
        : const [AutofillHints.newPassword],
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      suffixIcon: IconButton(
        key: toggleKey,
        tooltip: visible ? 'Hide password' : 'Show password',
        onPressed: enabled ? onToggle : null,
        icon: Icon(
          visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
      ),
    ),
  );
}

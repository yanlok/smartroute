import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/notice_models.dart';
import '../../../shared/models/transit_models.dart';
import '../../alerts/application/notice_controller.dart';
import '../../transit_network/application/transit_network_controller.dart';

class AdminDashboardScreen extends StatefulWidget {
  final NoticeController controller;
  final TransitNetworkController transitController;
  final VoidCallback onSignOut;

  const AdminDashboardScreen({
    super.key,
    required this.controller,
    required this.transitController,
    required this.onSignOut,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of the Admin console?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      widget.onSignOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.controller,
        widget.transitController,
      ]),
      builder: (context, _) {
        final network = widget.transitController.network;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            titleSpacing: AppSpacing.pageHorizontal,
            automaticallyImplyLeading: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.gapSm),
                    Flexible(
                      child: Text(
                        'SmartRoute Admin',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Operations & Directory Console',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.captionMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: widget.controller.reload,
                icon: const Icon(Icons.refresh_rounded),
              ),
              IconButton(
                tooltip: 'Sign Out',
                onPressed: _handleSignOut,
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.gapSm),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: AppColors.borderLight, height: 1),
            ),
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: [
              _AdminOverview(controller: widget.controller, network: network),
              _AdminNotices(controller: widget.controller, network: network),
              _AdminUserDirectory(controller: widget.controller),
              _AdminDataHealth(controller: widget.controller),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primaryLight,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(
                  Icons.dashboard_rounded,
                  color: AppColors.primary,
                ),
                label: 'Overview',
              ),
              NavigationDestination(
                icon: Icon(Icons.campaign_outlined),
                selectedIcon: Icon(
                  Icons.campaign_rounded,
                  color: AppColors.primary,
                ),
                label: 'Notices',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_outline_rounded),
                selectedIcon: Icon(
                  Icons.people_rounded,
                  color: AppColors.primary,
                ),
                label: 'Users',
              ),
              NavigationDestination(
                icon: Icon(Icons.health_and_safety_outlined),
                selectedIcon: Icon(
                  Icons.health_and_safety_rounded,
                  color: AppColors.primary,
                ),
                label: 'Data Health',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminOverview extends StatelessWidget {
  final NoticeController controller;
  final TransitNetwork? network;

  const _AdminOverview({required this.controller, required this.network});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final activeNotices = controller.notices
        .where((n) => n.isActiveAt(now))
        .length;
    final totalUsers = controller.users.length;
    final adminUsers = controller.users.where((u) => u.role == 'admin').length;
    final passengerUsers = totalUsers - adminUsers;
    final healthySources = controller.sourceHealth
        .where((s) => s.status == 'healthy')
        .length;
    final totalSources = controller.sourceHealth.length;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        Text('SYSTEM METRICS', style: AppTypography.captionBlack),
        const SizedBox(height: AppSpacing.gapMd),
        Wrap(
          spacing: AppSpacing.gapMd,
          runSpacing: AppSpacing.gapMd,
          children: [
            _MetricCard(
              label: 'TOTAL ACCOUNTS',
              value: '$totalUsers',
              icon: Icons.people_rounded,
            ),
            _MetricCard(
              label: 'PASSENGERS',
              value: '$passengerUsers',
              icon: Icons.person_rounded,
            ),
            _MetricCard(
              label: 'ADMINISTRATORS',
              value: '$adminUsers',
              icon: Icons.shield_rounded,
            ),
            _MetricCard(
              label: 'ACTIVE NOTICES',
              value: '$activeNotices',
              icon: Icons.campaign_rounded,
            ),
            _MetricCard(
              label: 'NETWORK ROUTES',
              value: '${network?.metadata.routeCount ?? '—'}',
              icon: Icons.alt_route_rounded,
            ),
            _MetricCard(
              label: 'NETWORK STOPS',
              value: '${network?.metadata.stopCount ?? '—'}',
              icon: Icons.location_on_rounded,
            ),
            _MetricCard(
              label: 'DATA HEALTH',
              value: totalSources > 0 ? '$healthySources / $totalSources' : '—',
              icon: Icons.check_circle_rounded,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionXl),
        Text('OPERATIONAL SCOPE', style: AppTypography.captionBlack),
        const SizedBox(height: AppSpacing.gapMd),
        const _InfoCard(
          icon: Icons.verified_user_outlined,
          title: 'Database-backed authorization',
          body:
              'Admin workspace is granted only to accounts with an active admin record in public.user_roles.',
        ),
        const _InfoCard(
          icon: Icons.lock_outline_rounded,
          title: 'Official data remains read-only',
          body:
              'Admins publish SmartRoute notices and inspect source health. Government GTFS identity is not editable.',
        ),
        const _InfoCard(
          icon: Icons.security_rounded,
          title: 'Role-based access control',
          body:
              'Row Level Security protects all sensitive queries. Passengers cannot view admin consoles or publish notices.',
        ),
      ],
    );
  }
}

class _AdminNotices extends StatelessWidget {
  final NoticeController controller;
  final TransitNetwork? network;

  const _AdminNotices({required this.controller, required this.network});

  @override
  Widget build(BuildContext context) {
    final notices = controller.notices;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.sectionMd,
            AppSpacing.pageHorizontal,
            88,
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SERVICE NOTICES (${notices.length})',
                  style: AppTypography.captionBlack,
                ),
                Text(
                  '${notices.where((n) => n.isActiveAt(DateTime.now())).length} active',
                  style: AppTypography.captionMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.gapMd),
            if (notices.isEmpty)
              const _InfoCard(
                icon: Icons.campaign_outlined,
                title: 'No service notices',
                body: 'Create a line-specific SmartRoute notice when needed.',
              )
            else
              for (final notice in notices)
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: AppSpacing.gapMd),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.gapLg,
                      vertical: AppSpacing.gapSm,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.gapSm),
                      decoration: BoxDecoration(
                        color: notice.status == NoticeStatus.published
                            ? AppColors.primaryLight
                            : AppColors.mutedBg,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(
                        notice.category == NoticeCategory.delay
                            ? Icons.timer_outlined
                            : notice.category == NoticeCategory.maintenance
                            ? Icons.build_outlined
                            : Icons.info_outline_rounded,
                        color: notice.status == NoticeStatus.published
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      notice.title,
                      style: AppTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notice.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _Badge(
                              text: notice.status.name.toUpperCase(),
                              isPrimary:
                                  notice.status == NoticeStatus.published,
                            ),
                            _Badge(
                              text:
                                  network
                                      ?.routesById[notice.routeId]
                                      ?.displayName ??
                                  notice.routeId,
                            ),
                            _Badge(
                              text: notice.source == NoticeSource.official
                                  ? 'OFFICIAL'
                                  : 'SMARTROUTE',
                            ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing:
                        notice.source == NoticeSource.smartRoute &&
                            notice.status != NoticeStatus.archived
                        ? IconButton(
                            tooltip: 'Archive notice',
                            onPressed: () => controller.archive(notice),
                            icon: const Icon(Icons.archive_outlined),
                          )
                        : null,
                    onTap: notice.source == NoticeSource.smartRoute
                        ? () => _openEditor(context, notice)
                        : null,
                  ),
                ),
          ],
        ),
        Positioned(
          right: AppSpacing.pageHorizontal,
          bottom: AppSpacing.sectionLg,
          child: FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            onPressed: network == null
                ? null
                : () => _openEditor(context, null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New notice'),
          ),
        ),
      ],
    );
  }

  Future<void> _openEditor(BuildContext context, ServiceNotice? notice) async {
    final selectedNetwork = network;
    if (selectedNetwork == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _NoticeEditor(
        controller: controller,
        network: selectedNetwork,
        notice: notice,
      ),
    );
  }
}

class _NoticeEditor extends StatefulWidget {
  final NoticeController controller;
  final TransitNetwork network;
  final ServiceNotice? notice;

  const _NoticeEditor({
    required this.controller,
    required this.network,
    required this.notice,
  });

  @override
  State<_NoticeEditor> createState() => _NoticeEditorState();
}

class _NoticeEditorState extends State<_NoticeEditor> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late String _routeId;
  late NoticeCategory _category;
  late NoticeSeverity _severity;
  late NoticeStatus _status;
  DateTime? _endsAt;
  String? _error;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.notice?.title);
    _body = TextEditingController(text: widget.notice?.body);
    _routeId = widget.notice?.routeId ?? widget.network.routes.first.id;
    _category = widget.notice?.category ?? NoticeCategory.service;
    _severity = widget.notice?.severity ?? NoticeSeverity.info;
    _status = widget.notice?.status ?? NoticeStatus.draft;
    _endsAt = widget.notice?.endsAt;
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      AppSpacing.pageHorizontal,
      AppSpacing.sectionLg,
      AppSpacing.pageHorizontal,
      MediaQuery.viewInsetsOf(context).bottom + AppSpacing.sectionLg,
    ),
    child: ListView(
      shrinkWrap: true,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.notice == null ? 'Create service notice' : 'Edit notice',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gapLg),
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.gapMd),
            decoration: BoxDecoration(
              color: AppColors.severityCriticalBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.severityCriticalColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _error!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.severityCriticalColor,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.gapMd),
        ],
        TextField(
          controller: _title,
          maxLength: 120,
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.gapMd),
        TextField(
          controller: _body,
          maxLength: 1000,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Commuter message',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: AppSpacing.gapMd),
        DropdownButtonFormField<String>(
          initialValue: _routeId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Affected route',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final route in widget.network.routes)
              DropdownMenuItem(
                value: route.id,
                child: Text(route.displayName, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (value) => setState(() => _routeId = value ?? _routeId),
        ),
        const SizedBox(height: AppSpacing.gapMd),
        DropdownButtonFormField<NoticeCategory>(
          initialValue: _category,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Notice type',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: NoticeCategory.delay, child: Text('Delay')),
            DropdownMenuItem(
              value: NoticeCategory.maintenance,
              child: Text('Maintenance'),
            ),
            DropdownMenuItem(
              value: NoticeCategory.service,
              child: Text('Service announcement'),
            ),
          ],
          onChanged: (value) => setState(() => _category = value ?? _category),
        ),
        const SizedBox(height: AppSpacing.gapMd),
        DropdownButtonFormField<NoticeSeverity>(
          initialValue: _severity,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Severity',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final severity in NoticeSeverity.values)
              DropdownMenuItem(
                value: severity,
                child: Text(severity.name.toUpperCase()),
              ),
          ],
          onChanged: (value) => setState(() => _severity = value ?? _severity),
        ),
        const SizedBox(height: AppSpacing.gapMd),
        DropdownButtonFormField<NoticeStatus>(
          initialValue: _status,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Publication state',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: NoticeStatus.draft, child: Text('Draft')),
            DropdownMenuItem(
              value: NoticeStatus.published,
              child: Text('Published'),
            ),
          ],
          onChanged: (value) => setState(() => _status = value ?? _status),
        ),
        const SizedBox(height: AppSpacing.sectionLg),
        OutlinedButton.icon(
          onPressed: _pickEnd,
          icon: const Icon(Icons.event_rounded),
          label: Text(
            _endsAt == null
                ? 'No automatic expiry'
                : 'Expires ${_endsAt!.toLocal().toString().split('.')[0]}',
          ),
        ),
        const SizedBox(height: AppSpacing.sectionLg),
        FilledButton(
          onPressed: widget.controller.isSaving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: widget.controller.isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  _status == NoticeStatus.published
                      ? 'Publish notice'
                      : 'Save draft',
                ),
        ),
      ],
    ),
  );

  Future<void> _pickEnd() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endsAt ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _endsAt = date.add(const Duration(days: 1)));
    }
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Notice title is required.');
      return;
    }
    if (body.isEmpty) {
      setState(() => _error = 'Commuter message is required.');
      return;
    }
    setState(() => _error = null);

    final success = await widget.controller.saveNotice(
      id: widget.notice?.id,
      title: title,
      body: body,
      category: _category,
      severity: _severity,
      routeId: _routeId,
      startsAt: widget.notice?.startsAt ?? DateTime.now(),
      endsAt: _endsAt,
      status: _status,
    );
    if (success && mounted) Navigator.of(context).pop();
  }
}

class _AdminUserDirectory extends StatefulWidget {
  final NoticeController controller;

  const _AdminUserDirectory({required this.controller});

  @override
  State<_AdminUserDirectory> createState() => _AdminUserDirectoryState();
}

class _AdminUserDirectoryState extends State<_AdminUserDirectory> {
  final _searchController = TextEditingController();
  String _roleFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showUserDetail(AdminUserSummary user) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Account Details',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.gapLg),
            Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: user.role == 'admin'
                    ? AppColors.primaryLight
                    : AppColors.mutedBg,
                backgroundImage:
                    user.photoUrl != null && user.photoUrl!.isNotEmpty
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null || user.photoUrl!.isEmpty
                    ? Text(
                        user.fullName.isNotEmpty
                            ? user.fullName.substring(0, 1).toUpperCase()
                            : 'U',
                        style: AppTypography.headlineMedium.copyWith(
                          color: user.role == 'admin'
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.gapMd),
            Center(
              child: Text(
                user.fullName,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.gapSm),
            Center(
              child: _Badge(
                text: user.role.toUpperCase(),
                isPrimary: user.role == 'admin',
              ),
            ),
            const SizedBox(height: AppSpacing.sectionLg),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: AppSpacing.gapMd),
            _DetailRow(
              label: 'ACCOUNT ID',
              value: user.id,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: user.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account ID copied to clipboard.'),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.gapMd),
            _DetailRow(
              label: 'ROLE ASSIGNMENT',
              value: user.role == 'admin'
                  ? 'Administrator (public.user_roles)'
                  : 'Passenger (default)',
            ),
            const SizedBox(height: AppSpacing.gapMd),
            _DetailRow(
              label: 'JOINED DATE',
              value: user.createdAt.toLocal().toString().split('.')[0],
            ),
            const SizedBox(height: AppSpacing.gapLg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.gapMd),
              decoration: BoxDecoration(
                color: AppColors.mutedBg,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.gapSm),
                  Expanded(
                    child: Text(
                      'Account authentication credentials and email addresses remain protected in Supabase Auth.',
                      style: AppTypography.captionMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionMd),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final allUsers = widget.controller.users;

    final filteredUsers = allUsers.where((user) {
      if (_roleFilter == 'admin' && user.role != 'admin') return false;
      if (_roleFilter == 'passenger' && user.role == 'admin') return false;
      if (query.isNotEmpty) {
        final matchesName = user.fullName.toLowerCase().contains(query);
        final matchesId = user.id.toLowerCase().contains(query);
        if (!matchesName && !matchesId) return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.gapMd,
            AppSpacing.pageHorizontal,
            AppSpacing.gapSm,
          ),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by name or ID...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.inputBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.inputBorder),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.gapSm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All (${allUsers.length})',
                      isSelected: _roleFilter == 'all',
                      onSelected: () => setState(() => _roleFilter = 'all'),
                    ),
                    const SizedBox(width: AppSpacing.gapSm),
                    _FilterChip(
                      label:
                          'Passengers (${allUsers.where((u) => u.role != 'admin').length})',
                      isSelected: _roleFilter == 'passenger',
                      onSelected: () =>
                          setState(() => _roleFilter = 'passenger'),
                    ),
                    const SizedBox(width: AppSpacing.gapSm),
                    _FilterChip(
                      label:
                          'Admins (${allUsers.where((u) => u.role == 'admin').length})',
                      isSelected: _roleFilter == 'admin',
                      onSelected: () => setState(() => _roleFilter = 'admin'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.controller.reload,
            color: AppColors.primary,
            child: filteredUsers.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(AppSpacing.sectionLg),
                    children: [
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: AppSpacing.gapMd),
                            Text(
                              query.isNotEmpty
                                  ? 'No accounts matching "$query"'
                                  : 'No accounts found in this role',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
                    itemCount: filteredUsers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.gapSm),
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final isAdmin = user.role == 'admin';
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          side: const BorderSide(color: AppColors.borderLight),
                        ),
                        child: ListTile(
                          onTap: () => _showUserDetail(user),
                          leading: CircleAvatar(
                            backgroundColor: isAdmin
                                ? AppColors.primaryLight
                                : AppColors.mutedBg,
                            backgroundImage:
                                user.photoUrl != null &&
                                    user.photoUrl!.isNotEmpty
                                ? NetworkImage(user.photoUrl!)
                                : null,
                            child:
                                user.photoUrl == null || user.photoUrl!.isEmpty
                                ? Text(
                                    user.fullName.isNotEmpty
                                        ? user.fullName
                                              .substring(0, 1)
                                              .toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      color: isAdmin
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            user.fullName,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Joined ${user.createdAt.toLocal().toString().split(' ')[0]}',
                            style: AppTypography.captionMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _Badge(
                                text: isAdmin ? 'ADMIN' : 'PASSENGER',
                                isPrimary: isAdmin,
                              ),
                              const SizedBox(width: AppSpacing.gapSm),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: AppColors.textTertiary,
                              ),
                            ],
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
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.mutedBg,
          borderRadius: BorderRadius.circular(AppRadius.circular),
        ),
        child: Text(
          label,
          style: AppTypography.captionBold.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onCopy;

  const _DetailRow({required this.label, required this.value, this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.captionBlack.copyWith(
            color: AppColors.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (onCopy != null)
              IconButton(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 16),
                tooltip: 'Copy',
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    );
  }
}

class _AdminDataHealth extends StatelessWidget {
  final NoticeController controller;

  const _AdminDataHealth({required this.controller});

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: controller.reload,
    color: AppColors.primary,
    child: ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SOURCE HEALTH (${controller.sourceHealth.length})',
              style: AppTypography.captionBlack,
            ),
            Text(
              '${controller.sourceHealth.where((s) => s.status == 'healthy').length} healthy',
              style: AppTypography.captionMedium.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.gapMd),
        for (final source in controller.sourceHealth)
          _SourceHealthCard(source: source),
      ],
    ),
  );
}

class _SourceHealthCard extends StatelessWidget {
  final SourceHealth source;

  const _SourceHealthCard({required this.source});

  @override
  Widget build(BuildContext context) {
    final isRealtimeStale =
        source.type == 'realtime' &&
        DateTime.now().toUtc().difference(source.checkedAt.toUtc()) >
            const Duration(minutes: 5);
    final displayStatus = isRealtimeStale ? 'stale' : source.status;

    final statusColor = displayStatus == 'healthy'
        ? AppColors.success
        : displayStatus == 'stale'
        ? AppColors.amber
        : displayStatus == 'unconfigured'
        ? AppColors.textTertiary
        : AppColors.severityCriticalColor;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.gapMd),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.borderLight),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.gapLg,
          vertical: AppSpacing.gapSm,
        ),
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.gapSm),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            displayStatus == 'healthy'
                ? Icons.check_circle_rounded
                : displayStatus == 'stale'
                ? Icons.access_time_rounded
                : displayStatus == 'unconfigured'
                ? Icons.settings_outlined
                : Icons.warning_rounded,
            color: statusColor,
            size: 22,
          ),
        ),
        title: Text(
          source.displayName,
          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${source.type.toUpperCase()} · ${displayStatus.toUpperCase()}',
              style: AppTypography.captionBold.copyWith(color: statusColor),
            ),
            const SizedBox(height: 2),
            Text(
              'Last checked ${source.checkedAt.toLocal().toString().split('.')[0]}',
              style: AppTypography.captionMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              source.details,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: source.recordCount == null
            ? null
            : Text(
                '${source.recordCount} rows',
                style: AppTypography.captionMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: 155,
    padding: const EdgeInsets.all(AppSpacing.cardPadding),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.borderLight),
      boxShadow: AppShadows.card,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: AppSpacing.gapMd),
        Text(value, style: AppTypography.monoLarge),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.captionMedium.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: AppSpacing.gapMd),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: const BorderSide(color: AppColors.borderLight),
    ),
    child: ListTile(
      leading: Icon(icon, color: AppColors.secondary),
      title: Text(
        title,
        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        body,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
    ),
  );
}

class _Badge extends StatelessWidget {
  final String text;
  final bool isPrimary;

  const _Badge({required this.text, this.isPrimary = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: isPrimary ? AppColors.primaryLight : AppColors.mutedBg,
      borderRadius: BorderRadius.circular(AppRadius.xs),
    ),
    child: Text(
      text,
      style: AppTypography.captionBold.copyWith(
        color: isPrimary ? AppColors.primary : AppColors.textSecondary,
        fontSize: 10,
      ),
    ),
  );
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/notice_models.dart';
import '../../../shared/models/transit_models.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../alerts/application/notice_controller.dart';
import '../../transit_network/application/transit_network_controller.dart';

class AdminDashboardScreen extends StatelessWidget {
  final NoticeController controller;
  final TransitNetworkController transitController;
  final VoidCallback onBack;

  const AdminDashboardScreen({
    super.key,
    required this.controller,
    required this.transitController,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([controller, transitController]),
      builder: (context, _) {
        if (!controller.isAdmin) {
          return Column(
            children: [
              AppPageHeader(title: 'Admin workspace', onBack: onBack),
              const Expanded(
                child: Center(
                  child: Text('Your account is not authorized as an admin.'),
                ),
              ),
            ],
          );
        }
        return DefaultTabController(
          length: 4,
          child: Column(
            children: [
              AppPageHeader(
                title: 'Admin workspace',
                subtitle: 'SmartRoute operations',
                onBack: onBack,
                action: IconButton(
                  tooltip: 'Refresh workspace',
                  onPressed: controller.reload,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ),
              const Material(
                color: AppColors.surface,
                child: TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Overview'),
                    Tab(text: 'Notices'),
                    Tab(text: 'Data health'),
                    Tab(text: 'Users'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _Overview(
                      controller: controller,
                      network: transitController.network,
                    ),
                    _Notices(
                      controller: controller,
                      network: transitController.network,
                    ),
                    _DataHealth(controller: controller),
                    _Users(controller: controller),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Overview extends StatelessWidget {
  final NoticeController controller;
  final TransitNetwork? network;

  const _Overview({required this.controller, required this.network});

  @override
  Widget build(BuildContext context) {
    final active = controller.notices
        .where((notice) => notice.isActiveAt(DateTime.now()))
        .length;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
      children: [
        Wrap(
          spacing: AppSpacing.gapXl,
          runSpacing: AppSpacing.gapXl,
          children: [
            _MetricCard(
              label: 'ACCOUNTS',
              value: '${controller.users.length}',
              icon: Icons.people_outline_rounded,
            ),
            _MetricCard(
              label: 'ACTIVE NOTICES',
              value: '$active',
              icon: Icons.campaign_outlined,
            ),
            _MetricCard(
              label: 'NETWORK ROUTES',
              value: '${network?.metadata.routeCount ?? '—'}',
              icon: Icons.route_rounded,
            ),
            _MetricCard(
              label: 'NETWORK STOPS',
              value: '${network?.metadata.stopCount ?? '—'}',
              icon: Icons.location_on_outlined,
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
              'This workspace is visible only to accounts assigned the admin role outside the passenger app.',
        ),
        const _InfoCard(
          icon: Icons.lock_outline_rounded,
          title: 'Official data remains read-only',
          body:
              'Admins publish SmartRoute notices and inspect source freshness. Government GTFS identity is not editable here.',
        ),
      ],
    );
  }
}

class _Notices extends StatelessWidget {
  final NoticeController controller;
  final TransitNetwork? network;

  const _Notices({required this.controller, required this.network});

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          AppSpacing.sectionLg,
          AppSpacing.pageHorizontal,
          96,
        ),
        children: [
          if (controller.notices.isEmpty)
            const _InfoCard(
              icon: Icons.campaign_outlined,
              title: 'No service notices',
              body: 'Create a line-specific SmartRoute notice when needed.',
            )
          else
            for (final notice in controller.notices)
              Card(
                elevation: 0,
                child: ListTile(
                  title: Text(notice.title),
                  subtitle: Text(
                    '${notice.status.name.toUpperCase()} · ${network?.routesById[notice.routeId]?.displayName ?? notice.routeId}\n${notice.source == NoticeSource.official ? 'Official' : 'SmartRoute notice'}',
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
          onPressed: network == null ? null : () => _openEditor(context, null),
          icon: const Icon(Icons.add_rounded),
          label: const Text('New notice'),
        ),
      ),
    ],
  );

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
  late NoticeSeverity _severity;
  late NoticeStatus _status;
  DateTime? _endsAt;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.notice?.title);
    _body = TextEditingController(text: widget.notice?.body);
    _routeId = widget.notice?.routeId ?? widget.network.routes.first.id;
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
        Text(
          widget.notice == null ? 'Create service notice' : 'Edit notice',
          style: AppTypography.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sectionLg),
        TextField(
          controller: _title,
          maxLength: 120,
          decoration: const InputDecoration(labelText: 'Title'),
        ),
        const SizedBox(height: AppSpacing.gapMd),
        TextField(
          controller: _body,
          maxLength: 1000,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Commuter message'),
        ),
        const SizedBox(height: AppSpacing.gapMd),
        DropdownButtonFormField<String>(
          initialValue: _routeId,
          decoration: const InputDecoration(labelText: 'Affected route'),
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
        DropdownButtonFormField<NoticeSeverity>(
          initialValue: _severity,
          decoration: const InputDecoration(labelText: 'Severity'),
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
          decoration: const InputDecoration(labelText: 'Publication state'),
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
                : 'Expires ${_endsAt!.toLocal()}',
          ),
        ),
        const SizedBox(height: AppSpacing.sectionLg),
        FilledButton(
          onPressed: widget.controller.isSaving ? null : _save,
          child: Text(
            _status == NoticeStatus.published ? 'Publish notice' : 'Save draft',
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
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) return;
    final success = await widget.controller.saveNotice(
      id: widget.notice?.id,
      title: _title.text,
      body: _body.text,
      severity: _severity,
      routeId: _routeId,
      startsAt: widget.notice?.startsAt ?? DateTime.now(),
      endsAt: _endsAt,
      status: _status,
    );
    if (success && mounted) Navigator.of(context).pop();
  }
}

class _DataHealth extends StatelessWidget {
  final NoticeController controller;

  const _DataHealth({required this.controller});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
    children: [
      for (final source in controller.sourceHealth)
        _SourceHealthCard(source: source),
    ],
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
    return Card(
      elevation: 0,
      child: ListTile(
        leading: Icon(
          displayStatus == 'healthy'
              ? Icons.check_circle_rounded
              : displayStatus == 'unconfigured'
              ? Icons.settings_outlined
              : Icons.warning_rounded,
          color: displayStatus == 'healthy'
              ? AppColors.success
              : AppColors.amber,
        ),
        title: Text(source.displayName),
        subtitle: Text(
          '${source.type.toUpperCase()} · ${displayStatus.toUpperCase()}\n'
          'Last checked ${source.checkedAt.toLocal()}\n${source.details}',
        ),
        isThreeLine: true,
        trailing: source.recordCount == null
            ? null
            : Text('${source.recordCount}'),
      ),
    );
  }
}

class _Users extends StatelessWidget {
  final NoticeController controller;

  const _Users({required this.controller});

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.all(AppSpacing.pageHorizontal),
    itemCount: controller.users.length,
    itemBuilder: (context, index) {
      final user = controller.users[index];
      return ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person_outline_rounded)),
        title: Text(user.fullName),
        subtitle: Text('Joined ${user.createdAt.toLocal()}'),
      );
    },
  );
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
    width: 160,
    padding: const EdgeInsets.all(AppSpacing.cardPadding),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.borderLight),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: AppSpacing.gapMd),
        Text(value, style: AppTypography.monoLarge),
        Text(label, style: AppTypography.captionMedium),
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
    child: ListTile(
      leading: Icon(icon, color: AppColors.secondary),
      title: Text(title),
      subtitle: Text(body),
      isThreeLine: true,
    ),
  );
}

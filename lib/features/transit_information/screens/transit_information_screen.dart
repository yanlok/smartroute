import 'package:flutter/material.dart';

import '../../../core/constants/navigation_types.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class TransitInformationScreen extends StatefulWidget {
  final ValueChanged<AppScreen> onNavigate;

  const TransitInformationScreen({super.key, required this.onNavigate});

  @override
  State<TransitInformationScreen> createState() => _TransitInformationScreenState();
}

class _TransitInformationScreenState extends State<TransitInformationScreen> {
  _TransportType _transportType = _TransportType.bus;
  String _route = 'T250';
  String _stop = 'Wangsa Maju LRT';

  List<String> get _routes => switch (_transportType) {
        _TransportType.bus => const ['T250'],
        _TransportType.mrt => const ['MRT Kajang Line'],
        _TransportType.lrt => const ['Kelana Jaya Line'],
        _TransportType.monorail => const ['KL Monorail'],
      };

  List<String> get _stops => switch (_transportType) {
        _TransportType.bus => const ['Wangsa Maju LRT', 'PV128', 'Columbia Asia', 'TAR UMT'],
        _TransportType.mrt => const ['Cochrane MRT'],
        _TransportType.lrt => const ['Asia Jaya LRT'],
        _TransportType.monorail => const ['Bukit Bintang'],
      };

  bool get _hasRouteInformation => _transportType == _TransportType.bus;

  void _selectTransport(_TransportType transportType) {
    setState(() {
      _transportType = transportType;
      _route = _routes.first;
      _stop = _stops.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Header(),
        Expanded(
          child: Container(
            color: AppColors.background,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.sectionXxl,
                AppSpacing.pageHorizontal,
                AppSpacing.pageBottom,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _SelectionCard(
                    transportType: _transportType,
                    route: _route,
                    stop: _stop,
                    routes: _routes,
                    stops: _stops,
                    hasRouteInformation: _hasRouteInformation,
                    onTransportSelected: _selectTransport,
                    onRouteChanged: (route) => setState(() => _route = route),
                    onStopChanged: (stop) => setState(() => _stop = stop),
                    onViewInformation: () => widget.onNavigate(AppScreen.routeDetail),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pageHorizontal,
          MediaQuery.paddingOf(context).top + AppSpacing.sectionLg,
          AppSpacing.pageHorizontal,
          AppSpacing.sectionLg,
        ),
        decoration: BoxDecoration(color: AppColors.surface, boxShadow: AppShadows.header),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transit Information', style: AppTypography.headlineMedium),
            const SizedBox(height: AppSpacing.gapXs),
            Text('Find route and stop details', style: AppTypography.description.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
}

class _SelectionCard extends StatelessWidget {
  final _TransportType transportType;
  final String route;
  final String stop;
  final List<String> routes;
  final List<String> stops;
  final bool hasRouteInformation;
  final ValueChanged<_TransportType> onTransportSelected;
  final ValueChanged<String> onRouteChanged;
  final ValueChanged<String> onStopChanged;
  final VoidCallback onViewInformation;

  const _SelectionCard({
    required this.transportType,
    required this.route,
    required this.stop,
    required this.routes,
    required this.stops,
    required this.hasRouteInformation,
    required this.onTransportSelected,
    required this.onRouteChanged,
    required this.onStopChanged,
    required this.onViewInformation,
  });

  @override
  Widget build(BuildContext context) => Container(
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
            const _SectionLabel('SELECT TRANSPORT TYPE'),
            const SizedBox(height: AppSpacing.gapMd),
            Wrap(
              spacing: AppSpacing.gapSm,
              runSpacing: AppSpacing.gapSm,
              children: [
                for (final type in _TransportType.values)
                  ChoiceChip(
                    label: Text(type.label),
                    avatar: Icon(type.icon, size: 16),
                    selected: type == transportType,
                    onSelected: (_) => onTransportSelected(type),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionXl),
            const _SectionLabel('SELECT ROUTE'),
            const SizedBox(height: AppSpacing.gapMd),
            _SelectionDropdown(value: route, items: routes, onChanged: onRouteChanged),
            const SizedBox(height: AppSpacing.sectionXl),
            const _SectionLabel('SELECT STOP / STATION'),
            const SizedBox(height: AppSpacing.gapMd),
            _SelectionDropdown(value: stop, items: stops, onChanged: onStopChanged),
            const SizedBox(height: AppSpacing.sectionXl),
            if (!hasRouteInformation) ...[
              Text(
                'Detailed route information is currently available for Bus T250 only.',
                style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.gapMd),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: hasRouteInformation ? onViewInformation : null,
                child: const Text('View Information'),
              ),
            ),
          ],
        ),
      );
}

class _SelectionDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _SelectionDropdown({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        items: [
          for (final item in items)
            DropdownMenuItem(value: item, child: Text(item, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: AppTypography.captionBlack);
}

enum _TransportType {
  bus('Bus', Icons.directions_bus_rounded),
  mrt('MRT', Icons.subway_rounded),
  lrt('LRT', Icons.train_rounded),
  monorail('Monorail', Icons.tram_rounded);

  final String label;
  final IconData icon;
  const _TransportType(this.label, this.icon);
}

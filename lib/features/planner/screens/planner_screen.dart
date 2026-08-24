import '../../../core/constants/mock_data.dart';
import '../../../core/constants/navigation_types.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class PlannerScreen extends StatefulWidget {
  final void Function(AppScreen) onNavigate;
  final VoidCallback onBack;

  const PlannerScreen({
    super.key,
    required this.onNavigate,
    required this.onBack,
  });

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final _fromController = TextEditingController(text: 'Asia Jaya LRT');
  final _toController = TextEditingController();
  final _modes = {'lrt', 'mrt', 'bus'};
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _formError;

  void _toggleMode(String mode) {
    setState(() {
      if (_modes.contains(mode)) {
        _modes.remove(mode);
      } else {
        _modes.add(mode);
      }
    });
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: _selectedDate,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _findRoutes() {
    final from = _fromController.text.trim();
    final to = _toController.text.trim();
    setState(() {
      _formError = from.isEmpty
          ? 'Enter a starting station or address.'
          : to.isEmpty
          ? 'Enter a destination station or address.'
          : _modes.isEmpty
          ? 'Select at least one transport mode.'
          : null;
    });
    if (_formError == null) {
      widget.onNavigate(AppScreen.routeResults);
    }
  }

  String _dateLabel() {
    final today = DateTime.now();
    if (_selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day) {
      return 'Today';
    }
    return '${_selectedDate.day}/${_selectedDate.month}';
  }

  String _timeLabel() {
    final hour = _selectedTime.hourOfPeriod == 0
        ? 12
        : _selectedTime.hourOfPeriod;
    final minute = _selectedTime.minute.toString().padLeft(2, '0');
    final period = _selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

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
              SizedBox(height: MediaQuery.of(context).padding.top),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                      color: AppColors.textSecondary,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('Plan Journey', style: AppTypography.titleMedium),
                  ],
                ),
              ),

              // From / To inputs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Stack(
                  children: [
                    // Dashed connector line
                    Positioned(
                      left: 19,
                      top: 44,
                      bottom: 44,
                      child: CustomPaint(
                        size: const Size(0, 1),
                        painter: _DashedLinePainter(),
                      ),
                    ),

                    Column(
                      children: [
                        // From
                        _StationInput(
                          controller: _fromController,
                          dotColor: AppColors.primary,
                          icon: Icons.location_on_outlined,
                          placeholder: 'From station or address',
                        ),
                        const SizedBox(height: 10),

                        // To
                        _StationInput(
                          controller: _toController,
                          dotColor: AppColors.secondary,
                          icon: Icons.search_rounded,
                          placeholder: 'To station or address',
                        ),
                      ],
                    ),

                    // Swap button
                    Positioned(
                      right: -8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            final tmp = _fromController.text;
                            _fromController.text = _toController.text;
                            _toController.text = tmp;
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppColors.divider),
                              shape: BoxShape.circle,
                              boxShadow: AppShadows.card,
                            ),
                            child: const Icon(
                              Icons.swap_vert_rounded,
                              size: 16,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Date & Time
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _PlannerOption(
                        icon: Icons.calendar_today_rounded,
                        label: _dateLabel(),
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PlannerOption(
                        icon: Icons.access_time_rounded,
                        label: _timeLabel(),
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ),
              ),
              if (_formError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formError!,
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primary,
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
          child: Container(
            color: AppColors.background,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transport modes
                  const _SectionLabel('TRANSPORT MODES'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _modeList.map((m) {
                      final on = _modes.contains(m['id']);
                      final color = Color(
                        int.parse(
                          '0xFF${(m['color'] as String).replaceFirst('#', '')}',
                        ),
                      );
                      return GestureDetector(
                        onTap: () => _toggleMode(m['id'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: on ? color : Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: on ? color : AppColors.divider,
                            ),
                            boxShadow: on
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.27),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                m['icon'] as IconData,
                                size: 14,
                                color: on ? Colors.white : color,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                m['label'] as String,
                                style: AppTypography.captionBold.copyWith(
                                  color: on
                                      ? Colors.white
                                      : AppColors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Recent searches
                  const _SectionLabel('RECENT SEARCHES'),
                  const SizedBox(height: 10),
                  ...recentSearches.map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => widget.onNavigate(AppScreen.routeResults),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.mutedBg,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: AppColors.iconGray,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      s['from']!,
                                      style: AppTypography.bodyLarge,
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 12,
                                      color: AppColors.iconGray,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      s['to']!,
                                      style: AppTypography.bodyLarge,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: Color(0xFFD1D5DB),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Popular destinations
                  const _SectionLabel('POPULAR DESTINATIONS'),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 3.2,
                    children: popularDestinations.map((d) {
                      return InkWell(
                        onTap: () {
                          _toController.text = d['name']!;
                          setState(() => _formError = null);
                        },
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _destinationIcon(d['name']!),
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                d['name']!,
                                style: AppTypography.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),

        // ── CTA ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          color: AppColors.background,
          child: GestureDetector(
            onTap: _findRoutes,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.gradientPrimary,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.ctaButton,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text('Find Best Routes', style: AppTypography.bodyLarge),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlannerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PlannerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.mutedBg,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Icon(icon, size: 14, color: AppColors.mutedForeground),
              const SizedBox(width: 8),
              Flexible(child: Text(label, style: AppTypography.bodySmall)),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _destinationIcon(String name) {
  switch (name) {
    case 'KLCC':
      return Icons.business_rounded;
    case 'Bukit Bintang':
      return Icons.shopping_bag_rounded;
    case 'Mid Valley':
      return Icons.storefront_rounded;
    default:
      return Icons.place_rounded;
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────

final _modeList = [
  {
    'id': 'lrt',
    'label': 'LRT',
    'color': '#009FE3',
    'icon': Icons.train_rounded,
  },
  {
    'id': 'mrt',
    'label': 'MRT',
    'color': '#003087',
    'icon': Icons.train_rounded,
  },
  {
    'id': 'bus',
    'label': 'Bus',
    'color': '#F59E0B',
    'icon': Icons.directions_bus_rounded,
  },
  {
    'id': 'monorail',
    'label': 'Monorail',
    'color': '#7C3AED',
    'icon': Icons.train_rounded,
  },
  {
    'id': 'brt',
    'label': 'BRT',
    'color': '#F97316',
    'icon': Icons.directions_bus_rounded,
  },
];

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.captionBlack);
  }
}

class _StationInput extends StatelessWidget {
  final TextEditingController controller;
  final Color dotColor;
  final IconData icon;
  final String placeholder;

  const _StationInput({
    required this.controller,
    required this.dotColor,
    required this.icon,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.mutedBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: dotColor.withValues(alpha: 0.25),
                  blurRadius: 4,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: placeholder,
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.iconGray,
                ),
              ),
            ),
          ),
          Icon(icon, size: 16, color: AppColors.iconGray),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 2;
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double startY = 0;
    final height = 60.0;
    while (startY < height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

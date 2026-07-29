import 'package:flutter/material.dart';

/// Provides the top system status bar padding for screens.
///
/// On screens with gradient/tinted backgrounds, the [color] extends
/// behind the system status bar so the visual flows edge-to-edge.
///
/// Use [child] to wrap content that should start below the status bar.
///
/// Replaces the React prototype's simulated iOS status bar — in a real
/// Flutter app the device provides its own status bar, so we only need
/// the correct padding and background color.
class StatusBar extends StatelessWidget {
  final Color? color;
  final Widget? child;

  const StatusBar({super.key, this.color, this.child});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // System status bar spacer with background
        Container(
          height: topPadding,
          color: color,
        ),
        if (child != null) child!,
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/core/theme/app_colors.dart';
import 'package:smartroute/features/tracking/domain/models/transit_line.dart';
import 'package:smartroute/features/tracking/domain/models/transit_mode.dart';
import 'package:smartroute/features/tracking/presentation/widgets/line_picker_tile.dart';

void main() {
  group('LinePickerTile', () {
    TransitLine makeLine() => const TransitLine(
      id: 'kj',
      code: 'KJ',
      name: 'Kelana Jaya Line',
      mode: TransitMode.lrt,
      colorToken: 'kjLine',
      orderedStationIds: <String>[],
    );

    testWidgets('renders the line name and station count', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LinePickerTile(
              line: makeLine(),
              stationCount: 37,
              statusLabel: 'On Time',
              statusColor: AppColors.statusOnTimeText,
              statusBackground: AppColors.statusOnTimeBg,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );
      expect(find.text('Kelana Jaya Line'), findsOneWidget);
      expect(find.text('37 stations'), findsOneWidget);
      expect(find.text('On Time'), findsOneWidget);

      await tester.tap(find.byType(LinePickerTile));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}

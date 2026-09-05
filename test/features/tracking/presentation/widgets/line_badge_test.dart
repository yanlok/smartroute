import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/tracking/presentation/widgets/line_badge.dart';

void main() {
  group('LineBadge', () {
    testWidgets('renders the code and uses the resolved color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LineBadge(code: 'KJ', colorToken: 'kjLine'),
            ),
          ),
        ),
      );
      expect(find.text('KJ'), findsOneWidget);
    });

    testWidgets('falls back to primary color for unknown token', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LineBadge(code: 'XX', colorToken: 'not-a-real-token'),
            ),
          ),
        ),
      );
      expect(find.text('XX'), findsOneWidget);
    });
  });
}

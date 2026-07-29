import 'package:flutter_test/flutter_test.dart';

import 'package:smartroute/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartRouteApp());
    await tester.pump();

    // Verify the app renders without errors
    expect(find.byType(SmartRouteApp), findsOneWidget);
  });
}

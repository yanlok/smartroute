import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smartroute/core/constants/navigation_types.dart';
import 'package:smartroute/features/route_detail/screens/route_detail_screen.dart';
import 'package:smartroute/features/transit_information/screens/transit_information_screen.dart';
import 'package:smartroute/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartRouteApp());
    await tester.pump();

    // Verify the app renders without errors
    expect(find.byType(SmartRouteApp), findsOneWidget);
  });

  testWidgets('Transit information opens T250 route details',
      (WidgetTester tester) async {
    AppScreen? requestedScreen;

    await tester.pumpWidget(
      MaterialApp(
        home: TransitInformationScreen(
          onNavigate: (screen) => requestedScreen = screen,
        ),
      ),
    );

    expect(find.text('Transit Information'), findsOneWidget);
    expect(find.text('T250'), findsOneWidget);
    expect(find.text('Wangsa Maju LRT'), findsOneWidget);

    await tester.tap(find.text('View Information'));

    expect(requestedScreen, AppScreen.routeDetail);
  });

  testWidgets('Route details adds T250 to favourites',
      (WidgetTester tester) async {
    bool? favouriteValue;

    await tester.pumpWidget(
      MaterialApp(
        home: RouteDetailScreen(
          isFavourite: false,
          onFavouriteChanged: (value) => favouriteValue = value,
          onBack: () {},
        ),
      ),
    );

    expect(find.text('FACILITIES'), findsNothing);
    expect(find.text('Track this service'), findsNothing);

    await tester.tap(find.text('Add to favourite'));

    expect(favouriteValue, isTrue);
  });
}

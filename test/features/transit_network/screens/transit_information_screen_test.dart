import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/alerts/application/notice_controller.dart';
import 'package:smartroute/features/transit_information/screens/station_details_screen.dart';
import 'package:smartroute/features/transit_information/screens/transit_information_screen.dart';
import 'package:smartroute/features/transit_network/application/transit_network_controller.dart';
import 'package:smartroute/features/user_management/application/saved_journey_controller.dart';
import 'package:smartroute/features/user_management/domain/models/saved_journey.dart';
import 'package:smartroute/features/user_management/domain/repositories/saved_journey_repository.dart';
import 'package:smartroute/shared/contracts/notice_repository.dart';
import 'package:smartroute/shared/contracts/transit_network_repository.dart';
import 'package:smartroute/shared/models/notice_models.dart';
import 'package:smartroute/shared/models/transit_models.dart';
import 'package:smartroute/shared/models/journey_models.dart';

void main() {
  testWidgets(
    'TransitInformationScreen renders network exploration map, mode rail, and route cards',
    (tester) async {
      final network = _network();
      final transitController = TransitNetworkController(
        repository: _FakeTransitRepo(network),
      );
      final noticeController = NoticeController(repository: _FakeNoticeRepo());
      final savedJourneys = SavedJourneyController(
        repository: _FakeSavedJourneyRepo(),
      );

      var progressRouteId = '';

      await tester.pumpWidget(
        MaterialApp(
          home: TransitInformationScreen(
            controller: transitController,
            notices: noticeController,
            userId: 'user-1',
            savedJourneys: savedJourneys,
            onOpenProgress: (routeId) {
              progressRouteId = routeId;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Explore Network'), findsOneWidget);
      expect(find.text('Search line, station or route'), findsOneWidget);

      expect(find.text('All'), findsOneWidget);
      expect(find.text('LRT'), findsOneWidget);
      expect(find.text('MRT'), findsOneWidget);
      expect(find.text('Bus'), findsOneWidget);

      expect(find.text('Kelana Jaya Line'), findsOneWidget);
      expect(find.text('5 stations'), findsOneWidget);

      await tester.tap(find.text('Kelana Jaya Line'));
      await tester.pumpAndSettle();

      expect(find.text('Track Live Route'), findsOneWidget);
      expect(find.text('Origin Station'), findsOneWidget);
      expect(find.text('Destination Station'), findsOneWidget);

      await tester.tap(find.text('Track Live Route'));
      await tester.pump();

      expect(progressRouteId, 'rapid-rail-kl:KJ');

      transitController.dispose();
      noticeController.dispose();
      savedJourneys.dispose();
    },
  );

  testWidgets('opens station details from the station search', (tester) async {
    final network = _network();
    final transitController = TransitNetworkController(
      repository: _FakeTransitRepo(network),
    );
    final noticeController = NoticeController(repository: _FakeNoticeRepo());
    final savedJourneys = SavedJourneyController(
      repository: _FakeSavedJourneyRepo(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TransitInformationScreen(
          controller: transitController,
          notices: noticeController,
          userId: 'user-1',
          savedJourneys: savedJourneys,
          onOpenProgress: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('View Full Map'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Destination');
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Destination Station'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('View on map'), findsNothing);
    expect(find.text('View on Map'), findsNothing);
    expect(find.byTooltip('Arrival reminder ready'), findsNothing);
    final stationDetails = find.byType(StationDetailsScreen);
    final stationDetailsList = find.descendant(
      of: stationDetails,
      matching: find.byType(ListView),
    );
    final stationDetailsScroller = find
        .descendant(of: stationDetailsList, matching: find.byType(Scrollable))
        .first;
    final stationInformation = find.descendant(
      of: stationDetails,
      matching: find.text('STATION INFORMATION'),
    );
    await tester.scrollUntilVisible(
      stationInformation,
      160,
      scrollable: stationDetailsScroller,
    );
    expect(stationInformation, findsOneWidget);
    expect(find.text('Scheduled service hours'), findsOneWidget);
    expect(find.text('FACILITIES'), findsNothing);
    expect(find.text('Kelana Jaya Line'), findsAtLeastNWidgets(1));
    expect(find.text('UPCOMING ARRIVALS'), findsNothing);
    expect(find.text('ARRIVAL REMINDER'), findsNothing);
    expect(find.text('Remind Me'), findsNothing);
    expect(find.byTooltip('Add favourite station'), findsOneWidget);
    expect(find.text('PREVIOUS & NEXT STOPS'), findsOneWidget);
    expect(find.text('Previous stop'), findsOneWidget);
    expect(find.text('Origin Station'), findsOneWidget);
    expect(find.text('Third Station'), findsOneWidget);
    expect(find.text('Fourth Station'), findsOneWidget);
    expect(find.text('Fifth Station'), findsOneWidget);
    await tester.tap(find.byTooltip('Add favourite station'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove favourite station'), findsOneWidget);
    expect(
      savedJourneys.containsStation('rapid-rail-kl:S2', 'rapid-rail-kl:KJ'),
      isTrue,
    );
    transitController.dispose();
    noticeController.dispose();
    savedJourneys.dispose();
  });
}

class _FakeTransitRepo implements TransitNetworkRepository {
  final TransitNetwork network;
  _FakeTransitRepo(this.network);

  @override
  Future<TransitNetwork> loadNetwork() async => network;
}

class _FakeSavedJourneyRepo implements SavedJourneyRepository {
  final List<FavoriteStation> stations = [];

  @override
  Future<void> deleteFavorite(String favoriteId) async {}

  @override
  Future<void> deleteFavoriteStation(String favoriteId) async {
    stations.removeWhere((station) => station.id == favoriteId);
  }

  @override
  Future<List<FavoriteStation>> getFavoriteStations(String userId) async =>
      List.unmodifiable(stations);

  @override
  Future<List<FavoriteJourney>> getFavorites(String userId) async => [];

  @override
  Future<List<RecentJourney>> getRecentSearches(String userId) async => [];

  @override
  Future<RecentJourney> recordSearch({
    required String userId,
    required String originStopId,
    required String destinationStopId,
  }) => throw UnimplementedError();

  @override
  Future<FavoriteJourney> saveFavorite({
    required String userId,
    required String label,
    required String originStopId,
    required String destinationStopId,
    required RouteObjective objective,
  }) => throw UnimplementedError();

  @override
  Future<FavoriteStation> saveFavoriteStation({
    required String userId,
    required String stationId,
    required String routeId,
    required String label,
  }) async {
    final favorite = FavoriteStation(
      id: 'favorite-station',
      userId: userId,
      stationId: stationId,
      routeId: routeId,
      label: label,
      updatedAt: DateTime(2026),
    );
    stations.add(favorite);
    return favorite;
  }
}

class _FakeNoticeRepo implements NoticeRepository {
  @override
  Future<bool> isAdmin(String userId) async => false;

  @override
  Future<List<ServiceNotice>> getNotices() async => [];

  @override
  Future<Set<String>> getReadNoticeIds(String userId) async => {};

  @override
  Future<Set<String>> getSubscribedRouteIds(String userId) async => {};

  @override
  Future<void> archiveNotice(String noticeId) async {}

  @override
  Future<List<SourceHealth>> getSourceHealth() async => [];

  @override
  Future<List<AdminUserSummary>> getUsers() async => [];

  @override
  Future<void> markRead({
    required String userId,
    required String noticeId,
  }) async {}

  @override
  Future<ServiceNotice> saveNotice({
    String? id,
    required String userId,
    required String title,
    required String body,
    required NoticeCategory category,
    required NoticeSeverity severity,
    required String routeId,
    required DateTime startsAt,
    DateTime? endsAt,
    required NoticeStatus status,
  }) => throw UnimplementedError();

  @override
  Future<void> setSubscription({
    required String userId,
    required String routeId,
    required bool enabled,
  }) async {}
}

TransitNetwork _network({int startSeconds = 0, int endSeconds = 86400}) =>
    TransitNetwork(
      metadata: TransitMetadata(
        generatedAt: DateTime.now(),
        publisher: 'data.gov.my',
        licence: 'Open',
        routeCount: 1,
        stopCount: 5,
        edgeCount: 1,
        patternCount: 1,
        shapeRouteCount: 1,
        sources: const [],
      ),
      routes: const [
        TransitRoute(
          id: 'rapid-rail-kl:KJ',
          gtfsId: 'KJ',
          source: 'rapid-rail-kl',
          shortName: 'KJ',
          longName: 'Kelana Jaya Line',
          mode: TransitMode.lrt,
          colorHex: '009FE3',
          operatorName: 'Rapid KL',
          shape: [TransitCoordinate(3, 101), TransitCoordinate(3.1, 101.1)],
        ),
      ],
      stops: const [
        TransitStop(
          id: 'rapid-rail-kl:S1',
          gtfsId: 'S1',
          source: 'rapid-rail-kl',
          name: 'Origin Station',
          latitude: 3,
          longitude: 101,
          routeIds: ['rapid-rail-kl:KJ'],
        ),
        TransitStop(
          id: 'rapid-rail-kl:S3',
          gtfsId: 'S3',
          source: 'rapid-rail-kl',
          name: 'Third Station',
          latitude: 3.2,
          longitude: 101.2,
          routeIds: ['rapid-rail-kl:KJ'],
        ),
        TransitStop(
          id: 'rapid-rail-kl:S4',
          gtfsId: 'S4',
          source: 'rapid-rail-kl',
          name: 'Fourth Station',
          latitude: 3.3,
          longitude: 101.3,
          routeIds: ['rapid-rail-kl:KJ'],
        ),
        TransitStop(
          id: 'rapid-rail-kl:S5',
          gtfsId: 'S5',
          source: 'rapid-rail-kl',
          name: 'Fifth Station',
          latitude: 3.4,
          longitude: 101.4,
          routeIds: ['rapid-rail-kl:KJ'],
        ),
        TransitStop(
          id: 'rapid-rail-kl:S2',
          gtfsId: 'S2',
          source: 'rapid-rail-kl',
          name: 'Destination Station',
          latitude: 3.1,
          longitude: 101.1,
          routeIds: ['rapid-rail-kl:KJ'],
        ),
      ],
      edges: const [],
      patterns: [
        TransitPattern(
          id: 'rapid-rail-kl:KJ:p1',
          routeId: 'rapid-rail-kl:KJ',
          gtfsTripId: 'trip-1',
          direction: 0,
          headsign: 'Destination Station',
          stopIds: [
            'rapid-rail-kl:S1',
            'rapid-rail-kl:S2',
            'rapid-rail-kl:S3',
            'rapid-rail-kl:S4',
            'rapid-rail-kl:S5',
          ],
          offsetMinutes: [0, 10, 20, 30, 40],
          startSeconds: startSeconds,
          endSeconds: endSeconds,
          headwaySeconds: 300,
        ),
      ],
    );

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartroute/features/alerts/application/notice_controller.dart';
import 'package:smartroute/features/home/screens/home_screen.dart';
import 'package:smartroute/features/transit_network/application/transit_network_controller.dart';
import 'package:smartroute/features/user_management/application/profile_controller.dart';
import 'package:smartroute/features/user_management/application/saved_journey_controller.dart';
import 'package:smartroute/features/user_management/domain/models/app_user.dart';
import 'package:smartroute/features/user_management/domain/models/saved_journey.dart';
import 'package:smartroute/features/user_management/domain/models/user_preferences.dart';
import 'package:smartroute/features/user_management/domain/models/user_profile.dart';
import 'package:smartroute/features/user_management/domain/repositories/profile_repository.dart';
import 'package:smartroute/features/user_management/domain/repositories/saved_journey_repository.dart';
import 'package:smartroute/shared/contracts/notice_repository.dart';
import 'package:smartroute/shared/contracts/transit_network_repository.dart';
import 'package:smartroute/shared/models/journey_models.dart';
import 'package:smartroute/shared/models/notice_models.dart';
import 'package:smartroute/shared/models/transit_models.dart';

void main() {
  testWidgets('Home aggregates persisted journeys notices and network data', (
    tester,
  ) async {
    final network = _network();
    final profile = ProfileController(profileRepository: _ProfileRepository());
    final journeys = SavedJourneyController(repository: _JourneyRepository());
    final notices = NoticeController(repository: _NoticeRepository());
    final transit = TransitNetworkController(
      repository: _NetworkRepository(network),
    );
    await notices.load(userId: 'user-1', notificationsEnabled: true);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            authUser: const AppUser(
              id: 'user-1',
              fullName: 'Jane Commuter',
              email: 'jane@example.com',
            ),
            profileController: profile,
            savedJourneys: journeys,
            notices: notices,
            transitController: transit,
            onPlan: () {},
            onAlerts: () {},
            onTransit: () {},
            onReplan: (_, _) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Jane Commuter'), findsOneWidget);
    expect(find.text('Kelana Jaya maintenance'), findsOneWidget);
    expect(find.text('Home to campus'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.text('Origin Station → Destination Station'), findsOneWidget);
    expect(find.text('1 routes · 2 stops and stations'), findsOneWidget);

    profile.dispose();
    journeys.dispose();
    notices.dispose();
    transit.dispose();
  });
}

class _ProfileRepository implements ProfileRepository {
  @override
  Future<UserProfile> getProfile({required String userId}) async =>
      UserProfile(id: userId, fullName: 'Jane Commuter');

  @override
  Future<UserPreferences> getPreferences({required String userId}) async =>
      const UserPreferences();

  @override
  Future<UserProfile> updateProfile({
    required String userId,
    required String fullName,
    String? photoUrl,
  }) async => UserProfile(id: userId, fullName: fullName, photoUrl: photoUrl);

  @override
  Future<UserPreferences> updatePreferences({
    required String userId,
    required UserPreferences preferences,
  }) async => preferences;
}

class _JourneyRepository implements SavedJourneyRepository {
  @override
  Future<List<FavoriteJourney>> getFavorites(String userId) async => [
    FavoriteJourney(
      id: 'favorite-1',
      userId: userId,
      label: 'Home to campus',
      originStopId: 'rapid-rail-kl:S1',
      destinationStopId: 'rapid-rail-kl:S2',
      objective: RouteObjective.fastest,
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Future<List<RecentJourney>> getRecentSearches(String userId) async => [
    RecentJourney(
      id: 'recent-1',
      userId: userId,
      originStopId: 'rapid-rail-kl:S1',
      destinationStopId: 'rapid-rail-kl:S2',
      searchedAt: DateTime.now(),
    ),
  ];

  @override
  Future<void> deleteFavorite(String favoriteId) async {}

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
}

class _NoticeRepository implements NoticeRepository {
  @override
  Future<bool> isAdmin(String userId) async => false;

  @override
  Future<List<ServiceNotice>> getNotices() async => [
    ServiceNotice(
      id: 'notice-1',
      title: 'Kelana Jaya maintenance',
      body: 'Allow additional travel time.',
      severity: NoticeSeverity.warning,
      source: NoticeSource.smartRoute,
      routeId: 'rapid-rail-kl:KJ',
      startsAt: DateTime.now().subtract(const Duration(hours: 1)),
      endsAt: DateTime.now().add(const Duration(hours: 1)),
      status: NoticeStatus.published,
      createdBy: 'admin-1',
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Future<Set<String>> getReadNoticeIds(String userId) async => {};

  @override
  Future<Set<String>> getSubscribedRouteIds(String userId) async => {
    'rapid-rail-kl:KJ',
  };

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

class _NetworkRepository implements TransitNetworkRepository {
  final TransitNetwork network;

  const _NetworkRepository(this.network);

  @override
  Future<TransitNetwork> loadNetwork() async => network;
}

TransitNetwork _network() => TransitNetwork(
  metadata: TransitMetadata(
    generatedAt: DateTime.now(),
    publisher: 'data.gov.my',
    licence: 'Open',
    routeCount: 1,
    stopCount: 2,
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
  patterns: const [],
);

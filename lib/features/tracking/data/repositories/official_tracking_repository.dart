import 'dart:async';
import 'dart:math' as math;

import '../../../../shared/contracts/transit_network_repository.dart';
import '../../../../shared/models/transit_models.dart';
import '../../domain/exceptions/tracking_repository_exception.dart';
import '../../domain/models/arrival_estimate.dart';
import '../../domain/models/line_status.dart';
import '../../domain/models/live_vehicle.dart';
import '../../domain/models/platform_info.dart';
import '../../domain/models/transit_direction.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/official_gtfs_realtime_data_source.dart';

class OfficialTrackingRepository implements TrackingRepository {
  final TransitNetworkRepository _networkRepository;
  final OfficialGtfsRealtimeDataSource _realtimeDataSource;
  final DateTime Function() _clock;

  OfficialTrackingRepository({
    required TransitNetworkRepository networkRepository,
    OfficialGtfsRealtimeDataSource? realtimeDataSource,
    DateTime Function()? clock,
  }) : _networkRepository = networkRepository,
       _realtimeDataSource =
           realtimeDataSource ?? OfficialGtfsRealtimeDataSource(),
       _clock = clock ?? DateTime.now;

  @override
  Stream<List<LiveVehicle>> watchVehicles(
    String lineId, {
    Duration tickInterval = const Duration(milliseconds: 300),
  }) async* {
    final network = await _networkRepository.loadNetwork();
    final route = network.routesById[lineId];
    if (route == null) {
      throw TrackingRepositoryException('The selected route was not found.');
    }
    if (route.mode != TransitMode.bus && route.mode != TransitMode.brt) {
      yield const <LiveVehicle>[];
      return;
    }
    await for (final snapshots in _realtimeDataSource.watchVehicles(
      route.source,
    )) {
      final now = _clock().toUtc();
      yield [
        for (final snapshot in snapshots)
          if (snapshot.routeId == route.gtfsId &&
              now.difference(snapshot.timestamp).abs() <=
                  const Duration(minutes: 2))
            _mapVehicle(snapshot, route),
      ];
    }
  }

  @override
  Stream<List<ArrivalEstimate>> watchArrivals({
    required String lineId,
    required String stationId,
    Duration tickInterval = const Duration(seconds: 10),
  }) async* {
    final network = await _networkRepository.loadNetwork();
    final pattern = network.patternForRouteAndStop(lineId, stationId);
    if (pattern == null) {
      yield const <ArrivalEstimate>[];
      return;
    }
    final next = pattern.nextDeparture(stationId, _clock());
    if (next == null) {
      yield const <ArrivalEstimate>[];
      return;
    }
    final minutes = math.max(0, next.difference(_clock()).inMinutes);
    yield <ArrivalEstimate>[
      ArrivalEstimate(
        stationId: stationId,
        platformCode: pattern.headsign.isEmpty
            ? 'Scheduled service'
            : 'Towards ${pattern.headsign}',
        lineId: lineId,
        vehicleId: pattern.gtfsTripId,
        etaMinutes: minutes,
        isLive: false,
      ),
    ];
  }

  @override
  Future<LineStatus> getLineStatus(String lineId) async {
    final network = await _networkRepository.loadNetwork();
    if (!network.routesById.containsKey(lineId)) {
      throw TrackingRepositoryException('The selected route was not found.');
    }
    return LineStatus.onTime(lineId: lineId, at: _clock());
  }

  @override
  Future<List<PlatformInfo>> getPlatforms(String stationId) async => const [];

  LiveVehicle _mapVehicle(
    RealtimeVehicleSnapshot snapshot,
    TransitRoute route,
  ) {
    return LiveVehicle(
      vehicleId: snapshot.vehicleId,
      lineId: route.id,
      direction: snapshot.directionId == 1
          ? TransitDirection.reverse
          : TransitDirection.forward,
      positionFraction: _positionFraction(
        route.shape,
        snapshot.latitude,
        snapshot.longitude,
      ),
      etaMinutes: 0,
      lastUpdated: snapshot.timestamp,
      isLive: true,
      latitude: snapshot.latitude,
      longitude: snapshot.longitude,
      tripId: snapshot.tripId,
      label: snapshot.label,
    );
  }

  double _positionFraction(
    List<TransitCoordinate> shape,
    double latitude,
    double longitude,
  ) {
    if (shape.length < 2) return 0;
    var nearestIndex = 0;
    var nearestDistance = double.infinity;
    for (var index = 0; index < shape.length; index++) {
      final point = shape[index];
      final latDelta = point.latitude - latitude;
      final lonDelta = point.longitude - longitude;
      final distance = latDelta * latDelta + lonDelta * lonDelta;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = index;
      }
    }
    return nearestIndex / (shape.length - 1);
  }
}

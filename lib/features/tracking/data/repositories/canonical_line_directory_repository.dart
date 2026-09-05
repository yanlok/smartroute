import '../../../../shared/contracts/transit_network_repository.dart';
import '../../../../shared/models/transit_models.dart' as shared;
import '../../domain/models/tracking_station.dart';
import '../../domain/models/transit_line.dart';
import '../../domain/models/transit_mode.dart';
import '../../domain/repositories/line_directory_repository.dart';

class CanonicalLineDirectoryRepository implements LineDirectoryRepository {
  final TransitNetworkRepository _networkRepository;

  const CanonicalLineDirectoryRepository(this._networkRepository);

  @override
  Future<List<TransitLine>> getLines() async {
    final network = await _networkRepository.loadNetwork();
    return [for (final route in network.routes) _line(route, network)];
  }

  @override
  Future<List<TrackingStation>> getAllStations() async {
    final network = await _networkRepository.loadNetwork();
    return [for (final route in network.routes) ..._stations(route, network)];
  }

  @override
  Future<TransitLine?> getLineById(String lineId) async {
    final network = await _networkRepository.loadNetwork();
    final route = network.routesById[lineId];
    return route == null ? null : _line(route, network);
  }

  @override
  Future<TrackingStation?> getStationById({
    required String lineId,
    required String stationId,
  }) async {
    final stations = await getStationsForLine(lineId);
    for (final station in stations) {
      if (station.id == stationId) return station;
    }
    return null;
  }

  @override
  Future<List<TrackingStation>> getStationsForLine(String lineId) async {
    final network = await _networkRepository.loadNetwork();
    final route = network.routesById[lineId];
    return route == null ? const [] : _stations(route, network);
  }

  TransitLine _line(shared.TransitRoute route, shared.TransitNetwork network) {
    final stationIds = _orderedStationIds(route, network);
    return TransitLine(
      id: route.id,
      code: route.shortName,
      name: route.displayName,
      mode: _mode(route.mode),
      colorToken: route.colorHex,
      orderedStationIds: stationIds,
    );
  }

  List<TrackingStation> _stations(
    shared.TransitRoute route,
    shared.TransitNetwork network,
  ) {
    final ids = _orderedStationIds(route, network);
    return [
      for (var index = 0; index < ids.length; index++)
        if (network.stopsById[ids[index]] case final stop?)
          TrackingStation(
            id: stop.id,
            name: stop.name,
            lineId: route.id,
            sequence: index,
            latitude: stop.latitude,
            longitude: stop.longitude,
          ),
    ];
  }

  List<String> _orderedStationIds(
    shared.TransitRoute route,
    shared.TransitNetwork network,
  ) {
    for (final pattern in network.patterns) {
      if (pattern.routeId == route.id && pattern.stopIds.isNotEmpty) {
        return pattern.stopIds;
      }
    }
    return [
      for (final stop in network.stops)
        if (stop.routeIds.contains(route.id)) stop.id,
    ];
  }

  TransitMode _mode(shared.TransitMode mode) => switch (mode) {
    shared.TransitMode.lrt => TransitMode.lrt,
    shared.TransitMode.mrt => TransitMode.mrt,
    shared.TransitMode.monorail => TransitMode.monorail,
    shared.TransitMode.brt => TransitMode.brt,
    shared.TransitMode.bus => TransitMode.bus,
  };
}

import '../../domain/exceptions/tracking_repository_exception.dart';
import '../../domain/models/arrival_estimate.dart';
import '../../domain/models/live_vehicle.dart';
import '../../domain/models/line_status.dart';
import '../../domain/models/platform_info.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/mock_tracking_data_source.dart';
import 'line_directory_repository_impl.dart';

/// Thin wrapper around [MockTrackingDataSource] that converts any
/// unexpected error into a [TrackingRepositoryException] before
/// it reaches the application layer. For an in-app mock the
/// only realistic failure modes are programming errors, so the
/// guard is defensive — but it keeps the contract honest for a
/// future remote implementation.
class TrackingRepositoryImpl implements TrackingRepository {
  final MockTrackingDataSource _dataSource;
  final LineDirectoryRepositoryImpl _directory;

  TrackingRepositoryImpl({
    MockTrackingDataSource? dataSource,
    LineDirectoryRepositoryImpl? directory,
  }) : _dataSource = dataSource ?? MockTrackingDataSource(),
       _directory = directory ?? LineDirectoryRepositoryImpl();

  @override
  Stream<List<LiveVehicle>> watchVehicles(
    String lineId, {
    Duration tickInterval = const Duration(milliseconds: 300),
  }) {
    return _dataSource
        .watchVehicles(lineId, tickInterval: tickInterval)
        .handleError((Object e) {
          throw TrackingRepositoryException(
            'Unable to stream live vehicles for line "$lineId".',
            cause: e,
          );
        });
  }

  @override
  Stream<List<ArrivalEstimate>> watchArrivals({
    required String lineId,
    required String stationId,
    Duration tickInterval = const Duration(seconds: 10),
  }) {
    return _dataSource
        .watchArrivals(
          lineId: lineId,
          stationId: stationId,
          tickInterval: tickInterval,
        )
        .handleError((Object e) {
          throw TrackingRepositoryException(
            'Unable to stream arrivals for station "$stationId" on line "$lineId".',
            cause: e,
          );
        });
  }

  @override
  Future<LineStatus> getLineStatus(String lineId) async {
    try {
      // For the mock we always report "on time" — the simulated
      // motion is deliberately not modelled as a service
      // disruption. A real implementation would query a status
      // feed here.
      return LineStatus.onTime(lineId: lineId);
    } catch (e) {
      throw TrackingRepositoryException(
        'Unable to read status for line "$lineId".',
        cause: e,
      );
    }
  }

  @override
  Future<List<PlatformInfo>> getPlatforms(String stationId) async {
    try {
      // The mock returns an empty list — platforms are not yet
      // modelled from the GTFS `pathways.txt` (Phase 8 work).
      // A real implementation would map accessibility + notes
      // from pathways / levels data.
      // We still touch the directory so the dependency is real
      // and a future swap stays low-risk.
      await _directory.getStationsForLine('kj');
      return const <PlatformInfo>[];
    } catch (e) {
      throw TrackingRepositoryException(
        'Unable to read platforms for station "$stationId".',
        cause: e,
      );
    }
  }
}

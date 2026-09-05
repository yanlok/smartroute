import '../../domain/exceptions/tracking_repository_exception.dart';
import '../../domain/models/arrival_estimate.dart';
import '../../domain/models/live_vehicle.dart';
import '../../domain/models/line_status.dart';
import '../../domain/models/platform_info.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/mock_tracking_data_source.dart';
import 'line_directory_repository_impl.dart';

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

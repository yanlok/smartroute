import '../../domain/exceptions/tracking_repository_exception.dart';
import '../../domain/models/transit_line.dart';
import '../../domain/models/tracking_station.dart';
import '../../domain/repositories/line_directory_repository.dart';
import '../datasources/mock_line_directory_data_source.dart';

/// In-memory `LineDirectoryRepository` implementation backed by the
/// generated GTFS-derived constants. All methods are synchronous
/// in the data source; we wrap them in `Future` here to honour the
/// repository contract and to keep room for a future remote
/// implementation that does need async I/O.
class LineDirectoryRepositoryImpl implements LineDirectoryRepository {
  final MockLineDirectoryDataSource _dataSource;

  LineDirectoryRepositoryImpl({MockLineDirectoryDataSource? dataSource})
    : _dataSource = dataSource ?? const MockLineDirectoryDataSource();

  @override
  Future<List<TransitLine>> getLines() async {
    return _safe(() => _dataSource.getLinesSync());
  }

  @override
  Future<List<TrackingStation>> getAllStations() async {
    return _safe(() => _dataSource.getAllStationsSync());
  }

  @override
  Future<List<TrackingStation>> getStationsForLine(String lineId) async {
    return _safe(() => _dataSource.getStationsForLineSync(lineId));
  }

  @override
  Future<TransitLine?> getLineById(String lineId) async {
    return _safe(() => _dataSource.getLineByIdSync(lineId));
  }

  @override
  Future<TrackingStation?> getStationById({
    required String lineId,
    required String stationId,
  }) async {
    return _safe(
      () =>
          _dataSource.getStationByIdSync(lineId: lineId, stationId: stationId),
    );
  }

  /// Wraps a synchronous data-source call so any unexpected error
  /// surfaces as a [TrackingRepositoryException] rather than
  /// leaking raw exceptions to the application layer.
  T _safe<T>(T Function() body) {
    try {
      return body();
    } on TrackingRepositoryException {
      rethrow;
    } catch (e) {
      throw TrackingRepositoryException(
        'Unable to read the transit network catalogue.',
        cause: e,
      );
    }
  }
}

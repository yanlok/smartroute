import '../../domain/exceptions/tracking_repository_exception.dart';
import '../../domain/models/transit_line.dart';
import '../../domain/models/tracking_station.dart';
import '../../domain/repositories/line_directory_repository.dart';
import '../datasources/mock_line_directory_data_source.dart';

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

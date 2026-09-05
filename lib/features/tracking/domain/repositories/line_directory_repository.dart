import '../models/transit_line.dart';
import '../models/tracking_station.dart';

abstract class LineDirectoryRepository {
  Future<List<TransitLine>> getLines();

  Future<List<TrackingStation>> getAllStations();

  Future<List<TrackingStation>> getStationsForLine(String lineId);

  Future<TransitLine?> getLineById(String lineId);

  Future<TrackingStation?> getStationById({
    required String lineId,
    required String stationId,
  });
}

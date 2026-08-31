import '../models/transit_line.dart';
import '../models/tracking_station.dart';

/// Read-only catalogue of transit lines and the stations on each line.
///
/// Implementations are expected to return data sourced from a
/// static, in-app dataset (today: `kTransitLines` /
/// `kAllStations` generated from the data.gov.my GTFS feed). Future
/// implementations may source from a remote feed, but the contract
/// remains the same.
abstract class LineDirectoryRepository {
  /// Returns every line in display order.
  Future<List<TransitLine>> getLines();

  /// Returns every station across every line.
  ///
  /// Some stations appear in more than one line; in that case the
  /// station is returned once per `(lineId, stationId)` pair so the
  /// presentation layer can show the station's name in each line's
  /// context. Use [getStationsForLine] for the single-line view.
  Future<List<TrackingStation>> getAllStations();

  /// Returns the stations for a single line, in canonical
  /// sequence order (origin → terminal).
  Future<List<TrackingStation>> getStationsForLine(String lineId);

  /// Looks up a single line by id. Returns `null` if no such line.
  Future<TransitLine?> getLineById(String lineId);

  /// Looks up a single station by `(lineId, stationId)`. Returns
  /// `null` if no such station.
  Future<TrackingStation?> getStationById({
    required String lineId,
    required String stationId,
  });
}

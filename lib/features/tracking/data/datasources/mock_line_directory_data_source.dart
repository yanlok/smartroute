import '../../domain/models/transit_line.dart';
import '../../domain/models/tracking_station.dart';
import '../datasources/transit_line_static_data.dart';

class MockLineDirectoryDataSource {
  const MockLineDirectoryDataSource();

  List<TransitLine> getLinesSync() => kTransitLines;

  List<TrackingStation> getAllStationsSync() => kAllStations;

  List<TrackingStation> getStationsForLineSync(String lineId) {
    return kAllStations.where((s) => s.lineId == lineId).toList()
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
  }

  TransitLine? getLineByIdSync(String lineId) {
    for (final line in kTransitLines) {
      if (line.id == lineId) return line;
    }
    return null;
  }

  TrackingStation? getStationByIdSync({
    required String lineId,
    required String stationId,
  }) {
    for (final s in kAllStations) {
      if (s.lineId == lineId && s.id == stationId) return s;
    }
    return null;
  }
}

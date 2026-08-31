import '../models/arrival_estimate.dart';
import '../models/live_vehicle.dart';
import '../models/line_status.dart';
import '../models/platform_info.dart';

abstract class TrackingRepository {
  Stream<List<LiveVehicle>> watchVehicles(
    String lineId, {
    Duration tickInterval = const Duration(milliseconds: 300),
  });

  Stream<List<ArrivalEstimate>> watchArrivals({
    required String lineId,
    required String stationId,
    Duration tickInterval = const Duration(seconds: 10),
  });

  Future<LineStatus> getLineStatus(String lineId);

  Future<List<PlatformInfo>> getPlatforms(String stationId);
}

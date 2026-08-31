import '../models/arrival_estimate.dart';
import '../models/live_vehicle.dart';
import '../models/line_status.dart';
import '../models/platform_info.dart';

/// Live transit data source. All methods are mock-friendly: the
/// current `MockTrackingDataSource` implementation drives
/// vehicles via a `Timer.periodic`. A future real implementation
/// (e.g. GTFS-RT) can drop in behind this contract without UI
/// changes.
///
/// The mock implementation MUST emit `LiveVehicle.isLive == false`
/// and `ArrivalEstimate.isLive == false` on every emission, per
/// `docs/design.md` §8.
abstract class TrackingRepository {
  /// Cold stream of simulated live vehicles for [lineId]. The
  /// stream is a broadcast of one vehicle per active train on the
  /// line. The [tickInterval] is a hint to the data source for
  /// how often to emit; real implementations may ignore it.
  ///
  /// Subscribers are responsible for cancelling the resulting
  /// `StreamSubscription` (typically in the controller's
  /// `dispose()`).
  Stream<List<LiveVehicle>> watchVehicles(
    String lineId, {
    Duration tickInterval = const Duration(milliseconds: 300),
  });

  /// Cold stream of upcoming arrivals at [stationId] for [lineId].
  /// The list contains up to 5 upcoming vehicles, sorted by
  /// ascending `etaMinutes`.
  Stream<List<ArrivalEstimate>> watchArrivals({
    required String lineId,
    required String stationId,
    Duration tickInterval = const Duration(seconds: 10),
  });

  /// One-shot snapshot of the line's operational health.
  Future<LineStatus> getLineStatus(String lineId);

  /// One-shot snapshot of the platforms at a given station.
  Future<List<PlatformInfo>> getPlatforms(String stationId);
}

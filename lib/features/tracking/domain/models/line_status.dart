import 'line_operational_status.dart';

/// An immutable snapshot of a line's operational health at a point
/// in time. Used for the line-picker and (in Phase 6) the Home
/// dashboard summary contract.
class LineStatus {
  /// The [TransitLine.id] this status is for.
  final String lineId;

  /// Operational state of the line.
  final LineOperationalStatus status;

  /// Reported delay in minutes. `0` for [LineOperationalStatus.onTime]
  /// and [LineOperationalStatus.suspended].
  final int delayMinutes;

  /// When this snapshot was produced.
  final DateTime lastUpdated;

  const LineStatus({
    required this.lineId,
    required this.status,
    required this.delayMinutes,
    required this.lastUpdated,
  }) : assert(
         delayMinutes >= 0,
         'delayMinutes must be >= 0; got $delayMinutes',
       );

  /// Convenience constructor for "on time" snapshots.
  factory LineStatus.onTime({required String lineId, DateTime? at}) {
    return LineStatus(
      lineId: lineId,
      status: LineOperationalStatus.onTime,
      delayMinutes: 0,
      lastUpdated: at ?? DateTime.now(),
    );
  }

  /// Convenience constructor for "delayed" snapshots.
  factory LineStatus.delayed({
    required String lineId,
    required LineOperationalStatus status,
    required int delayMinutes,
    DateTime? at,
  }) {
    assert(
      status == LineOperationalStatus.minorDelay ||
          status == LineOperationalStatus.majorDelay,
      'Use LineStatus.delayed for delay statuses only',
    );
    return LineStatus(
      lineId: lineId,
      status: status,
      delayMinutes: delayMinutes,
      lastUpdated: at ?? DateTime.now(),
    );
  }

  /// Convenience constructor for "suspended" snapshots.
  factory LineStatus.suspended({required String lineId, DateTime? at}) {
    return LineStatus(
      lineId: lineId,
      status: LineOperationalStatus.suspended,
      delayMinutes: 0,
      lastUpdated: at ?? DateTime.now(),
    );
  }

  LineStatus copyWith({
    String? lineId,
    LineOperationalStatus? status,
    int? delayMinutes,
    DateTime? lastUpdated,
  }) {
    return LineStatus(
      lineId: lineId ?? this.lineId,
      status: status ?? this.status,
      delayMinutes: delayMinutes ?? this.delayMinutes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineStatus &&
          runtimeType == other.runtimeType &&
          lineId == other.lineId &&
          status == other.status &&
          delayMinutes == other.delayMinutes &&
          lastUpdated == other.lastUpdated;

  @override
  int get hashCode => Object.hash(lineId, status, delayMinutes, lastUpdated);

  @override
  String toString() =>
      'LineStatus(lineId: $lineId, status: $status, '
      'delayMinutes: $delayMinutes)';
}

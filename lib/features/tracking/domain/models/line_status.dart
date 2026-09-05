import 'line_operational_status.dart';

class LineStatus {
  final String lineId;

  final LineOperationalStatus status;

  final int delayMinutes;

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

  factory LineStatus.onTime({required String lineId, DateTime? at}) {
    return LineStatus(
      lineId: lineId,
      status: LineOperationalStatus.onTime,
      delayMinutes: 0,
      lastUpdated: at ?? DateTime.now(),
    );
  }

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

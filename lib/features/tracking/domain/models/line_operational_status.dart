/// Operational status of a transit line at a point in time.
///
/// Used by [LineStatus] and by any cross-module summaries that report
/// line health (e.g. the Home dashboard summary contract).
enum LineOperationalStatus {
  onTime,
  minorDelay,
  majorDelay,
  suspended;

  String get label {
    switch (this) {
      case LineOperationalStatus.onTime:
        return 'On Time';
      case LineOperationalStatus.minorDelay:
        return 'Minor Delay';
      case LineOperationalStatus.majorDelay:
        return 'Major Delay';
      case LineOperationalStatus.suspended:
        return 'Suspended';
    }
  }
}

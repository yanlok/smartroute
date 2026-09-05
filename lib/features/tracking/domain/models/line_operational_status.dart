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

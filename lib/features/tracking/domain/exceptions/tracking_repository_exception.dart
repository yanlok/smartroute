class TrackingRepositoryException implements Exception {
  final String message;

  final Object? cause;

  const TrackingRepositoryException(this.message, {this.cause});

  @override
  String toString() {
    if (cause == null) {
      return 'TrackingRepositoryException: $message';
    }
    return 'TrackingRepositoryException: $message (caused by: $cause)';
  }
}

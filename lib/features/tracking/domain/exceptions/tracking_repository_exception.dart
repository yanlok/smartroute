/// Domain-level exception thrown by any tracking repository
/// implementation when data cannot be retrieved, parsed, or
/// otherwise made available to the application layer.
///
/// This exception intentionally does NOT leak transport-specific
/// details (e.g. HTTP status codes, GTFS error strings) — those
/// details belong in the data layer's logs, not in user-facing
/// messages. Use the [message] field for user-friendly copy.
class TrackingRepositoryException implements Exception {
  /// Human-readable, user-safe description of what went wrong.
  final String message;

  /// Optional underlying cause, retained for logs / debugging only.
  /// Must never be surfaced to the UI.
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

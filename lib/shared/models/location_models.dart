class DeviceLocation {
  final double latitude;
  final double longitude;

  const DeviceLocation({required this.latitude, required this.longitude});
}

enum LocationFailure {
  preferenceDisabled,
  servicesDisabled,
  permissionDenied,
  unavailable,
}

class LocationResult {
  final DeviceLocation? location;
  final LocationFailure? failure;

  const LocationResult.success(this.location) : failure = null;

  const LocationResult.failure(this.failure) : location = null;

  bool get isSuccess => location != null;
}

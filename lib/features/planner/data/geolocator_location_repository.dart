import 'package:geolocator/geolocator.dart';

import '../../../shared/contracts/location_repository.dart';
import '../../../shared/models/location_models.dart';

class GeolocatorLocationRepository implements LocationRepository {
  const GeolocatorLocationRepository();

  @override
  Future<LocationResult> getCurrentLocation({
    required bool preferenceEnabled,
  }) async {
    if (!preferenceEnabled) {
      return const LocationResult.failure(LocationFailure.preferenceDisabled);
    }
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult.failure(LocationFailure.servicesDisabled);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const LocationResult.failure(LocationFailure.permissionDenied);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return LocationResult.success(
        DeviceLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
      );
    } catch (_) {
      return const LocationResult.failure(LocationFailure.unavailable);
    }
  }
}

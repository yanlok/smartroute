import '../models/location_models.dart';

abstract class LocationRepository {
  Future<LocationResult> getCurrentLocation({required bool preferenceEnabled});
}

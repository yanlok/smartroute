import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../shared/contracts/location_repository.dart';
import '../../../shared/contracts/transit_network_repository.dart';
import '../../../shared/models/journey_models.dart';
import '../../../shared/models/location_models.dart';
import '../../../shared/models/transit_models.dart';
import '../../user_management/application/saved_journey_controller.dart';
import '../domain/route_planner_service.dart';

class PlannerController extends ChangeNotifier {
  final TransitNetworkRepository _networkRepository;
  final LocationRepository _locationRepository;
  TransitNetwork? _network;
  TransitStop? _origin;
  TransitStop? _destination;
  List<JourneyOption> _routes = const [];
  JourneyOption? _selectedRoute;
  Set<TransitMode> _allowedModes = TransitMode.values.toSet();
  bool _isLoading = false;
  bool _isLocating = false;
  String? _errorMessage;

  PlannerController({
    required TransitNetworkRepository networkRepository,
    required LocationRepository locationRepository,
  }) : _networkRepository = networkRepository,
       _locationRepository = locationRepository;

  TransitNetwork? get network => _network;
  TransitStop? get origin => _origin;
  TransitStop? get destination => _destination;
  List<JourneyOption> get routes => _routes;
  JourneyOption? get selectedRoute => _selectedRoute;
  Set<TransitMode> get allowedModes => Set.unmodifiable(_allowedModes);
  bool get isLoading => _isLoading;
  bool get isLocating => _isLocating;
  String? get errorMessage => _errorMessage;
  bool get canPlan =>
      _origin != null &&
      _destination != null &&
      _origin!.id != _destination!.id;

  Future<void> load() async {
    if (_network != null || _isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _network = await _networkRepository.loadNetwork();
    } catch (_) {
      _errorMessage = 'Journey planning data could not be loaded. Try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<TransitStop> searchStops(String query, {int limit = 40}) {
    final network = _network;
    if (network == null) return const [];
    final normalized = query.trim().toLowerCase();
    final matches = network.stops.where((stop) {
      if (normalized.isEmpty) return stop.routeIds.isNotEmpty;
      return stop.name.toLowerCase().contains(normalized) ||
          stop.gtfsId.toLowerCase().contains(normalized);
    }).toList();
    matches.sort((a, b) {
      final aStarts = a.name.toLowerCase().startsWith(normalized) ? 0 : 1;
      final bStarts = b.name.toLowerCase().startsWith(normalized) ? 0 : 1;
      final priority = aStarts.compareTo(bStarts);
      if (priority != 0) return priority;
      final routePriority = a.routeIds.length.compareTo(b.routeIds.length);
      return routePriority != 0 ? routePriority : a.name.compareTo(b.name);
    });
    return matches.take(limit).toList(growable: false);
  }

  void selectOrigin(TransitStop stop) {
    _origin = stop;
    _routes = const [];
    _selectedRoute = null;
    _errorMessage = null;
    notifyListeners();
  }

  void selectDestination(TransitStop stop) {
    _destination = stop;
    _routes = const [];
    _selectedRoute = null;
    _errorMessage = null;
    notifyListeners();
  }

  void swapStops() {
    final previous = _origin;
    _origin = _destination;
    _destination = previous;
    _routes = const [];
    _selectedRoute = null;
    notifyListeners();
  }

  void setModeEnabled(TransitMode mode, bool enabled) {
    final next = {..._allowedModes};
    enabled ? next.add(mode) : next.remove(mode);
    if (next.isEmpty) return;
    _allowedModes = next;
    _routes = const [];
    _selectedRoute = null;
    notifyListeners();
  }

  Future<bool> plan({
    required String userId,
    required SavedJourneyController savedJourneys,
  }) async {
    final network = _network;
    final origin = _origin;
    final destination = _destination;
    if (network == null || origin == null || destination == null) {
      _errorMessage = 'Choose an origin and destination.';
      notifyListeners();
      return false;
    }
    if (origin.id == destination.id) {
      _errorMessage = 'Origin and destination must be different.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _routes = RoutePlannerService(network).plan(
        originStopId: origin.id,
        destinationStopId: destination.id,
        allowedModes: _allowedModes,
      );
      if (_routes.isEmpty) {
        _errorMessage = 'No route was found with the selected transport modes.';
        return false;
      }
      _selectedRoute = _routes.first;
      await savedJourneys.recordSearch(
        userId: userId,
        originStopId: origin.id,
        destinationStopId: destination.id,
      );
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> replan({
    required String originStopId,
    required String destinationStopId,
    required String userId,
    required SavedJourneyController savedJourneys,
  }) async {
    await load();
    final network = _network;
    if (network == null) return false;
    final origin = network.stopsById[originStopId];
    final destination = network.stopsById[destinationStopId];
    if (origin == null || destination == null) {
      _errorMessage =
          'This saved journey no longer matches the transit snapshot.';
      notifyListeners();
      return false;
    }
    _origin = origin;
    _destination = destination;
    return plan(userId: userId, savedJourneys: savedJourneys);
  }

  void selectRoute(JourneyOption route) {
    if (!_routes.contains(route)) return;
    _selectedRoute = route;
    notifyListeners();
  }

  Future<bool> useCurrentLocation({required bool preferenceEnabled}) async {
    final network = _network;
    if (network == null || _isLocating) return false;
    _isLocating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _locationRepository.getCurrentLocation(
        preferenceEnabled: preferenceEnabled,
      );
      if (!result.isSuccess) {
        _errorMessage = switch (result.failure) {
          LocationFailure.preferenceDisabled =>
            'Enable location features in Profile, or choose a stop manually.',
          LocationFailure.servicesDisabled =>
            'Location services are off. Choose a stop manually.',
          LocationFailure.permissionDenied =>
            'Location permission was not granted. Choose a stop manually.',
          _ => 'Current location could not be found. Choose a stop manually.',
        };
        return false;
      }
      _origin = NearestStopFinder().find(network.stops, result.location!);
      return _origin != null;
    } finally {
      _isLocating = false;
      notifyListeners();
    }
  }
}

class NearestStopFinder {
  const NearestStopFinder();

  TransitStop? find(List<TransitStop> stops, DeviceLocation location) {
    TransitStop? nearest;
    var minimum = double.infinity;
    for (final stop in stops) {
      if (stop.routeIds.isEmpty) continue;
      final distance = _distance(
        location.latitude,
        location.longitude,
        stop.latitude,
        stop.longitude,
      );
      if (distance < minimum) {
        minimum = distance;
        nearest = stop;
      }
    }
    return nearest;
  }

  double _distance(double lat1, double lon1, double lat2, double lon2) {
    const radius = 6371000.0;
    final first = lat1 * pi / 180;
    final second = lat2 * pi / 180;
    final lat = (lat2 - lat1) * pi / 180;
    final lon = (lon2 - lon1) * pi / 180;
    final value =
        sin(lat / 2) * sin(lat / 2) +
        cos(first) * cos(second) * sin(lon / 2) * sin(lon / 2);
    return radius * 2 * atan2(sqrt(value), sqrt(1 - value));
  }
}

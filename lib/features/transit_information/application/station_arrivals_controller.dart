import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../shared/models/transit_models.dart';

class StationArrivalsController extends ChangeNotifier {
  final TransitNetwork _network;
  final String stationId;
  final DateTime Function() _clock;
  final int _maxArrivals;
  final Duration _refreshInterval;

  Timer? _refreshTimer;
  List<ScheduledStationArrival> _arrivals = const [];
  bool _isLoading = false;
  String? _errorMessage;

  StationArrivalsController({
    required TransitNetwork network,
    required this.stationId,
    DateTime Function()? clock,
    int maxArrivals = 5,
    Duration refreshInterval = const Duration(seconds: 30),
  }) : _network = network,
       _clock = clock ?? DateTime.now,
       _maxArrivals = maxArrivals,
       _refreshInterval = refreshInterval;

  List<ScheduledStationArrival> get arrivals => List.unmodifiable(_arrivals);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> start() async {
    _refreshTimer ??= Timer.periodic(_refreshInterval, (_) => refresh());
    await refresh();
  }

  Future<void> refresh() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _arrivals = _network.upcomingArrivalsForStop(
        stationId,
        now: _clock(),
        limit: _maxArrivals,
      );
    } catch (_) {
      _arrivals = const [];
      _errorMessage = 'Upcoming arrivals could not be calculated. Try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

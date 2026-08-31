import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/exceptions/tracking_repository_exception.dart';
import '../domain/models/arrival_estimate.dart';
import '../domain/models/tracking_station.dart';
import '../domain/repositories/tracking_repository.dart';

/// Owns the live state for the arrivals view at a single
/// `(lineId, stationId)` pair.
///
/// Same rules as [TrackingController]: no Timer, no
/// StreamController, no material import; stale-emission guard via
/// a generation counter.
class ArrivalsController extends ChangeNotifier {
  final TrackingRepository _trackingRepository;

  StreamSubscription<List<ArrivalEstimate>>? _subscription;
  int _generation = 0;

  final String lineId;
  final String stationId;

  List<ArrivalEstimate> _arrivals = const <ArrivalEstimate>[];
  TrackingStation? _station;
  bool _isLoading = false;
  String? _errorMessage;

  ArrivalsController({
    required TrackingRepository trackingRepository,
    required this.lineId,
    required this.stationId,
  }) : _trackingRepository = trackingRepository;

  List<ArrivalEstimate> get arrivals => List.unmodifiable(_arrivals);
  TrackingStation? get station => _station;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isMockData => true;

  /// Starts (or restarts) the stream subscription. Safe to call
  /// multiple times — only the most recent call's emissions are
  /// surfaced.
  void start() {
    final generation = ++_generation;
    _isLoading = true;
    _errorMessage = null;
    _arrivals = const <ArrivalEstimate>[];
    notifyListeners();

    _subscription?.cancel();
    _subscription = _trackingRepository
        .watchArrivals(lineId: lineId, stationId: stationId)
        .listen(
          (arrivals) {
            if (generation != _generation) return;
            _arrivals = arrivals;
            _isLoading = false;
            notifyListeners();
          },
          onError: (Object e) {
            if (generation != _generation) return;
            _isLoading = false;
            _errorMessage = _cleanErrorMessage(e);
            notifyListeners();
          },
        );
  }

  void retry() => start();

  @override
  void dispose() {
    _generation++;
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }

  String _cleanErrorMessage(Object e) {
    if (e is TrackingRepositoryException) return e.message;
    return 'Something went wrong. Please try again.';
  }
}

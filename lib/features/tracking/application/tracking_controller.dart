import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/exceptions/tracking_repository_exception.dart';
import '../domain/models/live_vehicle.dart';
import '../domain/models/transit_line.dart';
import '../domain/models/tracking_station.dart';
import '../domain/repositories/line_directory_repository.dart';
import '../domain/repositories/tracking_repository.dart';

/// Owns the live state for a single line's tracking view.
///
/// Responsibilities:
///   * Subscribes to [TrackingRepository.watchVehicles] when a
///     line is selected.
///   * Exposes a small immutable UI state via getters.
///   * Discards stale emissions (after [selectLine]) using a
///     monotonic generation counter (same trick used in
///     `ProfileController` to defeat race conditions).
///   * Cancels its stream subscription on [dispose].
///
/// **No** `Timer`, **no** `StreamController`, **no**
/// `package:flutter/material.dart` import.
class TrackingController extends ChangeNotifier {
  final TrackingRepository _trackingRepository;
  final LineDirectoryRepository _directoryRepository;

  StreamSubscription<List<LiveVehicle>>? _subscription;
  int _generation = 0;

  String? _selectedLineId;
  TransitLine? _selectedLine;
  List<TrackingStation> _stations = const <TrackingStation>[];
  List<LiveVehicle> _vehicles = const <LiveVehicle>[];
  bool _isLoading = false;
  String? _errorMessage;

  TrackingController({
    required TrackingRepository trackingRepository,
    required LineDirectoryRepository directoryRepository,
  }) : _trackingRepository = trackingRepository,
       _directoryRepository = directoryRepository;

  // ── Public, read-only state ─────────────────────────────────────────

  String? get selectedLineId => _selectedLineId;
  TransitLine? get selectedLine => _selectedLine;
  List<TrackingStation> get stations => List.unmodifiable(_stations);
  List<LiveVehicle> get vehicles => List.unmodifiable(_vehicles);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// The mock data source always reports simulated motion. UI uses
  /// this to render a "Simulated" pill (design.md §8).
  bool get isMockData => true;

  /// First vehicle in the list, or `null` if there are none.
  /// Convenient for the "current vehicle" header in the screen.
  LiveVehicle? get currentVehicle => _vehicles.isEmpty ? null : _vehicles.first;

  // ── Public actions ──────────────────────────────────────────────────

  /// Subscribes to the given line. Replaces any previous
  /// subscription. Safe to call multiple times.
  Future<void> selectLine(String lineId) async {
    final generation = ++_generation;

    _selectedLineId = lineId;
    _isLoading = true;
    _errorMessage = null;
    _vehicles = const <LiveVehicle>[];
    notifyListeners();

    try {
      final line = await _directoryRepository.getLineById(lineId);
      if (generation != _generation) return; // user changed lines again
      _selectedLine = line;

      final stations = await _directoryRepository.getStationsForLine(lineId);
      if (generation != _generation) return;
      _stations = stations;

      // Replace any previous subscription.
      await _subscription?.cancel();
      if (generation != _generation) return;

      _subscription = _trackingRepository
          .watchVehicles(lineId)
          .listen(
            (vehicles) {
              if (generation != _generation) return;
              _vehicles = vehicles;
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
    } on TrackingRepositoryException catch (e) {
      if (generation != _generation) return;
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      if (generation != _generation) return;
      _isLoading = false;
      _errorMessage = 'Something went wrong. Please try again.';
      notifyListeners();
    }
  }

  /// Clears the current selection and cancels the subscription.
  void clearSelection() {
    _generation++;
    _subscription?.cancel();
    _subscription = null;
    _selectedLineId = null;
    _selectedLine = null;
    _stations = const <TrackingStation>[];
    _vehicles = const <LiveVehicle>[];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Re-subscribes to the currently selected line. No-op if no
  /// line is selected.
  Future<void> retry() async {
    final lineId = _selectedLineId;
    if (lineId == null) return;
    await selectLine(lineId);
  }

  // ── Lifecycle ───────────────────────────────────────────────────────

  @override
  void dispose() {
    _generation++; // invalidate any pending async work
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }

  String _cleanErrorMessage(Object e) {
    if (e is TrackingRepositoryException) return e.message;
    return 'Something went wrong. Please try again.';
  }
}

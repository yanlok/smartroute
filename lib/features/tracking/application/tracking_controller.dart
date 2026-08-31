import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/exceptions/tracking_repository_exception.dart';
import '../domain/models/live_vehicle.dart';
import '../domain/models/transit_line.dart';
import '../domain/models/tracking_station.dart';
import '../domain/repositories/line_directory_repository.dart';
import '../domain/repositories/tracking_repository.dart';

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

  String? get selectedLineId => _selectedLineId;
  TransitLine? get selectedLine => _selectedLine;
  List<TrackingStation> get stations => List.unmodifiable(_stations);
  List<LiveVehicle> get vehicles => List.unmodifiable(_vehicles);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isMockData =>
      _vehicles.isNotEmpty && _vehicles.every((vehicle) => !vehicle.isLive);

  bool get hasLiveVehicles => _vehicles.any((vehicle) => vehicle.isLive);

  LiveVehicle? get currentVehicle => _vehicles.isEmpty ? null : _vehicles.first;

  Future<void> selectLine(String lineId) async {
    final generation = ++_generation;

    _selectedLineId = lineId;
    _isLoading = true;
    _errorMessage = null;
    _vehicles = const <LiveVehicle>[];
    notifyListeners();

    try {
      final line = await _directoryRepository.getLineById(lineId);
      if (generation != _generation) return;
      _selectedLine = line;

      final stations = await _directoryRepository.getStationsForLine(lineId);
      if (generation != _generation) return;
      _stations = stations;

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

  Future<void> retry() async {
    final lineId = _selectedLineId;
    if (lineId == null) return;
    await selectLine(lineId);
  }

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

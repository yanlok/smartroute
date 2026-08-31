import 'package:flutter/foundation.dart';

import '../domain/exceptions/tracking_repository_exception.dart';
import '../domain/models/line_status.dart';
import '../domain/models/transit_line.dart';
import '../domain/repositories/line_directory_repository.dart';
import '../domain/repositories/tracking_repository.dart';

class LinePickerController extends ChangeNotifier {
  final LineDirectoryRepository _directoryRepository;
  final TrackingRepository _trackingRepository;

  List<TransitLine> _lines = const <TransitLine>[];
  final Map<String, LineStatus> _statuses = <String, LineStatus>{};
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;

  LinePickerController({
    required LineDirectoryRepository directoryRepository,
    required TrackingRepository trackingRepository,
  }) : _directoryRepository = directoryRepository,
       _trackingRepository = trackingRepository;

  List<TransitLine> get lines => List.unmodifiable(_lines);
  Map<String, LineStatus> get statuses => Map.unmodifiable(_statuses);
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    if (_isLoading) return;
    await _load();
  }

  Future<void> refresh() async {
    _hasLoaded = false;
    await _load();
  }

  Future<void> _load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final lines = await _directoryRepository.getLines();
      _lines = lines;
      _hasLoaded = true;

      for (final line in lines) {
        try {
          _statuses[line.id] = await _trackingRepository.getLineStatus(line.id);
        } catch (_) {}
      }

      _isLoading = false;
      notifyListeners();
    } on TrackingRepositoryException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
    } catch (_) {
      _isLoading = false;
      _errorMessage = 'Something went wrong. Please try again.';
      notifyListeners();
    }
  }
}

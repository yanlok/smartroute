import 'package:flutter/foundation.dart';

import '../domain/exceptions/tracking_repository_exception.dart';
import '../domain/models/line_status.dart';
import '../domain/models/transit_line.dart';
import '../domain/repositories/line_directory_repository.dart';
import '../domain/repositories/tracking_repository.dart';

/// Owns the line-picker state: a one-shot load of the full
/// `TransitLine` list plus per-line status snapshots.
///
/// No live subscription — statuses are refreshed only when the
/// user pulls to refresh, or when [refresh] is called explicitly.
/// (Status polling on a real feed would belong here too, behind
/// the same `refresh` entry point.)
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

  /// Loads the line catalogue once. Subsequent calls are no-ops
  /// unless [refresh] is called.
  Future<void> load() async {
    if (_isLoading) return;
    await _load();
  }

  /// Forces a reload of the catalogue and statuses.
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

      // Refresh statuses after the catalogue is known. We don't
      // fail the whole load if a status fails — the lines are
      // still useful on their own.
      for (final line in lines) {
        try {
          _statuses[line.id] = await _trackingRepository.getLineStatus(line.id);
        } catch (_) {
          // leave the previous status (if any) in place
        }
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

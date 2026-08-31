import 'package:flutter/foundation.dart';

import '../../../shared/contracts/transit_network_repository.dart';
import '../../../shared/models/transit_models.dart';

class TransitNetworkController extends ChangeNotifier {
  final TransitNetworkRepository _repository;
  TransitNetwork? _network;
  bool _isLoading = false;
  String? _errorMessage;

  TransitNetworkController({required TransitNetworkRepository repository})
    : _repository = repository;

  TransitNetwork? get network => _network;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isReady => _network != null;

  Future<void> load() async {
    if (_isLoading || _network != null) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _network = await _repository.loadNetwork();
    } catch (_) {
      _errorMessage = 'Transit information could not be loaded. Try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<TransitStop> searchStops(String query, {int limit = 30}) {
    final network = _network;
    if (network == null) return const [];
    final normalized = query.trim().toLowerCase();
    final matches = network.stops.where((stop) {
      if (normalized.isEmpty) return true;
      return stop.name.toLowerCase().contains(normalized) ||
          stop.gtfsId.toLowerCase().contains(normalized);
    }).toList();
    matches.sort((a, b) {
      final aStarts = a.name.toLowerCase().startsWith(normalized) ? 0 : 1;
      final bStarts = b.name.toLowerCase().startsWith(normalized) ? 0 : 1;
      final priority = aStarts.compareTo(bStarts);
      return priority != 0 ? priority : a.name.compareTo(b.name);
    });
    return matches.take(limit).toList(growable: false);
  }

  Future<void> retry() async {
    _network = null;
    await load();
  }
}

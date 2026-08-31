import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../shared/contracts/transit_network_repository.dart';
import '../../../shared/models/transit_models.dart';

typedef TransitAssetLoader = Future<String> Function(String assetPath);

class BundledTransitNetworkRepository implements TransitNetworkRepository {
  final TransitAssetLoader _assetLoader;
  TransitNetwork? _network;
  Future<TransitNetwork>? _pending;

  BundledTransitNetworkRepository({TransitAssetLoader? assetLoader})
    : _assetLoader = assetLoader ?? rootBundle.loadString;

  @override
  Future<TransitNetwork> loadNetwork() {
    final cached = _network;
    if (cached != null) return Future.value(cached);
    return _pending ??= _load();
  }

  Future<TransitNetwork> _load() async {
    try {
      final source = await _assetLoader('assets/data/transit_network.json');
      final json = jsonDecode(source) as Map<String, Object?>;
      final network = TransitNetwork(
        metadata: TransitMetadata.fromJson(
          Map<String, Object?>.from(json['metadata']! as Map<Object?, Object?>),
        ),
        routes: [
          for (final route in json['routes']! as List<Object?>)
            TransitRoute.fromJson(
              Map<String, Object?>.from(route! as Map<Object?, Object?>),
            ),
        ],
        stops: [
          for (final stop in json['stops']! as List<Object?>)
            TransitStop.fromJson(
              Map<String, Object?>.from(stop! as Map<Object?, Object?>),
            ),
        ],
        edges: [
          for (final edge in json['edges']! as List<Object?>)
            TransitEdge.fromJson(
              Map<String, Object?>.from(edge! as Map<Object?, Object?>),
            ),
        ],
        patterns: [
          for (final pattern in json['patterns']! as List<Object?>)
            TransitPattern.fromJson(
              Map<String, Object?>.from(pattern! as Map<Object?, Object?>),
            ),
        ],
      );
      _network = network;
      return network;
    } finally {
      _pending = null;
    }
  }
}

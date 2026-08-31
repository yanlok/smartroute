import 'dart:async';
import 'dart:typed_data';

import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:http/http.dart' as http;

class RealtimeVehicleSnapshot {
  final String routeId;
  final String tripId;
  final String vehicleId;
  final String? label;
  final int directionId;
  final double latitude;
  final double longitude;
  final double? bearing;
  final double? speedMetresPerSecond;
  final DateTime timestamp;

  const RealtimeVehicleSnapshot({
    required this.routeId,
    required this.tripId,
    required this.vehicleId,
    required this.label,
    required this.directionId,
    required this.latitude,
    required this.longitude,
    required this.bearing,
    required this.speedMetresPerSecond,
    required this.timestamp,
  });
}

typedef RealtimeBytesFetcher = Future<Uint8List> Function(Uri uri);

class OfficialGtfsRealtimeDataSource {
  static const _baseUrl =
      'https://api.data.gov.my/gtfs-realtime/vehicle-position/prasarana';

  final RealtimeBytesFetcher _fetchBytes;
  final Duration pollInterval;

  OfficialGtfsRealtimeDataSource({
    RealtimeBytesFetcher? fetchBytes,
    this.pollInterval = const Duration(seconds: 30),
  }) : _fetchBytes = fetchBytes ?? _defaultFetch;

  Stream<List<RealtimeVehicleSnapshot>> watchVehicles(String source) {
    late StreamController<List<RealtimeVehicleSnapshot>> controller;
    Timer? timer;
    var requestInFlight = false;

    Future<void> refresh() async {
      if (requestInFlight || controller.isClosed) return;
      requestInFlight = true;
      try {
        final uri = Uri.parse(
          _baseUrl,
        ).replace(queryParameters: <String, String>{'category': source});
        final bytes = await _fetchBytes(uri);
        if (!controller.isClosed) controller.add(parse(bytes));
      } catch (error, stackTrace) {
        if (!controller.isClosed) controller.addError(error, stackTrace);
      } finally {
        requestInFlight = false;
      }
    }

    controller = StreamController<List<RealtimeVehicleSnapshot>>(
      onListen: () {
        refresh();
        timer = Timer.periodic(pollInterval, (_) => refresh());
      },
      onCancel: () {
        timer?.cancel();
      },
    );
    return controller.stream;
  }

  List<RealtimeVehicleSnapshot> parse(Uint8List bytes) {
    final feed = FeedMessage.fromBuffer(bytes);
    final vehicles = <RealtimeVehicleSnapshot>[];
    for (final entity in feed.entity) {
      if (!entity.hasVehicle()) continue;
      final update = entity.vehicle;
      if (!update.hasTrip() || !update.hasPosition()) continue;
      final trip = update.trip;
      final position = update.position;
      if (!trip.hasRouteId() ||
          !position.hasLatitude() ||
          !position.hasLongitude()) {
        continue;
      }
      final descriptor = update.hasVehicle() ? update.vehicle : null;
      final timestamp = update.hasTimestamp()
          ? DateTime.fromMillisecondsSinceEpoch(
              update.timestamp.toInt() * 1000,
              isUtc: true,
            )
          : DateTime.now().toUtc();
      vehicles.add(
        RealtimeVehicleSnapshot(
          routeId: trip.routeId,
          tripId: trip.hasTripId() ? trip.tripId : '',
          vehicleId: descriptor != null && descriptor.hasId()
              ? descriptor.id
              : entity.id,
          label: descriptor != null && descriptor.hasLabel()
              ? descriptor.label
              : null,
          directionId: trip.hasDirectionId() ? trip.directionId : 0,
          latitude: position.latitude,
          longitude: position.longitude,
          bearing: position.hasBearing() ? position.bearing : null,
          speedMetresPerSecond: position.hasSpeed() ? position.speed : null,
          timestamp: timestamp,
        ),
      );
    }
    return vehicles;
  }

  static Future<Uint8List> _defaultFetch(Uri uri) async {
    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw http.ClientException('Realtime provider request failed', uri);
    }
    return response.bodyBytes;
  }
}

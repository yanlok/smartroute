import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/transit_presentation.dart';
import '../../features/planner/domain/route_planner_service.dart';
import '../models/journey_models.dart';
import '../models/transit_models.dart';

class TransitMapMarker {
  final String id;
  final String label;
  final TransitCoordinate coordinate;
  final TransitMapMarkerKind kind;
  final VoidCallback? onTap;
  final double? rotation;
  final bool flat;
  final Offset? anchor;
  final BitmapDescriptor? iconOverride;

  const TransitMapMarker({
    required this.id,
    required this.label,
    required this.coordinate,
    this.kind = TransitMapMarkerKind.standard,
    this.onTap,
    this.rotation,
    this.flat = false,
    this.anchor,
    this.iconOverride,
  });
}

enum TransitMapMarkerKind {
  standard,
  origin,
  destination,
  stop,
  vehicle,

  simulatedVehicle,
  transfer,
}

class TransitMapCamera {
  final TransitCoordinate center;
  final double zoom;

  const TransitMapCamera({required this.center, required this.zoom});
}

class TransitMapViewport {
  const TransitMapViewport();

  TransitMapCamera resolve({
    required List<TransitMapMarker> markers,
    required List<TransitMapLine> lines,
    TransitCoordinate? fallback,
  }) {
    final coordinates = <TransitCoordinate>[
      for (final marker in markers) marker.coordinate,
      for (final line in lines) ...line.points,
    ];
    if (coordinates.isEmpty) {
      return TransitMapCamera(
        center: fallback ?? const TransitCoordinate(3.139, 101.6869),
        zoom: 12,
      );
    }
    var minLatitude = coordinates.first.latitude;
    var maxLatitude = coordinates.first.latitude;
    var minLongitude = coordinates.first.longitude;
    var maxLongitude = coordinates.first.longitude;
    for (final coordinate in coordinates.skip(1)) {
      minLatitude = minLatitude < coordinate.latitude
          ? minLatitude
          : coordinate.latitude;
      maxLatitude = maxLatitude > coordinate.latitude
          ? maxLatitude
          : coordinate.latitude;
      minLongitude = minLongitude < coordinate.longitude
          ? minLongitude
          : coordinate.longitude;
      maxLongitude = maxLongitude > coordinate.longitude
          ? maxLongitude
          : coordinate.longitude;
    }
    final span = (maxLatitude - minLatitude) > (maxLongitude - minLongitude)
        ? maxLatitude - minLatitude
        : maxLongitude - minLongitude;
    final zoom = switch (span) {
      >= 0.25 => 9.0,
      >= 0.12 => 9.8,
      >= 0.06 => 10.5,
      >= 0.03 => 11.3,
      >= 0.015 => 12.0,
      >= 0.007 => 12.8,
      _ => 14.0,
    };
    return TransitMapCamera(
      center: TransitCoordinate(
        (minLatitude + maxLatitude) / 2,
        (minLongitude + maxLongitude) / 2,
      ),
      zoom: zoom,
    );
  }
}

class TransitMapLine {
  final String id;
  final Color color;
  final List<TransitCoordinate> points;

  const TransitMapLine({
    required this.id,
    required this.color,
    required this.points,
  });
}

class TransitGoogleMap extends StatefulWidget {
  final List<TransitMapMarker> markers;
  final List<TransitMapLine> lines;
  final TransitCoordinate? initialCenter;
  final bool showCurrentLocation;
  final bool enableInteractionControls;
  final double height;
  final String? activeRouteId;
  final ValueChanged<String>? onLineTap;
  final Future<bool> Function()? nativeMapAvailability;

  const TransitGoogleMap({
    super.key,
    required this.markers,
    required this.lines,
    this.initialCenter,
    this.showCurrentLocation = false,
    this.enableInteractionControls = false,
    this.height = 360,
    this.activeRouteId,
    this.onLineTap,
    this.nativeMapAvailability,
  });

  @override
  State<TransitGoogleMap> createState() => _TransitGoogleMapState();
}

class _TransitGoogleMapState extends State<TransitGoogleMap> {
  static const _capabilityChannel = MethodChannel(
    'com.smartroute.app/google_maps_capability',
  );

  GoogleMapController? _mapController;
  bool? _nativeMapAvailable;

  @override
  void initState() {
    super.initState();
    _checkNativeMapAvailability();
  }

  @override
  void didUpdateWidget(covariant TransitGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeRouteId != null &&
        widget.activeRouteId != oldWidget.activeRouteId) {
      _animateCameraToLine(widget.activeRouteId!);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _checkNativeMapAvailability() async {
    if (_nativeMapAvailable != null) {
      setState(() => _nativeMapAvailable = null);
    }
    bool available;
    if (kIsWeb) {
      available = false;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      available = true;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final check =
            widget.nativeMapAvailability ??
            () async =>
                await _capabilityChannel.invokeMethod<bool>(
                  'isGoogleMapsAvailable',
                ) ??
                false;
        available = await check();
      } on PlatformException {
        available = false;
      } on MissingPluginException {
        available = false;
      } catch (_) {
        available = false;
      }
    } else {
      available = false;
    }
    if (!mounted) return;
    setState(() => _nativeMapAvailable = available);
  }

  void _animateCameraToLine(String routeId) {
    final line = widget.lines.where((l) => l.id == routeId).firstOrNull;
    if (line == null || line.points.isEmpty || _mapController == null) return;

    var minLat = line.points.first.latitude;
    var maxLat = line.points.first.latitude;
    var minLng = line.points.first.longitude;
    var maxLng = line.points.first.longitude;
    for (final p in line.points.skip(1)) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        48.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final camera = const TransitMapViewport().resolve(
      markers: widget.markers,
      lines: widget.lines,
      fallback: widget.initialCenter,
    );
    final hasActive = widget.activeRouteId != null;

    return Semantics(
      label: _nativeMapAvailable == true
          ? 'Interactive Google Map showing the selected transit journey'
          : 'Transit map availability information',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: _nativeMapAvailable == true
              ? GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (widget.activeRouteId != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _animateCameraToLine(widget.activeRouteId!);
                        }
                      });
                    }
                  },
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      camera.center.latitude,
                      camera.center.longitude,
                    ),
                    zoom: camera.zoom,
                  ),
                  markers: {
                    for (final marker in widget.markers)
                      Marker(
                        markerId: MarkerId(marker.id),
                        position: LatLng(
                          marker.coordinate.latitude,
                          marker.coordinate.longitude,
                        ),
                        icon:
                            marker.iconOverride ??
                            BitmapDescriptor.defaultMarkerWithHue(
                              _markerHue(marker.kind),
                            ),
                        rotation: marker.rotation ?? 0.0,
                        flat: marker.flat,
                        anchor:
                            marker.anchor ??
                            (marker.flat
                                ? const Offset(0.5, 0.5)
                                : const Offset(0.5, 1.0)),
                        zIndexInt:
                            marker.kind == TransitMapMarkerKind.vehicle ||
                                marker.kind ==
                                    TransitMapMarkerKind.simulatedVehicle
                            ? 10
                            : 1,
                        infoWindow: InfoWindow(title: marker.label),
                        onTap: marker.onTap,
                      ),
                  },
                  polylines: {
                    for (final line in widget.lines)
                      if (line.points.length >= 2)
                        Polyline(
                          polylineId: PolylineId(line.id),
                          color: hasActive && widget.activeRouteId != line.id
                              ? line.color.withValues(alpha: 0.2)
                              : line.color,
                          width: hasActive
                              ? (widget.activeRouteId == line.id ? 8 : 3)
                              : 6,
                          jointType: JointType.round,
                          zIndex: hasActive && widget.activeRouteId == line.id
                              ? 1
                              : 0,
                          points: [
                            for (final point in line.points)
                              LatLng(point.latitude, point.longitude),
                          ],
                          consumeTapEvents: widget.onLineTap != null,
                          onTap: widget.onLineTap != null
                              ? () => widget.onLineTap!(line.id)
                              : null,
                        ),
                  },
                  compassEnabled: true,
                  gestureRecognizers: widget.enableInteractionControls
                      ? <Factory<OneSequenceGestureRecognizer>>{
                          Factory<OneSequenceGestureRecognizer>(
                            EagerGestureRecognizer.new,
                          ),
                        }
                      : const <Factory<OneSequenceGestureRecognizer>>{},
                  mapToolbarEnabled: false,
                  myLocationEnabled: widget.showCurrentLocation,
                  myLocationButtonEnabled: widget.showCurrentLocation,
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  zoomControlsEnabled: widget.enableInteractionControls,
                )
              : _MapUnavailablePanel(
                  checking: _nativeMapAvailable == null,
                  markers: widget.markers,
                  onRetry: _checkNativeMapAvailability,
                ),
        ),
      ),
    );
  }

  double _markerHue(TransitMapMarkerKind kind) => switch (kind) {
    TransitMapMarkerKind.origin => BitmapDescriptor.hueGreen,
    TransitMapMarkerKind.destination => BitmapDescriptor.hueRed,
    TransitMapMarkerKind.stop => BitmapDescriptor.hueAzure,
    TransitMapMarkerKind.vehicle => BitmapDescriptor.hueViolet,
    TransitMapMarkerKind.simulatedVehicle => BitmapDescriptor.hueCyan,
    TransitMapMarkerKind.transfer => BitmapDescriptor.hueOrange,
    TransitMapMarkerKind.standard => BitmapDescriptor.hueRed,
  };
}

class _MapUnavailablePanel extends StatelessWidget {
  final bool checking;
  final List<TransitMapMarker> markers;
  final VoidCallback onRetry;

  const _MapUnavailablePanel({
    required this.checking,
    required this.markers,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final allLabels = markers
        .map((marker) => marker.label.trim())
        .where((label) => label.isNotEmpty)
        .toSet()
        .toList();
    final labels = allLabels.take(4).toList();
    final hiddenCount = allLabels.length - labels.length;
    return Container(
      key: const Key('transit_map_fallback'),
      color: AppColors.mutedBg,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.map_outlined,
              color: AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              checking
                  ? 'Checking map availability'
                  : 'Map unavailable on this device',
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Route and station information remains available.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (!checking && labels.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${labels.join(' • ')}${hiddenCount > 0 ? ' • $hiddenCount more' : ''}',
                key: const Key('transit_map_fallback_labels'),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (!checking) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                key: const Key('transit_map_retry'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry map'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class JourneyGoogleMap extends StatelessWidget {
  final JourneyOption journey;
  final TransitNetwork network;
  final bool showCurrentLocation;
  final bool enableInteractionControls;
  final double height;
  final ValueChanged<String>? onStopTap;

  const JourneyGoogleMap({
    super.key,
    required this.journey,
    required this.network,
    this.showCurrentLocation = false,
    this.enableInteractionControls = false,
    this.height = 320,
    this.onStopTap,
  });

  @override
  Widget build(BuildContext context) {
    final markers = <TransitMapMarker>[];
    final markerIds = <String>{};
    void addMarker(String stopId, String label, TransitMapMarkerKind kind) {
      final stop = network.stopsById[stopId];
      if (stop == null || !markerIds.add(stopId)) return;
      markers.add(
        TransitMapMarker(
          id: stop.id,
          label: '$label · ${stop.name}',
          coordinate: stop.coordinate,
          kind: kind,
          onTap: onStopTap == null ? null : () => onStopTap!(stopId),
        ),
      );
    }

    addMarker(journey.originStopId, 'Origin', TransitMapMarkerKind.origin);
    for (final segment in journey.segments) {
      addMarker(
        segment.fromStopId,
        segment.isWalking ? 'Walk' : 'Board',
        TransitMapMarkerKind.stop,
      );
      addMarker(
        segment.toStopId,
        segment == journey.segments.last ? 'Destination' : 'Transfer',
        segment == journey.segments.last
            ? TransitMapMarkerKind.destination
            : TransitMapMarkerKind.transfer,
      );
    }
    addMarker(
      journey.destinationStopId,
      'Destination',
      TransitMapMarkerKind.destination,
    );

    final lines = <TransitMapLine>[];
    for (var index = 0; index < journey.segments.length; index++) {
      final segment = journey.segments[index];
      final route = segment.routeId == null
          ? null
          : network.routesById[segment.routeId];
      final projected = const JourneyMapProjector().coordinatesFor(
        JourneyOption(
          id: 'segment-$index',
          objective: journey.objective,
          originStopId: segment.fromStopId,
          destinationStopId: segment.toStopId,
          durationMinutes: segment.durationMinutes,
          transferCount: 0,
          walkingMetres: segment.walkingMetres,
          segments: [segment],
        ),
        network,
      );
      lines.add(
        TransitMapLine(
          id: 'journey-$index',
          color: route == null
              ? AppColors.textTertiary
              : TransitPresentation.routeColor(route),
          points: projected,
        ),
      );
    }

    return TransitGoogleMap(
      markers: markers,
      lines: lines,
      initialCenter: network.stopsById[journey.originStopId]?.coordinate,
      showCurrentLocation: showCurrentLocation,
      enableInteractionControls: enableInteractionControls,
      height: height,
    );
  }
}

class TransitVehicleIconFactory {
  static final Map<String, BitmapDescriptor> _cache = {};

  static Future<BitmapDescriptor?> getVehicleIcon({
    required bool isBus,
    Color? color,
    int? vehicleNumber,
  }) async {
    try {
      final effectiveColor =
          color ?? (isBus ? const Color(0xFF7C3AED) : const Color(0xFF009FE3));
      final cacheKey = '$isBus-${effectiveColor.toARGB32()}-$vehicleNumber';

      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!;
      }

      final icon = await _createBadge(
        isBus: isBus,
        bgColor: effectiveColor,
        vehicleNumber: vehicleNumber,
      );

      _cache[cacheKey] = icon;
      return icon;
    } catch (_) {
      return null;
    }
  }

  static Future<BitmapDescriptor> _createBadge({
    required bool isBus,
    required Color bgColor,
    int? vehicleNumber,
  }) async {
    const size = 64.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawCircle(
      const Offset(size / 2, size / 2 + 1.5),
      (size / 2) - 4,
      shadowPaint,
    );

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      (size / 2) - 3,
      borderPaint,
    );

    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      (size / 2) - 6,
      bgPaint,
    );

    final iconData = isBus ? Icons.directions_bus_rounded : Icons.train_rounded;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 28.0,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2, (size - textPainter.height) / 2),
    );

    if (vehicleNumber != null) {
      const badgeCenter = Offset(size - 13, 13);
      const badgeRadius = 10.0;

      canvas.drawCircle(
        const Offset(size - 13, 14),
        badgeRadius,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );

      canvas.drawCircle(
        badgeCenter,
        badgeRadius,
        Paint()..color = Colors.white,
      );

      canvas.drawCircle(
        badgeCenter,
        badgeRadius - 1.5,
        Paint()..color = const Color(0xFF1E293B),
      );

      final numPainter = TextPainter(textDirection: TextDirection.ltr);
      numPainter.text = TextSpan(
        text: '$vehicleNumber',
        style: const TextStyle(
          fontSize: 11.0,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1.0,
        ),
      );
      numPainter.layout();
      numPainter.paint(
        canvas,
        Offset(
          badgeCenter.dx - (numPainter.width / 2),
          badgeCenter.dy - (numPainter.height / 2),
        ),
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();
    return BitmapDescriptor.bytes(bytes, width: 32, height: 32);
  }
}

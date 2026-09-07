import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as osm;
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
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

  const TransitMapMarker({
    required this.id,
    required this.label,
    required this.coordinate,
    this.kind = TransitMapMarkerKind.standard,
    this.onTap,
  });
}

enum TransitMapMarkerKind {
  standard,
  origin,
  destination,
  stop,
  vehicle,
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
  final double height;
  final Future<bool> Function()? googleMapsAvailable;

  const TransitGoogleMap({
    super.key,
    required this.markers,
    required this.lines,
    this.initialCenter,
    this.showCurrentLocation = false,
    this.height = 320,
    this.googleMapsAvailable,
  });

  @override
  State<TransitGoogleMap> createState() => _TransitGoogleMapState();
}

class _TransitGoogleMapState extends State<TransitGoogleMap> {
  static const _mapSupportChannel = MethodChannel(
    'com.smartroute.app/map-support',
  );

  // Start with the vendor-free map so an unsupported device never constructs
  // a Google platform view. Supported devices upgrade to Google Maps once the
  // native preflight completes.
  bool _isNativeMapAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkMapSupport();
  }

  Future<void> _checkMapSupport() async {
    final available = await _resolveMapSupport();
    if (!mounted) return;
    setState(() => _isNativeMapAvailable = available);
  }

  Future<bool> _resolveMapSupport() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return defaultTargetPlatform == TargetPlatform.iOS;
    }
    try {
      final checker =
          widget.googleMapsAvailable ?? _googlePlayServicesAvailable;
      return await checker();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _googlePlayServicesAvailable() async =>
      await _mapSupportChannel.invokeMethod<bool>(
        'isGooglePlayServicesAvailable',
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final camera = const TransitMapViewport().resolve(
      markers: widget.markers,
      lines: widget.lines,
      fallback: widget.initialCenter,
    );
    return Semantics(
      label: _isNativeMapAvailable == false
          ? 'Interactive OpenStreetMap showing the selected transit journey'
          : 'Interactive Google Map showing the selected transit journey',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: _isNativeMapAvailable
              ? _GoogleMapView(
                  camera: camera,
                  markers: widget.markers,
                  lines: widget.lines,
                  showCurrentLocation: widget.showCurrentLocation,
                )
              : _OpenStreetMapView(
                  camera: camera,
                  markers: widget.markers,
                  lines: widget.lines,
                ),
        ),
      ),
    );
  }
}

class _GoogleMapView extends StatelessWidget {
  final TransitMapCamera camera;
  final List<TransitMapMarker> markers;
  final List<TransitMapLine> lines;
  final bool showCurrentLocation;

  const _GoogleMapView({
    required this.camera,
    required this.markers,
    required this.lines,
    required this.showCurrentLocation,
  });

  @override
  Widget build(BuildContext context) => GoogleMap(
    initialCameraPosition: CameraPosition(
      target: LatLng(camera.center.latitude, camera.center.longitude),
      zoom: camera.zoom,
    ),
    markers: {
      for (final marker in markers)
        Marker(
          markerId: MarkerId(marker.id),
          position: LatLng(
            marker.coordinate.latitude,
            marker.coordinate.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(_markerHue(marker.kind)),
          infoWindow: InfoWindow(title: marker.label),
          onTap: marker.onTap,
        ),
    },
    polylines: {
      for (final line in lines)
        if (line.points.length >= 2)
          Polyline(
            polylineId: PolylineId(line.id),
            color: line.color,
            width: 6,
            jointType: JointType.round,
            points: [
              for (final point in line.points)
                LatLng(point.latitude, point.longitude),
            ],
          ),
    },
    compassEnabled: true,
    mapToolbarEnabled: false,
    myLocationEnabled: showCurrentLocation,
    myLocationButtonEnabled: showCurrentLocation,
    zoomControlsEnabled: false,
  );

  double _markerHue(TransitMapMarkerKind kind) => switch (kind) {
    TransitMapMarkerKind.origin => BitmapDescriptor.hueGreen,
    TransitMapMarkerKind.destination => BitmapDescriptor.hueRed,
    TransitMapMarkerKind.stop => BitmapDescriptor.hueAzure,
    TransitMapMarkerKind.vehicle => BitmapDescriptor.hueViolet,
    TransitMapMarkerKind.transfer => BitmapDescriptor.hueOrange,
    TransitMapMarkerKind.standard => BitmapDescriptor.hueRed,
  };
}

class _OpenStreetMapView extends StatelessWidget {
  static const _tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _openStreetMapCopyrightUrl =
      'https://www.openstreetmap.org/copyright';

  final TransitMapCamera camera;
  final List<TransitMapMarker> markers;
  final List<TransitMapLine> lines;

  const _OpenStreetMapView({
    required this.camera,
    required this.markers,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      flutter_map.FlutterMap(
        options: flutter_map.MapOptions(
          initialCenter: osm.LatLng(
            camera.center.latitude,
            camera.center.longitude,
          ),
          initialZoom: camera.zoom,
          minZoom: 3,
          maxZoom: 19,
          backgroundColor: AppColors.mutedBg,
        ),
        children: [
          flutter_map.TileLayer(
            urlTemplate: _tileUrlTemplate,
            userAgentPackageName: 'com.smartroute.app',
            maxNativeZoom: 19,
            tileDisplay: const flutter_map.TileDisplay.instantaneous(),
          ),
          flutter_map.PolylineLayer(
            polylines: [
              for (final line in lines)
                if (line.points.length >= 2)
                  flutter_map.Polyline(
                    points: [
                      for (final point in line.points)
                        osm.LatLng(point.latitude, point.longitude),
                    ],
                    color: line.color,
                    strokeWidth: 6,
                  ),
            ],
          ),
          flutter_map.MarkerLayer(
            markers: [
              for (final marker in markers)
                flutter_map.Marker(
                  key: ValueKey(marker.id),
                  point: osm.LatLng(
                    marker.coordinate.latitude,
                    marker.coordinate.longitude,
                  ),
                  width: AppSpacing.xxl4,
                  height: AppSpacing.xxl4,
                  alignment: Alignment.topCenter,
                  child: Semantics(
                    label: marker.label,
                    button: marker.onTap != null,
                    child: GestureDetector(
                      onTap: marker.onTap,
                      child: Tooltip(
                        message: marker.label,
                        child: Icon(
                          _markerIcon(marker.kind),
                          color: _markerColor(marker.kind),
                          size: AppSpacing.xxl4,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      Positioned(
        right: AppSpacing.gapXs,
        bottom: AppSpacing.gapXs,
        child: Material(
          color: AppColors.surface,
          child: InkWell(
            onTap: () => launchUrl(Uri.parse(_openStreetMapCopyrightUrl)),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.gapXs,
                vertical: AppSpacing.xs,
              ),
              child: Text(
                '© OpenStreetMap contributors',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  IconData _markerIcon(TransitMapMarkerKind kind) => switch (kind) {
    TransitMapMarkerKind.origin => Icons.trip_origin,
    TransitMapMarkerKind.destination => Icons.location_on,
    TransitMapMarkerKind.stop => Icons.place,
    TransitMapMarkerKind.vehicle => Icons.directions_bus,
    TransitMapMarkerKind.transfer => Icons.swap_horiz,
    TransitMapMarkerKind.standard => Icons.location_on,
  };

  Color _markerColor(TransitMapMarkerKind kind) => switch (kind) {
    TransitMapMarkerKind.origin => AppColors.success,
    TransitMapMarkerKind.destination => AppColors.primary,
    TransitMapMarkerKind.stop => AppColors.secondary,
    TransitMapMarkerKind.vehicle => AppColors.mlLine,
    TransitMapMarkerKind.transfer => AppColors.amber,
    TransitMapMarkerKind.standard => AppColors.primary,
  };
}

class JourneyGoogleMap extends StatelessWidget {
  final JourneyOption journey;
  final TransitNetwork network;
  final bool showCurrentLocation;
  final double height;
  final ValueChanged<String>? onStopTap;

  const JourneyGoogleMap({
    super.key,
    required this.journey,
    required this.network,
    this.showCurrentLocation = false,
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
      height: height,
    );
  }
}

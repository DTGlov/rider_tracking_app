import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/models/geo_coordinate.dart';

LatLng toMapCoordinate(GeoCoordinate coordinate) {
  return LatLng(coordinate.latitude, coordinate.longitude);
}

List<LatLng> toMapCoordinates(Iterable<GeoCoordinate> coordinates) {
  return coordinates.map(toMapCoordinate).toList(growable: false);
}

GeoCoordinate interpolateCoordinate(
  GeoCoordinate start,
  GeoCoordinate end,
  double progress,
) {
  final clampedProgress = progress.clamp(0.0, 1.0);
  return GeoCoordinate(
    latitude:
        start.latitude + (end.latitude - start.latitude) * clampedProgress,
    longitude:
        start.longitude + (end.longitude - start.longitude) * clampedProgress,
  );
}

class TrackingMap extends StatefulWidget {
  const TrackingMap({
    required this.route,
    required this.destination,
    this.riderLocation,
    super.key,
  });

  final List<GeoCoordinate> route;
  final GeoCoordinate destination;
  final GeoCoordinate? riderLocation;

  @override
  State<TrackingMap> createState() => _TrackingMapState();
}

class _TrackingMapState extends State<TrackingMap>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _riderAnimation;
  GeoCoordinate? _animationStart;
  GeoCoordinate? _animationTarget;
  GeoCoordinate? _displayedRiderLocation;
  var _followEnabled = true;
  var _mapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _riderAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..addListener(_handleAnimationTick);
    _displayedRiderLocation = widget.riderLocation;
  }

  @override
  void didUpdateWidget(covariant TrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextLocation = widget.riderLocation;
    if (nextLocation == oldWidget.riderLocation) {
      return;
    }

    if (nextLocation == null) {
      _riderAnimation.stop();
      _displayedRiderLocation = null;
      _animationStart = null;
      _animationTarget = null;
      return;
    }

    final currentLocation = _displayedRiderLocation;
    if (currentLocation == null) {
      _displayedRiderLocation = nextLocation;
      return;
    }

    _animationStart = currentLocation;
    _animationTarget = nextLocation;
    _riderAnimation
      ..stop()
      ..value = 0
      ..forward();
  }

  @override
  void dispose() {
    _riderAnimation.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _handleAnimationTick() {
    final start = _animationStart;
    final target = _animationTarget;
    if (!mounted || start == null || target == null) {
      return;
    }

    final location = interpolateCoordinate(
      start,
      target,
      Curves.easeOut.transform(_riderAnimation.value),
    );
    setState(() => _displayedRiderLocation = location);
    _followRider(location);
  }

  void _followRider(GeoCoordinate location) {
    if (_followEnabled && _mapReady) {
      _mapController.move(
        toMapCoordinate(location),
        _mapController.camera.zoom,
      );
    }
  }

  void _handleMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture && _followEnabled) {
      setState(() => _followEnabled = false);
    }
  }

  void _recenterAndFollow() {
    setState(() => _followEnabled = true);
    final location = _displayedRiderLocation;
    if (location != null && _mapReady) {
      _mapController.move(
        toMapCoordinate(location),
        _mapController.camera.zoom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final routePoints = toMapCoordinates(widget.route);
    final markers = <Marker>[
      Marker(
        key: const ValueKey('origin-marker'),
        point: routePoints.first,
        width: 36,
        height: 36,
        child: const _MapMarker(
          icon: Icons.trip_origin,
          color: Colors.white,
          backgroundColor: Colors.blue,
        ),
      ),
      Marker(
        key: const ValueKey('destination-marker'),
        point: toMapCoordinate(widget.destination),
        width: 36,
        height: 36,
        child: const _MapMarker(
          icon: Icons.flag,
          color: Colors.white,
          backgroundColor: Colors.red,
        ),
      ),
    ];

    final rider = _displayedRiderLocation;
    if (rider != null) {
      markers.add(
        Marker(
          key: const ValueKey('rider-marker'),
          point: toMapCoordinate(rider),
          width: 48,
          height: 48,
          child: const _MapMarker(
            icon: Icons.two_wheeler,
            color: Colors.white,
            backgroundColor: Colors.teal,
          ),
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: FlutterMap(
            key: const ValueKey('tracking-map'),
            mapController: _mapController,
            options: MapOptions(
              initialCameraFit: CameraFit.coordinates(
                coordinates: routePoints,
                padding: const EdgeInsets.all(56),
                maxZoom: 16,
              ),
              onMapReady: () => setState(() => _mapReady = true),
              onPositionChanged: _handleMapPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.rider_tracking_app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 5,
                  ),
                ],
              ),
              MarkerLayer(markers: markers),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
        ),
        if (!_followEnabled)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FloatingActionButton.small(
                key: const ValueKey('recenter-follow-button'),
                onPressed: _recenterAndFollow,
                tooltip: 'Follow rider',
                child: const Icon(Icons.my_location),
              ),
            ),
          ),
      ],
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

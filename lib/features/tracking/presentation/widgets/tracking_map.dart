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

class TrackingMap extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final routePoints = toMapCoordinates(route);
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
        point: toMapCoordinate(destination),
        width: 36,
        height: 36,
        child: const _MapMarker(
          icon: Icons.flag,
          color: Colors.white,
          backgroundColor: Colors.red,
        ),
      ),
    ];

    final rider = riderLocation;
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

    return FlutterMap(
      key: const ValueKey('tracking-map'),
      options: MapOptions(
        initialCameraFit: CameraFit.coordinates(
          coordinates: routePoints,
          padding: const EdgeInsets.all(56),
          maxZoom: 16,
        ),
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
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
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

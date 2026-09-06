import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rider_tracking_app/features/tracking/domain/models/geo_coordinate.dart';
import 'package:rider_tracking_app/features/tracking/presentation/widgets/tracking_map.dart';

void main() {
  const route = [
    GeoCoordinate(latitude: 5.0, longitude: -0.2),
    GeoCoordinate(latitude: 5.1, longitude: -0.1),
    GeoCoordinate(latitude: 5.2, longitude: 0.0),
  ];
  const destination = GeoCoordinate(latitude: 5.2, longitude: 0.0);

  test('converts tracking coordinates to map coordinates', () {
    expect(toMapCoordinate(route.first), const LatLng(5.0, -0.2));
    expect(toMapCoordinates(route), const [
      LatLng(5.0, -0.2),
      LatLng(5.1, -0.1),
      LatLng(5.2, 0.0),
    ]);
  });

  testWidgets('passes the route and current rider position to map layers', (
    WidgetTester tester,
  ) async {
    const firstRider = GeoCoordinate(latitude: 5.05, longitude: -0.15);
    const nextRider = GeoCoordinate(latitude: 5.15, longitude: -0.05);

    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 400,
          height: 400,
          child: TrackingMap(
            route: route,
            destination: destination,
            riderLocation: firstRider,
          ),
        ),
      ),
    );

    var markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    var riderMarker = markerLayer.markers.singleWhere(
      (marker) => marker.key == const ValueKey('rider-marker'),
    );
    expect(riderMarker.point, toMapCoordinate(firstRider));

    final polylineLayer = tester.widget<PolylineLayer<Object>>(
      find.byType(PolylineLayer<Object>),
    );
    expect(polylineLayer.polylines.single.points, toMapCoordinates(route));

    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 400,
          height: 400,
          child: TrackingMap(
            route: route,
            destination: destination,
            riderLocation: nextRider,
          ),
        ),
      ),
    );

    markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    riderMarker = markerLayer.markers.singleWhere(
      (marker) => marker.key == const ValueKey('rider-marker'),
    );
    expect(riderMarker.point, toMapCoordinate(nextRider));
  });
}

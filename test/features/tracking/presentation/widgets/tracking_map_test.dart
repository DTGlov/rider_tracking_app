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

  test('interpolates rider coordinates and clamps progress', () {
    const start = GeoCoordinate(latitude: 5.0, longitude: -0.2);
    const end = GeoCoordinate(latitude: 5.2, longitude: 0.0);

    expect(
      interpolateCoordinate(start, end, 0.5),
      const GeoCoordinate(latitude: 5.1, longitude: -0.1),
    );
    expect(interpolateCoordinate(start, end, -1), start);
    expect(interpolateCoordinate(start, end, 2), end);
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
    await tester.pump(const Duration(milliseconds: 700));

    markerLayer = tester.widget<MarkerLayer>(find.byType(MarkerLayer));
    riderMarker = markerLayer.markers.singleWhere(
      (marker) => marker.key == const ValueKey('rider-marker'),
    );
    expect(riderMarker.point, toMapCoordinate(nextRider));
  });

  testWidgets('manual map movement disables follow and recenter restores it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 400,
          height: 400,
          child: TrackingMap(
            route: route,
            destination: destination,
            riderLocation: GeoCoordinate(latitude: 5.05, longitude: -0.15),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('recenter-follow-button')), findsNothing);

    await tester.drag(
      find.byKey(const ValueKey('tracking-map')),
      const Offset(100, 0),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('recenter-follow-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('recenter-follow-button')));
    await tester.pump();

    expect(find.byKey(const ValueKey('recenter-follow-button')), findsNothing);
  });
}

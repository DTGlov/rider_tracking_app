import 'package:flutter_test/flutter_test.dart';
import 'package:rider_tracking_app/features/tracking/data/datasources/local_tracking_simulator.dart';
import 'package:rider_tracking_app/features/tracking/data/datasources/tracking_simulation_driver.dart';
import 'package:rider_tracking_app/features/tracking/domain/models/geo_coordinate.dart';
import 'package:rider_tracking_app/features/tracking/domain/models/tracking_status.dart';

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

bool _isNonIncreasing(List<num> values) {
  for (var index = 1; index < values.length; index++) {
    if (values[index] > values[index - 1]) {
      return false;
    }
  }
  return true;
}

void main() {
  group('LocalTrackingSimulator', () {
    test('emits multiple snapshots in order and completes cleanly', () async {
      final driver = ManualTrackingSimulationDriver();
      final simulator = LocalTrackingSimulator(
        driver: driver,
        route: const [
          GeoCoordinate(latitude: 1.0, longitude: 1.0),
          GeoCoordinate(latitude: 1.001, longitude: 1.001),
          GeoCoordinate(latitude: 1.002, longitude: 1.002),
        ],
        tickInterval: const Duration(seconds: 1),
        speedMetersPerSecond: 120,
        startTime: DateTime.utc(2026, 9, 5, 12),
      );

      final snapshotsFuture = simulator.watchTracking().toList();
      await _flushMicrotasks();
      driver.advance(10);

      final snapshots = await snapshotsFuture;

      expect(snapshots.length, greaterThan(1));
      expect(snapshots.first.status, TrackingStatus.riderAssigned);
      expect(snapshots.last.status, TrackingStatus.delivered);
      expect(snapshots.last.riderLocation, snapshots.last.destination);
      expect(snapshots.last.remainingDistanceMeters, 0);
      expect(snapshots.last.eta, Duration.zero);
      expect(
        snapshots.map((snapshot) => snapshot.updatedAt).toList(),
        isNotEmpty,
      );
      expect(
        snapshots
            .map((snapshot) => snapshot.updatedAt)
            .toList()
            .asMap()
            .entries
            .skip(1)
            .every(
              (entry) =>
                  entry.value.isAfter(snapshots[entry.key - 1].updatedAt) ||
                  entry.value.isAtSameMomentAs(
                    snapshots[entry.key - 1].updatedAt,
                  ),
            ),
        isTrue,
      );
    });

    test(
      'rider position changes and remaining distance decreases over time',
      () async {
        final driver = ManualTrackingSimulationDriver();
        final simulator = LocalTrackingSimulator(
          driver: driver,
          route: const [
            GeoCoordinate(latitude: 5.0, longitude: -1.0),
            GeoCoordinate(latitude: 5.0005, longitude: -0.9995),
            GeoCoordinate(latitude: 5.0010, longitude: -0.9990),
            GeoCoordinate(latitude: 5.0015, longitude: -0.9985),
          ],
          tickInterval: const Duration(seconds: 1),
          speedMetersPerSecond: 100,
          startTime: DateTime.utc(2026, 9, 5, 12),
        );

        final snapshotsFuture = simulator.watchTracking().toList();
        await _flushMicrotasks();
        driver.advance(10);

        final snapshots = await snapshotsFuture;

        expect(
          snapshots.first.riderLocation,
          isNot(equals(snapshots.last.riderLocation)),
        );
        expect(
          _isNonIncreasing(
            snapshots
                .map((snapshot) => snapshot.remainingDistanceMeters)
                .toList(),
          ),
          isTrue,
        );
        expect(
          _isNonIncreasing(
            snapshots.map((snapshot) => snapshot.eta?.inSeconds ?? 0).toList(),
          ),
          isTrue,
        );
        expect(snapshots.last.status, TrackingStatus.delivered);
      },
    );
  });
}

import 'dart:async';
import 'dart:math' as math;

import '../../domain/models/geo_coordinate.dart';
import '../../domain/models/tracking_route.dart';
import '../../domain/models/tracking_snapshot.dart';
import '../../domain/models/tracking_status.dart';
import 'tracking_simulation_driver.dart';

class LocalTrackingSimulator {
  LocalTrackingSimulator({
    TrackingSimulationDriver? driver,
    List<GeoCoordinate>? route,
    Duration tickInterval = const Duration(milliseconds: 750),
    double speedMetersPerSecond = 10,
    DateTime? startTime,
  }) : _driver =
           driver ?? PeriodicTrackingSimulationDriver(interval: tickInterval),
       _route = route ?? defaultTrackingRoute,
       _tickInterval = tickInterval,
       _speedMetersPerSecond = speedMetersPerSecond,
       _startTime = startTime ?? DateTime.utc(2026, 9, 5, 12) {
    if (_route.length < 2) {
      throw ArgumentError.value(_route, 'route', 'needs at least two points');
    }
  }

  final TrackingSimulationDriver _driver;
  final List<GeoCoordinate> _route;
  final Duration _tickInterval;
  final double _speedMetersPerSecond;
  final DateTime _startTime;

  Stream<TrackingSnapshot> watchTracking() {
    late final StreamController<TrackingSnapshot> controller;
    StreamSubscription<void>? subscription;
    var isCleaningUp = false;
    var state = _RouteProgress.initial(
      route: _route,
      tickInterval: _tickInterval,
      speedMetersPerSecond: _speedMetersPerSecond,
      startTime: _startTime,
    );

    Future<void> finish() async {
      if (isCleaningUp) {
        return;
      }
      isCleaningUp = true;
      await subscription?.cancel();
      await _driver.dispose();
      if (!controller.isClosed) {
        await controller.close();
      }
    }

    controller = StreamController<TrackingSnapshot>(
      onListen: () {
        controller.add(state.snapshot);
        subscription = _driver.ticks.listen(
          (_) {
            if (state.isComplete) {
              unawaited(finish());
              return;
            }

            state = state.advance();
            controller.add(state.snapshot);

            if (state.isComplete) {
              unawaited(finish());
            }
          },
          onError: controller.addError,
          onDone: () {
            if (!controller.isClosed) {
              unawaited(controller.close());
            }
          },
        );
      },
      onCancel: () async {
        if (!isCleaningUp) {
          await finish();
        }
      },
    );

    return controller.stream;
  }
}

class _RouteProgress {
  const _RouteProgress({
    required this.route,
    required this.tickInterval,
    required this.speedMetersPerSecond,
    required this.startTime,
    required this.elapsedTicks,
    required this.distanceTravelledMeters,
    required this.totalDistanceMeters,
    required this.segmentDistances,
    required this.segmentOffsets,
  });

  factory _RouteProgress.initial({
    required List<GeoCoordinate> route,
    required Duration tickInterval,
    required double speedMetersPerSecond,
    required DateTime startTime,
  }) {
    final segmentDistances = <double>[];
    final segmentOffsets = <double>[0];
    var totalDistance = 0.0;

    for (var index = 0; index < route.length - 1; index++) {
      final segmentDistance = _distanceBetween(route[index], route[index + 1]);
      segmentDistances.add(segmentDistance);
      totalDistance += segmentDistance;
      segmentOffsets.add(totalDistance);
    }

    return _RouteProgress(
      route: route,
      tickInterval: tickInterval,
      speedMetersPerSecond: speedMetersPerSecond,
      startTime: startTime,
      elapsedTicks: 0,
      distanceTravelledMeters: 0,
      totalDistanceMeters: totalDistance,
      segmentDistances: segmentDistances,
      segmentOffsets: segmentOffsets,
    );
  }

  final List<GeoCoordinate> route;
  final Duration tickInterval;
  final double speedMetersPerSecond;
  final DateTime startTime;
  final int elapsedTicks;
  final double distanceTravelledMeters;
  final double totalDistanceMeters;
  final List<double> segmentDistances;
  final List<double> segmentOffsets;

  bool get isComplete => distanceTravelledMeters >= totalDistanceMeters;

  _RouteProgress advance() {
    final nextDistance = math.min(
      totalDistanceMeters,
      distanceTravelledMeters +
          speedMetersPerSecond * tickInterval.inMilliseconds / 1000,
    );

    return _RouteProgress(
      route: route,
      tickInterval: tickInterval,
      speedMetersPerSecond: speedMetersPerSecond,
      startTime: startTime,
      elapsedTicks: elapsedTicks + 1,
      distanceTravelledMeters: nextDistance,
      totalDistanceMeters: totalDistanceMeters,
      segmentDistances: segmentDistances,
      segmentOffsets: segmentOffsets,
    );
  }

  TrackingSnapshot get snapshot {
    final currentLocation = _positionAt(distanceTravelledMeters);
    final destination = route.last;
    final remainingDistance = math
        .max(0.0, totalDistanceMeters - distanceTravelledMeters)
        .toDouble();
    final eta = remainingDistance <= 0
        ? Duration.zero
        : Duration(
            milliseconds: (remainingDistance / speedMetersPerSecond * 1000)
                .round(),
          );
    final status = remainingDistance <= 0
        ? TrackingStatus.delivered
        : remainingDistance < totalDistanceMeters * 0.2
        ? TrackingStatus.arriving
        : distanceTravelledMeters <= 0
        ? TrackingStatus.riderAssigned
        : TrackingStatus.enRoute;

    return TrackingSnapshot(
      status: status,
      riderLocation: currentLocation,
      destination: destination,
      remainingDistanceMeters: remainingDistance,
      eta: eta,
      updatedAt: startTime.add(
        Duration(milliseconds: tickInterval.inMilliseconds * elapsedTicks),
      ),
    );
  }

  GeoCoordinate _positionAt(double distanceMeters) {
    if (distanceMeters <= 0) {
      return route.first;
    }

    if (distanceMeters >= totalDistanceMeters) {
      return route.last;
    }

    for (var index = 0; index < segmentDistances.length; index++) {
      final segmentStart = segmentOffsets[index];
      final segmentEnd = segmentOffsets[index + 1];
      if (distanceMeters <= segmentEnd) {
        final segmentDistance = segmentDistances[index];
        final segmentProgress =
            (distanceMeters - segmentStart) / segmentDistance;
        return _interpolate(route[index], route[index + 1], segmentProgress);
      }
    }

    return route.last;
  }
}

double _distanceBetween(GeoCoordinate a, GeoCoordinate b) {
  const earthRadiusMeters = 6371000.0;
  final lat1 = _toRadians(a.latitude);
  final lat2 = _toRadians(b.latitude);
  final deltaLat = _toRadians(b.latitude - a.latitude);
  final deltaLon = _toRadians(b.longitude - a.longitude);

  final haversine =
      math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
      math.cos(lat1) *
          math.cos(lat2) *
          math.sin(deltaLon / 2) *
          math.sin(deltaLon / 2);
  final angularDistance =
      2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  return earthRadiusMeters * angularDistance;
}

double _toRadians(double degrees) => degrees * math.pi / 180;

GeoCoordinate _interpolate(
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

import '../../domain/models/geo_coordinate.dart';
import '../../domain/models/tracking_snapshot.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/local_tracking_simulator.dart';
import '../datasources/tracking_simulation_driver.dart';

class LocalTrackingRepository implements TrackingRepository {
  LocalTrackingRepository({
    List<GeoCoordinate>? route,
    Duration tickInterval = const Duration(milliseconds: 750),
    double speedMetersPerSecond = 10,
    DateTime? startTime,
    TrackingSimulationDriver? driver,
  }) : _route = route,
       _tickInterval = tickInterval,
       _speedMetersPerSecond = speedMetersPerSecond,
       _startTime = startTime ?? DateTime.utc(2026, 9, 5, 12),
       _driver = driver;

  final List<GeoCoordinate>? _route;
  final Duration _tickInterval;
  final double _speedMetersPerSecond;
  final DateTime _startTime;
  final TrackingSimulationDriver? _driver;

  @override
  Stream<TrackingSnapshot> watchTracking() {
    final simulator = LocalTrackingSimulator(
      route: _route,
      tickInterval: _tickInterval,
      speedMetersPerSecond: _speedMetersPerSecond,
      startTime: _startTime,
      driver: _driver,
    );
    return simulator.watchTracking();
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:rider_tracking_app/features/tracking/data/datasources/tracking_simulation_driver.dart';
import 'package:rider_tracking_app/features/tracking/data/repositories/local_tracking_repository.dart';
import 'package:rider_tracking_app/features/tracking/domain/models/geo_coordinate.dart';
import 'package:rider_tracking_app/features/tracking/domain/models/tracking_status.dart';
import 'package:rider_tracking_app/features/tracking/presentation/view_models/tracking_view_model.dart';

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  group('TrackingViewModel', () {
    test('reflects repository updates and completes', () async {
      final driver = ManualTrackingSimulationDriver();
      final repository = LocalTrackingRepository(
        driver: driver,
        route: const [
          GeoCoordinate(latitude: 2.0, longitude: 2.0),
          GeoCoordinate(latitude: 2.001, longitude: 2.001),
          GeoCoordinate(latitude: 2.002, longitude: 2.002),
        ],
        tickInterval: const Duration(seconds: 1),
        speedMetersPerSecond: 150,
        startTime: DateTime.utc(2026, 9, 5, 12),
      );

      final viewModel = TrackingViewModel(repository: repository);
      addTearDown(viewModel.dispose);

      expect(viewModel.state.isLoading, isTrue);
      expect(viewModel.isSubscribed, isTrue);

      driver.advance(2);
      await _flushMicrotasks();

      expect(viewModel.state.isLoading, isFalse);
      expect(viewModel.state.hasLiveData, isTrue);
      expect(viewModel.state.status, isNot(TrackingStatus.idle));
      expect(viewModel.state.remainingDistanceMeters, isNotNull);

      driver.advance(20);
      await _flushMicrotasks();

      expect(viewModel.state.isComplete, isTrue);
      expect(viewModel.state.status, TrackingStatus.delivered);
      expect(viewModel.state.remainingDistanceMeters, 0);
      expect(viewModel.state.eta, Duration.zero);
    });

    test('cleanup cancels the active subscription', () async {
      final driver = ManualTrackingSimulationDriver();
      final repository = LocalTrackingRepository(
        driver: driver,
        route: const [
          GeoCoordinate(latitude: 3.0, longitude: 3.0),
          GeoCoordinate(latitude: 3.001, longitude: 3.001),
        ],
        tickInterval: const Duration(seconds: 1),
        speedMetersPerSecond: 20,
        startTime: DateTime.utc(2026, 9, 5, 12),
      );

      final viewModel = TrackingViewModel(repository: repository);

      expect(driver.activeListenerCount, 1);

      viewModel.dispose();
      await _flushMicrotasks();

      expect(driver.activeListenerCount, 0);
    });
  });
}

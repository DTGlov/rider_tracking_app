import 'package:flutter_test/flutter_test.dart';
import 'package:rider_tracking_app/app/tracking_composition.dart';
import 'package:rider_tracking_app/app/tracking_source_config.dart';
import 'package:rider_tracking_app/features/tracking/data/repositories/local_tracking_repository.dart';
import 'package:rider_tracking_app/features/tracking/data/repositories/web_socket_tracking_repository.dart';

void main() {
  group('TrackingAppConfig', () {
    test('defaults to local mode', () {
      final config = TrackingAppConfig.fromValues();

      expect(config.sourceMode, TrackingSourceMode.local);
      expect(config.webSocketUrl, isNull);
    });

    test('parses websocket mode and URL', () {
      final config = TrackingAppConfig.fromValues(
        source: 'websocket',
        webSocketUrl: 'ws://localhost:8080/ws/tracking',
      );

      expect(config.sourceMode, TrackingSourceMode.webSocket);
      expect(config.webSocketUrl, Uri.parse('ws://localhost:8080/ws/tracking'));
    });

    test('rejects unsupported source values', () {
      expect(
        () => TrackingAppConfig.fromValues(source: 'unknown'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects websocket mode without a valid URL', () {
      expect(
        () => TrackingAppConfig.fromValues(source: 'websocket'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => TrackingAppConfig.fromValues(
          source: 'websocket',
          webSocketUrl: 'http://localhost:8080/ws/tracking',
        ),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('createTrackingRepository', () {
    test('selects the local repository for local mode', () {
      final repository = createTrackingRepository(
        TrackingAppConfig.fromValues(),
      );

      expect(repository, isA<LocalTrackingRepository>());
    });

    test('selects the websocket repository for websocket mode', () {
      final repository = createTrackingRepository(
        TrackingAppConfig.fromValues(
          source: 'websocket',
          webSocketUrl: 'ws://localhost:8080/ws/tracking',
        ),
      );

      expect(repository, isA<WebSocketTrackingRepository>());
    });
  });
}

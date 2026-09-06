import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rider_tracking_app/features/tracking/data/datasources/web_socket_tracking_data_source.dart';
import 'package:rider_tracking_app/features/tracking/data/datasources/web_socket_tracking_update.dart';
import 'package:rider_tracking_app/features/tracking/data/repositories/web_socket_tracking_repository.dart';
import 'package:rider_tracking_app/features/tracking/domain/models/geo_coordinate.dart';
import 'package:rider_tracking_app/features/tracking/domain/models/tracking_snapshot.dart';
import 'package:rider_tracking_app/features/tracking/domain/models/tracking_status.dart';

const _validMessage = '''
{
  "tripId": "trip-demo-001",
  "sequence": 7,
  "timestamp": "2026-09-05T12:00:01.500Z",
  "latitude": 5.6043,
  "longitude": -0.1860,
  "remainingDistanceMeters": 512.4,
  "etaSeconds": 10,
  "status": "enRoute"
}
''';

class _FakeConnection implements WebSocketTrackingConnection {
  _FakeConnection(this.controller);

  final StreamController<Object?> controller;
  var closeCount = 0;

  @override
  Stream<Object?> get messages => controller.stream;

  @override
  Future<void> close() async {
    closeCount++;
    await controller.close();
  }
}

void main() {
  test('decodes the Phase 6A tracking contract', () {
    final update = WebSocketTrackingUpdate.fromJson(_validMessage);

    expect(update.tripId, 'trip-demo-001');
    expect(update.sequence, 7);
    expect(update.timestamp, DateTime.utc(2026, 9, 5, 12, 0, 1, 500));
    expect(
      update.riderLocation,
      const GeoCoordinate(latitude: 5.6043, longitude: -0.186),
    );
    expect(update.remainingDistanceMeters, 512.4);
    expect(update.etaSeconds, 10);
    expect(update.status, TrackingStatus.enRoute);
  });

  test('rejects malformed JSON and unsupported statuses', () {
    expect(
      () => WebSocketTrackingUpdate.fromJson('{"status":"enRoute"'),
      throwsA(isA<FormatException>()),
    );

    final unsupported = _validMessage.replaceAll('"enRoute"', '"paused"');
    expect(
      () => WebSocketTrackingUpdate.fromJson(unsupported),
      throwsA(isA<FormatException>()),
    );
  });

  test('repository maps wire updates to domain snapshots', () async {
    final messages = StreamController<Object?>();
    final connection = _FakeConnection(messages);
    final source = WebSocketTrackingDataSource(
      url: Uri.parse('ws://example.test/ws/tracking'),
      connectionFactory: (_) => connection,
    );
    final repository = WebSocketTrackingRepository(
      dataSource: source,
      destination: const GeoCoordinate(latitude: 5.6072, longitude: -0.1819),
    );
    final snapshots = <TrackingSnapshot>[];
    final subscription = repository.watchTracking().listen(snapshots.add);
    addTearDown(subscription.cancel);

    messages.add(_validMessage);
    await Future<void>.delayed(Duration.zero);

    expect(snapshots, hasLength(1));
    final snapshot = snapshots.single;
    expect(
      snapshot.riderLocation,
      const GeoCoordinate(latitude: 5.6043, longitude: -0.186),
    );
    expect(
      snapshot.destination,
      const GeoCoordinate(latitude: 5.6072, longitude: -0.1819),
    );
    expect(snapshot.remainingDistanceMeters, 512.4);
    expect(snapshot.eta, const Duration(seconds: 10));
    expect(snapshot.status, TrackingStatus.enRoute);
  });

  test(
    'source surfaces malformed messages and closes its connection',
    () async {
      final messages = StreamController<Object?>();
      final connection = _FakeConnection(messages);
      final source = WebSocketTrackingDataSource(
        url: Uri.parse('ws://example.test/ws/tracking'),
        connectionFactory: (_) => connection,
      );
      final errors = <Object>[];
      final subscription = source.watchUpdates().listen(
        (_) {},
        onError: errors.add,
      );

      messages.add('{"status":"unsupported"}');
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(errors, hasLength(1));
      expect(errors.single, isA<FormatException>());
      expect(connection.closeCount, 1);
    },
  );
}

import '../../domain/models/geo_coordinate.dart';
import '../../domain/models/tracking_route.dart';
import '../../domain/models/tracking_snapshot.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/web_socket_tracking_data_source.dart';

class WebSocketTrackingRepository implements TrackingRepository {
  WebSocketTrackingRepository({
    required WebSocketTrackingDataSource dataSource,
    GeoCoordinate? destination,
  }) : _dataSource = dataSource,
       _destination = destination ?? defaultTrackingRoute.last;

  final WebSocketTrackingDataSource _dataSource;
  final GeoCoordinate _destination;

  @override
  Stream<TrackingSnapshot> watchTracking() {
    return _dataSource.watchUpdates().map(
      (update) => TrackingSnapshot(
        status: update.status,
        riderLocation: update.riderLocation,
        destination: _destination,
        remainingDistanceMeters: update.remainingDistanceMeters,
        eta: Duration(seconds: update.etaSeconds),
        updatedAt: update.timestamp,
      ),
    );
  }
}

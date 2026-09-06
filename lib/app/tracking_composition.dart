import '../features/tracking/data/datasources/web_socket_tracking_data_source.dart';
import '../features/tracking/data/repositories/local_tracking_repository.dart';
import '../features/tracking/data/repositories/web_socket_tracking_repository.dart';
import '../features/tracking/domain/repositories/tracking_repository.dart';
import 'tracking_source_config.dart';

TrackingRepository createTrackingRepository(TrackingAppConfig config) {
  return switch (config.sourceMode) {
    TrackingSourceMode.local => LocalTrackingRepository(),
    TrackingSourceMode.webSocket => WebSocketTrackingRepository(
      dataSource: WebSocketTrackingDataSource(url: config.webSocketUrl!),
    ),
  };
}

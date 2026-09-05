import '../models/tracking_snapshot.dart';

abstract class TrackingRepository {
  Stream<TrackingSnapshot> watchTracking();
}

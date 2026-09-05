import 'geo_coordinate.dart';
import 'tracking_status.dart';

class TrackingSnapshot {
  const TrackingSnapshot({
    required this.status,
    required this.riderLocation,
    required this.destination,
    required this.remainingDistanceMeters,
    required this.updatedAt,
    this.eta,
  });

  final TrackingStatus status;
  final GeoCoordinate riderLocation;
  final GeoCoordinate destination;
  final double remainingDistanceMeters;
  final Duration? eta;
  final DateTime updatedAt;

  TrackingSnapshot copyWith({
    TrackingStatus? status,
    GeoCoordinate? riderLocation,
    GeoCoordinate? destination,
    double? remainingDistanceMeters,
    Duration? eta,
    DateTime? updatedAt,
  }) {
    return TrackingSnapshot(
      status: status ?? this.status,
      riderLocation: riderLocation ?? this.riderLocation,
      destination: destination ?? this.destination,
      remainingDistanceMeters:
          remainingDistanceMeters ?? this.remainingDistanceMeters,
      eta: eta ?? this.eta,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TrackingSnapshot &&
        other.status == status &&
        other.riderLocation == riderLocation &&
        other.destination == destination &&
        other.remainingDistanceMeters == remainingDistanceMeters &&
        other.eta == eta &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      riderLocation,
      destination,
      remainingDistanceMeters,
      eta,
      updatedAt,
    );
  }
}

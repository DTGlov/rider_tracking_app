enum TrackingStatus {
  idle,
  preparing,
  riderAssigned,
  enRoute,
  arriving,
  delivered,
  cancelled,
}

extension TrackingStatusLabel on TrackingStatus {
  String get label {
    return switch (this) {
      TrackingStatus.idle => 'Idle',
      TrackingStatus.preparing => 'Preparing',
      TrackingStatus.riderAssigned => 'Rider assigned',
      TrackingStatus.enRoute => 'En route',
      TrackingStatus.arriving => 'Arriving',
      TrackingStatus.delivered => 'Delivered',
      TrackingStatus.cancelled => 'Cancelled',
    };
  }
}

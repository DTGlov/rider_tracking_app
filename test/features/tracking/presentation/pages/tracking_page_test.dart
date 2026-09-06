import 'package:flutter_test/flutter_test.dart';
import 'package:rider_tracking_app/features/tracking/domain/models/tracking_status.dart';
import 'package:rider_tracking_app/features/tracking/presentation/pages/tracking_page.dart';

void main() {
  group('tracking experience presentation helpers', () {
    test('uses friendly status copy for each tracking status', () {
      expect(
        statusMessageFor(TrackingStatus.preparing),
        'Dobz is getting ready',
      );
      expect(
        statusMessageFor(TrackingStatus.riderAssigned),
        'Dobz is on the way',
      );
      expect(statusMessageFor(TrackingStatus.enRoute), 'Dobz is on the way');
      expect(statusMessageFor(TrackingStatus.arriving), 'Dobz is almost there');
      expect(statusMessageFor(TrackingStatus.delivered), 'Delivered!');
      expect(statusMessageFor(TrackingStatus.cancelled), 'Delivery cancelled');
    });

    test('formats ETA and remaining distance for people', () {
      expect(formatEta(const Duration(minutes: 8, seconds: 2)), '8 min');
      expect(formatEta(Duration.zero), 'Now');
      expect(formatEta(null), '--');
      expect(formatRemainingDistance(850), '850 m away');
      expect(formatRemainingDistance(1800), '1.8 km away');
      expect(formatRemainingDistance(null), '--');
    });

    test('maps tracking status to delivery progress', () {
      expect(deliveryProgressFor(TrackingStatus.preparing), 0.25);
      expect(deliveryProgressFor(TrackingStatus.enRoute), 0.65);
      expect(deliveryProgressFor(TrackingStatus.arriving), 0.88);
      expect(deliveryProgressFor(TrackingStatus.delivered), 1);
    });
  });
}

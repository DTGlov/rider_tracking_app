import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/tracking_route.dart';
import '../../domain/models/tracking_status.dart';
import '../view_models/tracking_view_model.dart';
import '../widgets/tracking_map.dart';

const String riderName = 'Dobz';

String statusMessageFor(TrackingStatus status) {
  return switch (status) {
    TrackingStatus.idle || TrackingStatus.preparing => 'Dobz is getting ready',
    TrackingStatus.riderAssigned ||
    TrackingStatus.enRoute => 'Dobz is on the way',
    TrackingStatus.arriving => 'Dobz is almost there',
    TrackingStatus.delivered => 'Delivered!',
    TrackingStatus.cancelled => 'Delivery cancelled',
  };
}

String formatEta(Duration? eta) {
  if (eta == null) {
    return '--';
  }
  if (eta == Duration.zero) {
    return 'Now';
  }

  final minutes = eta.inMinutes.clamp(1, double.infinity).toInt();
  return '$minutes min';
}

String formatRemainingDistance(double? distanceMeters) {
  if (distanceMeters == null) {
    return '--';
  }
  if (distanceMeters < 1000) {
    return '${distanceMeters.round()} m away';
  }

  final distanceKm = distanceMeters / 1000;
  final precision = distanceKm < 10 ? 1 : 0;
  return '${distanceKm.toStringAsFixed(precision)} km away';
}

double deliveryProgressFor(TrackingStatus status) {
  return switch (status) {
    TrackingStatus.idle => 0,
    TrackingStatus.preparing => 0.25,
    TrackingStatus.riderAssigned => 0.45,
    TrackingStatus.enRoute => 0.65,
    TrackingStatus.arriving => 0.88,
    TrackingStatus.delivered => 1,
    TrackingStatus.cancelled => 0,
  };
}

class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<TrackingViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Rider Tracking')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: viewModel,
          builder: (BuildContext context, Widget? child) {
            final state = viewModel.state;

            return Stack(
              fit: StackFit.expand,
              children: [
                TrackingMap(
                  route: defaultTrackingRoute,
                  destination: state.destination ?? defaultTrackingRoute.last,
                  riderLocation: state.riderLocation,
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _DeliveryInfoPanel(state: state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DeliveryInfoPanel extends StatelessWidget {
  const _DeliveryInfoPanel({required this.state});

  final TrackingViewState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 8,
          shadowColor: Colors.black38,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live simulator diagnostics',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                _StatusHeader(state: state),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HighlightMetric(
                        icon: Icons.schedule_rounded,
                        value: formatEta(state.eta),
                        label: 'ETA',
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HighlightMetric(
                        icon: Icons.near_me_rounded,
                        value: formatRemainingDistance(
                          state.remainingDistanceMeters,
                        ),
                        label: 'Remaining distance',
                        color: colors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const _RiderIdentity(),
                const SizedBox(height: 18),
                _DeliveryProgress(status: state.status),
                const SizedBox(height: 14),
                _CoordinateDiagnostics(state: state),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.state});

  final TrackingViewState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDelivered = state.status == TrackingStatus.delivered;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDelivered ? colors.primary : colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDelivered ? Icons.check_rounded : Icons.delivery_dining_rounded,
            color: isDelivered ? colors.onPrimary : colors.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusMessageFor(state.status),
                key: const ValueKey('delivery-status-message'),
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                state.status.label,
                key: const ValueKey('delivery-status-label'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HighlightMetric extends StatelessWidget {
  const _HighlightMetric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    key: ValueKey('metric-$label'),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiderIdentity extends StatelessWidget {
  const _RiderIdentity();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _RiderAvatar(),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              riderName,
              key: const ValueKey('rider-name'),
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              'Your rider',
              key: const ValueKey('rider-role'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const Spacer(),
        Icon(
          Icons.favorite_rounded,
          color: Theme.of(context).colorScheme.tertiary,
          size: 20,
        ),
      ],
    );
  }
}

class _RiderAvatar extends StatelessWidget {
  const _RiderAvatar();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: colors.tertiary.withValues(alpha: 0.35)),
      ),
      child: Icon(
        Icons.face_3_rounded,
        color: colors.onTertiaryContainer,
        size: 32,
      ),
    );
  }
}

class _DeliveryProgress extends StatelessWidget {
  const _DeliveryProgress({required this.status});

  final TrackingStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = deliveryProgressFor(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Delivery progress',
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              '${(progress * 100).round()}%',
              key: const ValueKey('delivery-progress-percent'),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            key: const ValueKey('delivery-progress'),
            value: progress,
            minHeight: 8,
            backgroundColor: colors.surfaceContainerHighest,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ProgressLabel(label: 'Preparing', active: progress > 0),
            _ProgressLabel(label: 'On the way', active: progress >= 0.45),
            _ProgressLabel(label: 'Delivered', active: progress >= 1),
          ],
        ),
      ],
    );
  }
}

class _ProgressLabel extends StatelessWidget {
  const _ProgressLabel({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: active ? colors.primary : colors.onSurfaceVariant,
        fontWeight: active ? FontWeight.w700 : FontWeight.normal,
      ),
    );
  }
}

class _CoordinateDiagnostics extends StatelessWidget {
  const _CoordinateDiagnostics({required this.state});

  final TrackingViewState state;

  @override
  Widget build(BuildContext context) {
    final location = state.riderLocation;
    return Row(
      children: [
        Expanded(
          child: _DiagnosticRow(
            label: 'Latitude',
            value: location == null
                ? '--'
                : location.latitude.toStringAsFixed(6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DiagnosticRow(
            label: 'Longitude',
            value: location == null
                ? '--'
                : location.longitude.toStringAsFixed(6),
          ),
        ),
      ],
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

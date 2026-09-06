import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/tracking_route.dart';
import '../../domain/models/tracking_status.dart';
import '../widgets/tracking_map.dart';
import '../view_models/tracking_view_model.dart';

class TrackingPage extends StatelessWidget {
  const TrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<TrackingViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Rider Tracking')),
      body: SafeArea(
        child: Center(
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
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Live simulator diagnostics',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  state.isLoading
                                      ? 'Waiting for the first simulated snapshot...'
                                      : state.isComplete
                                      ? 'Rider has reached the destination.'
                                      : 'Rider is moving along the predefined route.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                _DiagnosticRow(
                                  label: 'Latitude',
                                  value: state.riderLocation == null
                                      ? '--'
                                      : state.riderLocation!.latitude
                                            .toStringAsFixed(6),
                                ),
                                const SizedBox(height: 8),
                                _DiagnosticRow(
                                  label: 'Longitude',
                                  value: state.riderLocation == null
                                      ? '--'
                                      : state.riderLocation!.longitude
                                            .toStringAsFixed(6),
                                ),
                                const SizedBox(height: 8),
                                _DiagnosticRow(
                                  label: 'Status',
                                  value: state.status.label,
                                ),
                                const SizedBox(height: 8),
                                _DiagnosticRow(
                                  label: 'ETA',
                                  value: state.eta == null
                                      ? '--'
                                      : _formatDuration(state.eta!),
                                ),
                                const SizedBox(height: 8),
                                _DiagnosticRow(
                                  label: 'Remaining distance',
                                  value: state.remainingDistanceMeters == null
                                      ? '--'
                                      : '${state.remainingDistanceMeters!.toStringAsFixed(1)} m',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '${minutes}m ${seconds}s';
}

# Project Overview

## Purpose

Rider Tracking is a Flutter app for customers waiting for a delivery. It is being built toward a live view of a rider, the delivery route, the estimated arrival time, and the delivery status.

The current app uses a local rider simulation. This makes the user experience and data flow testable before a real backend exists.

## Architecture

The project uses a feature-first structure. Code for tracking stays under `lib/features/tracking/`. App-wide wiring belongs in `lib/app/`, while genuinely shared helpers belong in `lib/core/`.

The tracking flow is:

```mermaid
flowchart LR
  DS[Data source] --> R[TrackingRepository]
  R --> VM[TrackingViewModel]
  VM --> UI[TrackingPage]
```

Today, the data source is `LocalTrackingSimulator`. Later, a WebSocket data source can provide the same kind of tracking snapshots. The repository contract and ViewModel stream should remain stable, so the UI does not need to know which source is active.

## Development progress

1. Foundation: complete. The app shell, routing, theme, domain models, repository contract, Provider wiring, and initial ViewModel exist.
2. Local rider simulation: complete. A deterministic route emits snapshots, and the page displays live tracking values.
3. Map tracking: complete. The page renders the route, rider position, and destination on a map.
4. Real data source: later. Replace or select the local simulator through repository wiring and add a WebSocket-backed source.
5. Product hardening: later. Address real authentication, connection failures, persistence, platform location concerns, and production observability.

## Important boundary

The current page is still intentionally simple. It proves that updates reach a map and status overlay, but it is not yet the final customer tracking experience.

## Files to know

- `lib/app/app.dart` creates the repository and ViewModel and starts the app.
- `lib/app/router.dart` maps the tracking route to the tracking page.
- `lib/features/tracking/domain/repositories/tracking_repository.dart` defines the source-independent tracking stream.
- `lib/features/tracking/data/datasources/local_tracking_simulator.dart` creates local tracking snapshots.
- `lib/features/tracking/data/repositories/local_tracking_repository.dart` exposes the simulator through the domain contract.
- `lib/features/tracking/presentation/view_models/tracking_view_model.dart` turns stream events into immutable presentation state.
- `lib/features/tracking/presentation/pages/tracking_page.dart` renders the map and current tracking state.

## Remember

The key design choice is the stable stream boundary. A source publishes tracking snapshots, the repository exposes them, the ViewModel owns subscription state, and the page renders state. Future transport changes should stay below that boundary.

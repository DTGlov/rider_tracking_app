# Rider Tracking

Rider Tracking is a Flutter delivery-tracking demonstration app. It shows how a customer-facing tracking experience can be built around a realtime state stream, beginning with a deterministic local rider simulator before introducing a remote backend.

The current experience follows **Dobz**, a friendly rider, as she moves along a predefined route. The app renders the route on a map, smoothly moves the rider marker between updates, follows the rider when enabled, and presents delivery status, ETA, remaining distance, rider information, and progress.

The app uses local data by default today. A separately testable Flutter WebSocket data source can now consume the Phase 6A Go server, but it is not permanently wired as the default source yet. Device geolocation and real routing are not implemented.

## Current Progress

The following development phases are complete:

1. **Foundation**: app shell, routing, theme, domain models, repository contract, Provider wiring, and initial ViewModel.
2. **Local rider simulation**: deterministic route progression, distance, ETA, status transitions, timestamps, and stream completion.
3. **Map rendering**: route polyline, origin and destination markers, and the current rider marker.
4. **Live rider movement UX**: smooth marker interpolation, camera follow, manual follow cancellation, and recenter behavior.
5. **Tracking experience UI**: polished delivery status, Dobz rider identity, human-friendly metrics, and delivery progress.
6. **WebSocket contract and Go server**: a minimal deterministic Go server emits the documented tracking JSON contract over `/ws/tracking`.
7. **Flutter WebSocket data source**: strict JSON decoding and a WebSocket-backed repository now satisfy the existing tracking contract; local simulator wiring remains the default.
8. **Runtime source selection**: compile-time configuration can select either repository at the app composition root; local mode remains the default.

## Architecture

The app uses a feature-first Flutter structure. Tracking-specific code lives under `lib/features/tracking/`, while app composition and routing live under `lib/app/`.

```mermaid
flowchart LR
  L[LocalTrackingSimulator] --> LR[LocalTrackingRepository]
  W[WebSocketTrackingDataSource] --> WR[WebSocketTrackingRepository]
  LR --> R[TrackingRepository]
  WR --> R
  R --> V[TrackingViewModel]
  V --> P[TrackingPage]
  P --> M[TrackingMap]
  M --> U[Map and movement UI]
  P --> C[Delivery information card]
```

The `TrackingRepository` contract keeps the presentation layer independent from the source of tracking data. The ViewModel subscribes to that contract and exposes the latest immutable presentation state. The page renders that state, while the map owns visual marker interpolation and camera behavior.

The simulator can later be replaced or supplemented by a WebSocket-backed data source through repository wiring without rewriting the tracking screen.

## Tech Stack

- Flutter and Dart
- Material 3 theming
- `provider` for dependency injection and ViewModel access
- `ChangeNotifier` for presentation state
- `go_router` for declarative routing
- `flutter_map` for map rendering
- `latlong2` for map coordinate values
- `web_socket_channel` for the optional WebSocket tracking data source
- OpenStreetMap public tiles for the current demonstration map
- Flutter widget tests and deterministic simulator tests

## Learning Approach

The project is built in small, completed vertical phases. Each phase establishes one useful piece of the product, keeps data and presentation boundaries explicit, adds focused tests, and records the important decisions in a short learning note.

See [`docs/learning/`](docs/learning/) for the phase-by-phase notes, diagrams, architectural decisions, deferred work, and key lessons. [`docs/learning/00-project-overview.md`](docs/learning/00-project-overview.md) provides the overall project map.

## Project Goals

- Build a clear customer-facing delivery-tracking experience.
- Demonstrate a stable stream boundary between data sources and UI.
- Keep simulation, repository, ViewModel, page, and map responsibilities separated.
- Make realtime state flow easy to test with deterministic inputs.
- Prepare the presentation layer for a future remote tracking source.
- Use each phase to strengthen practical Flutter and software architecture skills.

## Running Locally

Install Flutter, then run:

```sh
flutter pub get
flutter run
```

Run the test suite with:

```sh
flutter test
```

The app opens at `/tracking`. The local simulator advances automatically and eventually reaches the `Delivered` state.

## Screenshots

Screenshots and demo media will be added here when the UI and visual direction are finalized.

## Current Status

The local tracking experience is functional and suitable for demonstrating the current product direction. The simulator, map, movement UX, delivery information panel, focused tests, Go WebSocket server, and optional Flutter WebSocket source are in place. The local simulator remains the default app source.

The next planned milestone is connection resilience. Production concerns such as authentication, reconnect/recovery, stale-message handling, persistence, device location, backend business logic, routing, notifications, and production tile configuration remain intentionally unimplemented.

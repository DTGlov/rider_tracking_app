# Project Rules

## Accepted Architecture

- The app uses a feature-first Flutter structure.
- Shared code belongs in `lib/core/` only when it is genuinely cross-feature.
- Feature code stays inside `lib/features/<feature_name>/`.
- For this project, `tracking` is the first vertical slice.

## Feature Boundaries

- Keep UI, data access, and business rules inside the owning feature.
- Do not create global `data/` or `domain/` folders.
- Do not move feature-specific models or repositories into `core/`.
- Only extract shared helpers to `core/` when more than one feature needs them.

## State Management

- Use `ChangeNotifier` for ViewModels.
- Use `provider` for dependency injection and widget access.
- Keep widgets lean.
- The ViewModel owns presentation state and subscribes to repository streams.
- Widgets render immutable ViewModel state and forward user actions.

## Repository And Data-Source Boundaries

- Domain repositories define the contracts consumed by ViewModels.
- Data sources implement the actual source of truth, such as a simulator or WebSocket client.
- Repositories adapt data-source output into feature domain models.
- The first implementation should keep simulator and WebSocket logic behind the same repository contract.

## Dependency Policy

- Add dependencies only when a feature phase truly requires them.
- Prefer the Flutter SDK and existing packages before introducing new ones.
- Do not add overlapping packages for the same job.
- Document why any new dependency is needed before it is added.
- After dependency changes, run `flutter pub get`, then analyze and test the touched code.

## Flutter MCP Validation Workflow

- Inspect relevant code before editing.
- Use Flutter/Dart MCP tools when they help validate types, runtime behavior, or analyzer output.
- For UI or runtime changes, verify with runtime tools when practical.
- Prefer focused tests over broad suites unless broader coverage is necessary.
- Review analyzer output and the final diff before finishing.

## Simulator To WebSocket Migration Strategy

- Keep the `TrackingRepository` contract stable.
- Implement the local simulator as one data-source option behind that contract.
- Later add a WebSocket-backed data source without changing the presentation layer.
- The ViewModel should continue consuming the same tracking stream regardless of source.
- Replace the simulator with the backend by swapping repository wiring, not by rewriting widgets.

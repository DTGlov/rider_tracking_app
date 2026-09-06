# Rider Tracking Backend

This is the first backend boundary for the Rider Tracking project. It is a small Go server that simulates one delivery route and sends tracking updates over a WebSocket connection.

Phase 6A proves the transport and message contract only. The Flutter app still uses its existing local simulator and is not connected to this server yet.

## Run

From the repository root:

```sh
cd backend
go run ./cmd/server
```

The server listens on `http://localhost:8080` by default. Set `TRACKING_SERVER_ADDR` to use another address, for example `:9090`.

The WebSocket endpoint is:

```text
ws://localhost:8080/ws/tracking
```

Each connection receives deterministic updates immediately, then one update per configured tick. The server emits a final `delivered` update and closes the connection cleanly.

## Message Contract

Every WebSocket message is a JSON object with these stable fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `tripId` | string | Identifier for the delivery trip |
| `sequence` | integer | Monotonically increasing update number |
| `timestamp` | string | RFC3339/ISO-8601 UTC timestamp |
| `latitude` | number | Rider latitude in decimal degrees |
| `longitude` | number | Rider longitude in decimal degrees |
| `remainingDistanceMeters` | number | Estimated distance to the destination |
| `etaSeconds` | integer | Estimated time to arrival in seconds |
| `status` | string | `riderAssigned`, `enRoute`, `arriving`, or `delivered` |

Example:

```json
{
  "tripId": "trip-demo-001",
  "sequence": 4,
  "timestamp": "2026-09-05T12:00:00.750Z",
  "latitude": 5.604318,
  "longitude": -0.185996,
  "remainingDistanceMeters": 512.4,
  "etaSeconds": 10,
  "status": "enRoute"
}
```

The `sequence` field will let a future Flutter client reject stale or out-of-order messages. The timestamp describes when the simulated update was produced, rather than when a client happened to receive it.

## Structure

- `cmd/server/main.go` owns process startup, configuration, and graceful shutdown.
- `internal/tracking/message.go` defines the JSON message model and wire statuses.
- `internal/tracking/simulator.go` contains deterministic route progression and update calculation.
- `internal/tracking/handler.go` upgrades `/ws/tracking` connections and writes simulator updates.
- `internal/tracking/simulator_test.go` tests simulation behavior without a live socket.

The simulator does not import Flutter code. It uses the same conceptual route and tracking fields, but the backend has its own Go types so the two projects remain independently understandable.

## Checks

```sh
go test ./...
go vet ./...
```

## Deliberately Deferred

This phase does not integrate the Flutter client, add a WebSocket repository implementation, persist trips, authenticate clients, connect to a Go business backend, use device geolocation, call routing services, or configure production deployment and observability.

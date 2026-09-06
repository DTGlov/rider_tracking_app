package tracking

import "time"

// Status is the stable wire representation of a delivery state.
type Status string

const (
	StatusRiderAssigned Status = "riderAssigned"
	StatusEnRoute       Status = "enRoute"
	StatusArriving      Status = "arriving"
	StatusDelivered     Status = "delivered"
)

// TrackingUpdate is one complete update sent to a connected client.
type TrackingUpdate struct {
	TripID                  string    `json:"tripId"`
	Sequence                int       `json:"sequence"`
	Timestamp               time.Time `json:"timestamp"`
	Latitude                float64   `json:"latitude"`
	Longitude               float64   `json:"longitude"`
	RemainingDistanceMeters float64   `json:"remainingDistanceMeters"`
	ETASeconds              int       `json:"etaSeconds"`
	Status                  Status    `json:"status"`
}

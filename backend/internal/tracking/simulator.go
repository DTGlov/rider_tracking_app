package tracking

import (
	"errors"
	"math"
	"time"
)

const defaultTripID = "trip-demo-001"

// Coordinate is a route point used internally by the backend simulator.
type Coordinate struct {
	Latitude  float64
	Longitude float64
}

// DefaultRoute follows the same conceptual Accra route as the Flutter demo.
var DefaultRoute = []Coordinate{
	{Latitude: 5.6037, Longitude: -0.1870},
	{Latitude: 5.6045, Longitude: -0.1857},
	{Latitude: 5.6056, Longitude: -0.1844},
	{Latitude: 5.6064, Longitude: -0.1831},
	{Latitude: 5.6072, Longitude: -0.1819},
}

// Config controls deterministic simulation behavior.
type Config struct {
	TripID               string
	Route                []Coordinate
	TickInterval         time.Duration
	SpeedMetersPerSecond float64
	StartTime            time.Time
}

func defaultConfig() Config {
	return Config{
		TripID:               defaultTripID,
		Route:                DefaultRoute,
		TickInterval:         250 * time.Millisecond,
		SpeedMetersPerSecond: 50,
		StartTime:            time.Date(2026, 9, 5, 12, 0, 0, 0, time.UTC),
	}
}

// DefaultConfig returns the server's deterministic demonstration settings.
func DefaultConfig() Config {
	return defaultConfig()
}

func (c Config) withDefaults() Config {
	defaults := defaultConfig()
	if c.TripID == "" {
		c.TripID = defaults.TripID
	}
	if len(c.Route) == 0 {
		c.Route = defaults.Route
	}
	if c.TickInterval <= 0 {
		c.TickInterval = defaults.TickInterval
	}
	if c.SpeedMetersPerSecond <= 0 {
		c.SpeedMetersPerSecond = defaults.SpeedMetersPerSecond
	}
	if c.StartTime.IsZero() {
		c.StartTime = defaults.StartTime
	}
	return c
}

// Simulator advances one deterministic tracking update at a time.
type Simulator struct {
	config            Config
	segmentDistances  []float64
	segmentOffsets    []float64
	totalDistance     float64
	distanceTravelled float64
	sequence          int
	finished          bool
}

// NewSimulator creates a simulator without starting a clock or goroutine.
func NewSimulator(config Config) (*Simulator, error) {
	config = config.withDefaults()
	if len(config.Route) < 2 {
		return nil, errors.New("route needs at least two points")
	}

	segmentDistances := make([]float64, 0, len(config.Route)-1)
	segmentOffsets := []float64{0}
	totalDistance := 0.0
	for index := 0; index < len(config.Route)-1; index++ {
		segmentDistance := distanceBetween(config.Route[index], config.Route[index+1])
		segmentDistances = append(segmentDistances, segmentDistance)
		totalDistance += segmentDistance
		segmentOffsets = append(segmentOffsets, totalDistance)
	}

	return &Simulator{
		config:           config,
		segmentDistances: segmentDistances,
		segmentOffsets:   segmentOffsets,
		totalDistance:    totalDistance,
	}, nil
}

// TickInterval returns the delay intended between emitted updates.
func (s *Simulator) TickInterval() time.Duration {
	return s.config.TickInterval
}

// Next emits the next update and reports whether it is the final update.
func (s *Simulator) Next() (TrackingUpdate, bool) {
	if s.finished {
		return TrackingUpdate{}, true
	}

	location := s.positionAt(s.distanceTravelled)
	remainingDistance := math.Max(0, s.totalDistance-s.distanceTravelled)
	status := statusFor(s.distanceTravelled, remainingDistance, s.totalDistance)
	s.sequence++
	update := TrackingUpdate{
		TripID:                  s.config.TripID,
		Sequence:                s.sequence,
		Timestamp:               s.config.StartTime.Add(time.Duration(s.sequence-1) * s.config.TickInterval),
		Latitude:                location.Latitude,
		Longitude:               location.Longitude,
		RemainingDistanceMeters: remainingDistance,
		ETASeconds:              etaSeconds(remainingDistance, s.config.SpeedMetersPerSecond),
		Status:                  status,
	}

	if remainingDistance <= 0 {
		s.finished = true
		return update, true
	}

	s.distanceTravelled = math.Min(
		s.totalDistance,
		s.distanceTravelled+s.config.SpeedMetersPerSecond*s.config.TickInterval.Seconds(),
	)
	return update, false
}

func statusFor(distanceTravelled, remainingDistance, totalDistance float64) Status {
	switch {
	case remainingDistance <= 0:
		return StatusDelivered
	case remainingDistance < totalDistance*0.2:
		return StatusArriving
	case distanceTravelled <= 0:
		return StatusRiderAssigned
	default:
		return StatusEnRoute
	}
}

func etaSeconds(remainingDistance, speedMetersPerSecond float64) int {
	if remainingDistance <= 0 {
		return 0
	}
	return int(math.Round(remainingDistance / speedMetersPerSecond))
}

func (s *Simulator) positionAt(distanceMeters float64) Coordinate {
	if distanceMeters <= 0 {
		return s.config.Route[0]
	}
	if distanceMeters >= s.totalDistance {
		return s.config.Route[len(s.config.Route)-1]
	}

	for index, segmentDistance := range s.segmentDistances {
		segmentStart := s.segmentOffsets[index]
		segmentEnd := s.segmentOffsets[index+1]
		if distanceMeters <= segmentEnd {
			progress := (distanceMeters - segmentStart) / segmentDistance
			return interpolate(s.config.Route[index], s.config.Route[index+1], progress)
		}
	}
	return s.config.Route[len(s.config.Route)-1]
}

func interpolate(start, end Coordinate, progress float64) Coordinate {
	progress = math.Max(0, math.Min(1, progress))
	return Coordinate{
		Latitude:  start.Latitude + (end.Latitude-start.Latitude)*progress,
		Longitude: start.Longitude + (end.Longitude-start.Longitude)*progress,
	}
}

func distanceBetween(a, b Coordinate) float64 {
	const earthRadiusMeters = 6371000.0
	lat1 := radians(a.Latitude)
	lat2 := radians(b.Latitude)
	deltaLat := radians(b.Latitude - a.Latitude)
	deltaLon := radians(b.Longitude - a.Longitude)
	haversine := math.Sin(deltaLat/2)*math.Sin(deltaLat/2) +
		math.Cos(lat1)*math.Cos(lat2)*math.Sin(deltaLon/2)*math.Sin(deltaLon/2)
	angularDistance := 2 * math.Atan2(math.Sqrt(haversine), math.Sqrt(1-haversine))
	return earthRadiusMeters * angularDistance
}

func radians(degrees float64) float64 {
	return degrees * math.Pi / 180
}

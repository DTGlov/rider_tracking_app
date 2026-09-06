package tracking

import (
	"testing"
	"time"
)

func TestSimulatorProducesOrderedProgressiveUpdates(t *testing.T) {
	simulator, err := NewSimulator(Config{
		TickInterval:         time.Second,
		SpeedMetersPerSecond: 150,
		StartTime:            time.Date(2026, 9, 5, 12, 0, 0, 0, time.UTC),
	})
	if err != nil {
		t.Fatalf("NewSimulator() error = %v", err)
	}

	first, firstDone := simulator.Next()
	second, secondDone := simulator.Next()
	if firstDone || secondDone {
		t.Fatal("expected the first two updates to be non-final")
	}
	if second.Sequence <= first.Sequence {
		t.Fatalf("sequence did not increase: %d then %d", first.Sequence, second.Sequence)
	}
	if second.Latitude == first.Latitude && second.Longitude == first.Longitude {
		t.Fatal("position did not progress")
	}
	if second.RemainingDistanceMeters >= first.RemainingDistanceMeters {
		t.Fatal("remaining distance did not decrease")
	}
	if second.ETASeconds >= first.ETASeconds {
		t.Fatal("ETA did not decrease")
	}
	if !second.Timestamp.After(first.Timestamp) {
		t.Fatal("timestamp did not increase")
	}
}

func TestSimulatorEventuallyDelivers(t *testing.T) {
	simulator, err := NewSimulator(Config{
		TickInterval:         time.Second,
		SpeedMetersPerSecond: 150,
	})
	if err != nil {
		t.Fatalf("NewSimulator() error = %v", err)
	}

	var last TrackingUpdate
	var done bool
	for updates := 0; updates < 100; updates++ {
		last, done = simulator.Next()
		if done {
			break
		}
	}

	if !done {
		t.Fatal("simulator did not finish")
	}
	if last.Status != StatusDelivered {
		t.Fatalf("final status = %q, want %q", last.Status, StatusDelivered)
	}
	if last.RemainingDistanceMeters != 0 {
		t.Fatalf("final remaining distance = %f, want 0", last.RemainingDistanceMeters)
	}
	if last.ETASeconds != 0 {
		t.Fatalf("final ETA = %d, want 0", last.ETASeconds)
	}
}

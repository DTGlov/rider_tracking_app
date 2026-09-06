package tracking

import (
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gorilla/websocket"
)

func TestHandlerEmitsTrackingUpdates(t *testing.T) {
	server := httptest.NewServer(NewHandler(Config{
		TickInterval:         time.Millisecond,
		SpeedMetersPerSecond: 10000,
	}))
	defer server.Close()

	webSocketURL := "ws" + strings.TrimPrefix(server.URL, "http") + "/ws/tracking"
	connection, _, err := websocket.DefaultDialer.Dial(webSocketURL, nil)
	if err != nil {
		t.Fatalf("Dial() error = %v", err)
	}
	defer connection.Close()

	var first TrackingUpdate
	if err := connection.ReadJSON(&first); err != nil {
		t.Fatalf("ReadJSON(first) error = %v", err)
	}
	var second TrackingUpdate
	if err := connection.ReadJSON(&second); err != nil {
		t.Fatalf("ReadJSON(second) error = %v", err)
	}

	if first.Sequence != 1 || second.Sequence != 2 {
		t.Fatalf("sequences = %d, %d; want 1, 2", first.Sequence, second.Sequence)
	}
	if first.TripID == "" || first.Status == "" {
		t.Fatal("first update is missing contract fields")
	}
}

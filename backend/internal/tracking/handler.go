package tracking

import (
	"net/http"
	"time"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{}

// NewHandler returns the HTTP handler for the tracking WebSocket endpoint.
func NewHandler(config Config) http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("/ws/tracking", func(writer http.ResponseWriter, request *http.Request) {
		serveTracking(writer, request, config)
	})
	return mux
}

func serveTracking(writer http.ResponseWriter, request *http.Request, config Config) {
	connection, err := upgrader.Upgrade(writer, request, nil)
	if err != nil {
		return
	}
	defer connection.Close()

	simulator, err := NewSimulator(config)
	if err != nil {
		return
	}

	for {
		update, done := simulator.Next()
		if err := connection.WriteJSON(update); err != nil {
			return
		}
		if done {
			return
		}
		timer := time.NewTimer(simulator.TickInterval())
		<-timer.C
	}
}

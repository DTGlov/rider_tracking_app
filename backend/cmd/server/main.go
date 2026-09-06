package main

import (
	"context"
	"errors"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"rider_tracking_app/backend/internal/tracking"
)

func main() {
	address := ":8080"
	if configuredAddress := os.Getenv("TRACKING_SERVER_ADDR"); configuredAddress != "" {
		address = configuredAddress
	}

	server := &http.Server{
		Addr:              address,
		Handler:           tracking.NewHandler(tracking.DefaultConfig()),
		ReadHeaderTimeout: 5 * time.Second,
	}

	shutdownContext, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	go func() {
		<-shutdownContext.Done()
		shutdownContext, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		if err := server.Shutdown(shutdownContext); err != nil {
			log.Printf("server shutdown: %v", err)
		}
	}()

	log.Printf("tracking server listening on http://localhost%s", address)
	if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		log.Fatal(err)
	}
}

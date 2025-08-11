package main

import (
	"encoding/json"
	"net/http"
	"os"
)

func handler(w http.ResponseWriter, r *http.Request) {
	// Set content type to application/json
	w.Header().Set("Content-Type", "application/json")

	// Read ALLOC_ID from environment
	allocID := os.Getenv("ALLOC_ID")

	// Create a response map with status and alloc_id
	response := map[string]string{
		"status":   "ok",
		"alloc_id": allocID,
	}

	// Encode the response to JSON and write it
	json.NewEncoder(w).Encode(response)
}

func main() {
	// Handle requests to the root URL
	http.HandleFunc("/", handler)

	// Start the server on port 8080
	http.ListenAndServe(":8080", nil)
}

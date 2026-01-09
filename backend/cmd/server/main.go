package main

import (
	"backend/internal/handlers"
	"backend/internal/service"
	"backend/internal/store"
	"log"
	"net/http"
	"os"
)

func main() {
	// Configuration
	apiKey := os.Getenv("STEAM_API_KEY")
	if apiKey == "" {
		// Fallback for development if needed, or error out
		log.Println("Warning: STEAM_API_KEY environment variable not set.")
	}
	
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	dbPath := "steam_data.db"

	// Init Store
	s, err := store.NewSQLiteStore(dbPath)
	if err != nil {
		log.Fatalf("Failed to initialize store: %v", err)
	}
	defer s.Close()

	// Init Services
	steamClient := service.NewSteamClient(apiKey)
	dataService := service.NewDataService(s, steamClient)

	// Init Handlers
	steamHandler := handlers.NewSteamHandler(steamClient)
	dataHandler := handlers.NewDataHandler(dataService)
	authHandler := handlers.NewAuthHandler(dataService)

	// Routing
	mux := http.NewServeMux()

	// Steam Endpoints
	mux.HandleFunc("/api/steam/user/", steamHandler.GetUserSummary)
	mux.HandleFunc("/api/steam/games/", steamHandler.GetOwnedGames)
	mux.HandleFunc("/api/steam/achievements/", steamHandler.GetPlayerAchievements)
	mux.HandleFunc("/api/steam/friends/", steamHandler.GetFriendList)
	mux.HandleFunc("/api/steam/recently-played/", steamHandler.GetRecentlyPlayedGames)
	mux.HandleFunc("/api/steam/level/", steamHandler.GetSteamLevel)
	mux.HandleFunc("/api/steam/bans/", steamHandler.GetPlayerBans)
	mux.HandleFunc("/api/steam/badges/", steamHandler.GetBadges)

	// Auth Endpoints
	mux.HandleFunc("/api/auth/login", authHandler.HandleLogin)

	// Data Endpoints
	// Data Endpoints with User Context
	mux.HandleFunc("/api/data/", func(w http.ResponseWriter, r *http.Request) {
		// Pattern expected: /api/data/{steamId}/games or /api/data/{steamId}/games/{appId}
		// We can detect if it's a list or item based on trailing segments or simply by attempting item handler details.
		
		// Simplest dispatch: Check suffix or path parts
		path := r.URL.Path
		// Check if it ends in "/games" or "/games/"
		if len(path) > 6 && (path[len(path)-6:] == "/games" || path[len(path)-7:] == "/games/") {
             dataHandler.GetAllGameData(w, r)
             return
		}
		
		dataHandler.HandleGameData(w, r)
	})

	log.Printf("Server starting on port %s...", port)
	if err := http.ListenAndServe(":"+port, mux); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}

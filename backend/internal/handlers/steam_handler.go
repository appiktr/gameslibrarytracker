package handlers

import (
	"backend/internal/service"
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
)

type SteamHandler struct {
	client *service.SteamClient
}

func NewSteamHandler(client *service.SteamClient) *SteamHandler {
	return &SteamHandler{client: client}
}

// ExtractPathVar is a helper since we might not have gorilla/mux working yet.
// Assumes path pattern like /api/steam/user/{id}
func extractID(path string, prefix string) string {
	return strings.TrimPrefix(path, prefix)
}

func (h *SteamHandler) GetUserSummary(w http.ResponseWriter, r *http.Request) {
	// Pattern: /api/steam/user/
	id := extractID(r.URL.Path, "/api/steam/user/")
	if id == "" {
		http.Error(w, "Missing Steam ID", http.StatusBadRequest)
		return
	}

	user, err := h.client.GetUserSummary(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if user == nil {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

func (h *SteamHandler) GetOwnedGames(w http.ResponseWriter, r *http.Request) {
	// Pattern: /api/steam/games/
	id := extractID(r.URL.Path, "/api/steam/games/")
	if id == "" {
		http.Error(w, "Missing Steam ID", http.StatusBadRequest)
		return
	}

	games, err := h.client.GetOwnedGames(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(games)
}

func (h *SteamHandler) GetPlayerAchievements(w http.ResponseWriter, r *http.Request) {
	// Pattern: /api/steam/achievements/{steamId}/{appId}
	parts := strings.Split(strings.TrimPrefix(r.URL.Path, "/api/steam/achievements/"), "/")
	if len(parts) < 2 {
		http.Error(w, "Invalid path parameters", http.StatusBadRequest)
		return
	}
	steamID := parts[0]
	appID, err := strconv.Atoi(parts[1])
	if err != nil {
		http.Error(w, "Invalid App ID", http.StatusBadRequest)
		return
	}

	achievements, err := h.client.GetPlayerAchievements(steamID, appID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(achievements)
}

func (h *SteamHandler) GetFriendList(w http.ResponseWriter, r *http.Request) {
	id := extractID(r.URL.Path, "/api/steam/friends/")
	if id == "" {
		http.Error(w, "Missing Steam ID", http.StatusBadRequest)
		return
	}

	friends, err := h.client.GetFriendList(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(friends)
}

func (h *SteamHandler) GetRecentlyPlayedGames(w http.ResponseWriter, r *http.Request) {
	id := extractID(r.URL.Path, "/api/steam/recently-played/")
	if id == "" {
		http.Error(w, "Missing Steam ID", http.StatusBadRequest)
		return
	}

	games, err := h.client.GetRecentlyPlayedGames(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(games)
}

func (h *SteamHandler) GetSteamLevel(w http.ResponseWriter, r *http.Request) {
	id := extractID(r.URL.Path, "/api/steam/level/")
	if id == "" {
		http.Error(w, "Missing Steam ID", http.StatusBadRequest)
		return
	}

	level, err := h.client.GetSteamLevel(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(level)
}

func (h *SteamHandler) GetPlayerBans(w http.ResponseWriter, r *http.Request) {
	id := extractID(r.URL.Path, "/api/steam/bans/")
	if id == "" {
		http.Error(w, "Missing Steam ID", http.StatusBadRequest)
		return
	}

	bans, err := h.client.GetPlayerBans(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(bans)
}

func (h *SteamHandler) GetBadges(w http.ResponseWriter, r *http.Request) {
	id := extractID(r.URL.Path, "/api/steam/badges/")
	if id == "" {
		http.Error(w, "Missing Steam ID", http.StatusBadRequest)
		return
	}

	badges, err := h.client.GetBadges(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(badges)
}

package handlers

import (
	"backend/internal/service"
	"encoding/json"
	"net/http"
)

type AuthHandler struct {
	service *service.DataService
}

func NewAuthHandler(service *service.DataService) *AuthHandler {
	return &AuthHandler{service: service}
}

type LoginRequest struct {
	SteamID string `json:"steamId"`
}

func (h *AuthHandler) HandleLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid Body", http.StatusBadRequest)
		return
	}

	if req.SteamID == "" {
		http.Error(w, "Missing Steam ID", http.StatusBadRequest)
		return
	}

	user, err := h.service.RegisterOrUpdateUser(req.SteamID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if user == nil {
		http.Error(w, "User not found on Steam", http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

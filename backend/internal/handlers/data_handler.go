package handlers

import (
	"backend/internal/models"
	"backend/internal/service"
	"encoding/json"
	"net/http"
	"strconv"
	"strings"
)

type DataHandler struct {
	service *service.DataService
}

func NewDataHandler(service *service.DataService) *DataHandler {
	return &DataHandler{service: service}
}

func (h *DataHandler) HandleGameData(w http.ResponseWriter, r *http.Request) {
	// Pattern: /api/data/{steamId}/games/{appId}
	path := strings.TrimPrefix(r.URL.Path, "/api/data/")
	parts := strings.Split(path, "/")
	
	if len(parts) < 3 || parts[1] != "games" {
		http.Error(w, "Invalid path", http.StatusBadRequest)
		return
	}
	
	steamID := parts[0]
	appIDStr := parts[2]
	
	appID, err := strconv.Atoi(appIDStr)
	if err != nil {
		http.Error(w, "Invalid App ID", http.StatusBadRequest)
		return
	}

	switch r.Method {
	case http.MethodGet:
		data, err := h.service.GetGameData(steamID, appID)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		if data == nil {
			w.Header().Set("Content-Type", "application/json")
			json.NewEncoder(w).Encode(nil)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(data)

	case http.MethodPost:
		var data models.LocalGameData
		if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
			http.Error(w, "Invalid Body", http.StatusBadRequest)
			return
		}
		data.AppID = appID // Ensure ID matches URL
		
		if err := h.service.SaveGameData(steamID, &data); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		w.WriteHeader(http.StatusOK)
		
	default:
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
	}
}

func (h *DataHandler) GetAllGameData(w http.ResponseWriter, r *http.Request) {
	// Pattern: /api/data/{steamId}/games
	path := strings.TrimPrefix(r.URL.Path, "/api/data/")
	parts := strings.Split(path, "/")
	
	if len(parts) < 2 || parts[1] != "games" {
		http.Error(w, "Invalid path", http.StatusBadRequest)
		return
	}
	steamID := parts[0]
	
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	data, err := h.service.GetAllGameData(steamID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(data)
}

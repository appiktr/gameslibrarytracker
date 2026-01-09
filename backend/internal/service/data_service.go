package service

import (
	"backend/internal/models"
	"backend/internal/store"
)

type DataService struct {
	store       store.Store
	steamClient *SteamClient
}

func NewDataService(store store.Store, steamClient *SteamClient) *DataService {
	return &DataService{
		store:       store,
		steamClient: steamClient,
	}
}

func (s *DataService) SaveGameData(steamID string, data *models.LocalGameData) error {
	return s.store.SaveGameData(steamID, data)
}

func (s *DataService) GetGameData(steamID string, appID int) (*models.LocalGameData, error) {
	return s.store.GetGameData(steamID, appID)
}

func (s *DataService) GetAllGameData(steamID string) (map[int]*models.LocalGameData, error) {
	return s.store.GetAllGameData(steamID)
}

// RegisterOrUpdateUser fetches user info from Steam and saves/updates it in local store.
func (s *DataService) RegisterOrUpdateUser(steamID string) (*models.SteamUser, error) {
	// 1. Fetch from Steam
	user, err := s.steamClient.GetUserSummary(steamID)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, nil // Not found
	}

	// 2. Save to DB
	if err := s.store.SaveUser(user); err != nil {
		return nil, err
	}

	return user, nil
}

// GetUser returns the user from local store.
func (s *DataService) GetUser(steamID string) (*models.SteamUser, error) {
	return s.store.GetUser(steamID)
}

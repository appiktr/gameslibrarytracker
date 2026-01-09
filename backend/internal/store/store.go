package store

import "backend/internal/models"

type Store interface {
	SaveGameData(steamID string, data *models.LocalGameData) error
	GetGameData(steamID string, appID int) (*models.LocalGameData, error)
	GetAllGameData(steamID string) (map[int]*models.LocalGameData, error)
	SaveUser(user *models.SteamUser) error
	GetUser(steamID string) (*models.SteamUser, error)
	Close() error
}

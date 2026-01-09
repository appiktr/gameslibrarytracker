package store

import (
	"backend/internal/models"
	"database/sql"
	"encoding/json"

	_ "github.com/mattn/go-sqlite3"
)

type SQLiteStore struct {
	db *sql.DB
}

func NewSQLiteStore(dbPath string) (*SQLiteStore, error) {
	db, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		return nil, err
	}

	if err := db.Ping(); err != nil {
		return nil, err
	}

	if err := createTable(db); err != nil {
		return nil, err
	}

	return &SQLiteStore{db: db}, nil
}

func createTable(db *sql.DB) error {
	// Migration: Drop old table if it has single PK (simple check: just drop and recreate for dev)
	// In prod, checking schema is better. For now, we force update.
	// We can try to rename or migrate, but simplest is new schema.
	// queryDrop := `DROP TABLE IF EXISTS local_game_data` 
	// db.Exec(queryDrop) <-- Use with caution. 
    // Let's create a new table 'user_game_data' to be safe and clean.
    
    query := `
	CREATE TABLE IF NOT EXISTS user_game_data (
		steam_id TEXT,
		app_id INTEGER,
		data TEXT,
		PRIMARY KEY (steam_id, app_id)
	);
	`
	if _, err := db.Exec(query); err != nil {
		return err
	}

	queryUsers := `
	CREATE TABLE IF NOT EXISTS users (
		steam_id TEXT PRIMARY KEY,
		data TEXT
	);
	`
	_, err := db.Exec(queryUsers)
	return err
}

func (s *SQLiteStore) SaveGameData(steamID string, data *models.LocalGameData) error {
	jsonData, err := json.Marshal(data)
	if err != nil {
		return err
	}

	query := `
	INSERT INTO user_game_data (steam_id, app_id, data)
	VALUES (?, ?, ?)
	ON CONFLICT(steam_id, app_id) DO UPDATE SET data = excluded.data;
	`
	_, err = s.db.Exec(query, steamID, data.AppID, string(jsonData))
	return err
}

func (s *SQLiteStore) GetGameData(steamID string, appID int) (*models.LocalGameData, error) {
	query := `SELECT data FROM user_game_data WHERE steam_id = ? AND app_id = ?`
	row := s.db.QueryRow(query, steamID, appID)

	var dataStr string
	if err := row.Scan(&dataStr); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil // Not found
		}
		return nil, err
	}

	var data models.LocalGameData
	if err := json.Unmarshal([]byte(dataStr), &data); err != nil {
		return nil, err
	}
	return &data, nil
}

func (s *SQLiteStore) GetAllGameData(steamID string) (map[int]*models.LocalGameData, error) {
	query := `SELECT app_id, data FROM user_game_data WHERE steam_id = ?`
	rows, err := s.db.Query(query, steamID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	results := make(map[int]*models.LocalGameData)
	for rows.Next() {
		var appID int
		var dataStr string
		if err := rows.Scan(&appID, &dataStr); err != nil {
			return nil, err
		}

		var data models.LocalGameData
		if err := json.Unmarshal([]byte(dataStr), &data); err != nil {
			continue
		}
		results[appID] = &data
	}

	return results, nil
}

func (s *SQLiteStore) SaveUser(user *models.SteamUser) error {
	jsonData, err := json.Marshal(user)
	if err != nil {
		return err
	}

	query := `
	INSERT INTO users (steam_id, data)
	VALUES (?, ?)
	ON CONFLICT(steam_id) DO UPDATE SET data = excluded.data;
	`
	_, err = s.db.Exec(query, user.SteamID, string(jsonData))
	return err
}

func (s *SQLiteStore) GetUser(steamID string) (*models.SteamUser, error) {
	query := `SELECT data FROM users WHERE steam_id = ?`
	row := s.db.QueryRow(query, steamID)

	var dataStr string
	if err := row.Scan(&dataStr); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}

	var user models.SteamUser
	if err := json.Unmarshal([]byte(dataStr), &user); err != nil {
		return nil, err
	}
	return &user, nil
}

func (s *SQLiteStore) Close() error {
	return s.db.Close()
}

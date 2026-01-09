package service

import (
	"backend/internal/models"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"time"
)

type SteamClient struct {
	apiKey     string
	httpClient *http.Client
	baseURL    string
}

func NewSteamClient(apiKey string) *SteamClient {
	return &SteamClient{
		apiKey:  apiKey,
		baseURL: "https://api.steampowered.com",
		httpClient: &http.Client{
			Timeout: 10 * time.Second,
		},
	}
}

func (s *SteamClient) get(path string, query url.Values, target interface{}) error {
	query.Set("key", s.apiKey)
	u := fmt.Sprintf("%s%s?%s", s.baseURL, path, query.Encode())

	resp, err := s.httpClient.Get(u)
	if err != nil {
		fmt.Printf("HTTP Request failed: %v\n", err)
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		fmt.Printf("Steam API returned %d for %s\n", resp.StatusCode, u)
		return fmt.Errorf("steam api error: status %d", resp.StatusCode)
	}

	return json.NewDecoder(resp.Body).Decode(target)
}

func (s *SteamClient) GetUserSummary(steamID string) (*models.SteamUser, error) {
	q := url.Values{}
	q.Set("steamids", steamID)

	var resp models.PlayerSummariesResponse
	err := s.get("/ISteamUser/GetPlayerSummaries/v0002/", q, &resp)
	if err != nil {
		return nil, err
	}

	if len(resp.Response.Players) > 0 {
		return &resp.Response.Players[0], nil
	}
	return nil, nil // Not found
}

func (s *SteamClient) GetOwnedGames(steamID string) ([]models.SteamGame, error) {
	q := url.Values{}
	q.Set("steamid", steamID)
	q.Set("format", "json")
	q.Set("include_appinfo", "true")
	q.Set("include_played_free_games", "true")

	var resp models.OwnedGamesResponse
	err := s.get("/IPlayerService/GetOwnedGames/v0001/", q, &resp)
	if err != nil {
		return nil, err
	}

	return resp.Response.Games, nil
}

func (s *SteamClient) GetPlayerAchievements(steamID string, appID int) ([]models.SteamAchievement, error) {
	// 1. Get Player Status
	qStat := url.Values{}
	qStat.Set("steamid", steamID)
	qStat.Set("appid", fmt.Sprintf("%d", appID))

	var statResp models.PlayerAchievementsResponse
	err := s.get("/ISteamUserStats/GetPlayerAchievements/v0001/", qStat, &statResp)
	if err != nil {
		fmt.Printf("Error fetching player achievements structure: %v\n", err)
		return nil, err // Often fails if profile is private or game has no stats
	}

	// 2. Get Schema (Optional, simplified for now)
	qSchema := url.Values{}
	qSchema.Set("appid", fmt.Sprintf("%d", appID))

	var schemaResp models.GameSchemaResponse
	schemaMap := make(map[string]struct {
		Name        string
		Description string
	})
	
	// We consume schema error softly
	if err := s.get("/ISteamUserStats/GetSchemaForGame/v2/", qSchema, &schemaResp); err == nil {
		for _, a := range schemaResp.Game.AvailableGameStats.Achievements {
			schemaMap[a.Name] = struct {
				Name        string
				Description string
			}{Name: a.DisplayName, Description: a.Description}
		}
	}

	var result []models.SteamAchievement
	for _, a := range statResp.PlayerStats.Achievements {
		schema := schemaMap[a.APIName]
		name := schema.Name
		if name == "" {
			name = a.APIName
		}
		
		result = append(result, models.SteamAchievement{
			APIName:     a.APIName,
			Achieved:    a.Achieved == 1,
			UnlockTime:  a.UnlockTime,
			Name:        name,
			Description: schema.Description,
		})
	}

	return result, nil
}

func (s *SteamClient) GetFriendList(steamID string) ([]models.SteamUser, error) {
	// 1. Get Friend IDs
	q := url.Values{}
	q.Set("steamid", steamID)
	q.Set("relationship", "friend")

	var friendsResp models.FriendListResponse
	if err := s.get("/ISteamUser/GetFriendList/v0001/", q, &friendsResp); err != nil {
		return nil, err
	}

	if len(friendsResp.FriendsList.Friends) == 0 {
		return []models.SteamUser{}, nil
	}

	// 2. Get Summaries for Friend IDs
	// Limit to first 100 for now to match Dart logic and API limits
	var friendIDs []string
	count := 0
	for _, f := range friendsResp.FriendsList.Friends {
		friendIDs = append(friendIDs, f.SteamID)
		count++
		if count >= 100 {
			break
		}
	}

	// Reuse GetUserSummary logic but for bulk?
	// The current GetUserSummary takes one ID. We need a bulk fetcher or reuse the underlying call.
	// Let's call the API directly here for bulk.
	qSum := url.Values{}
	qSum.Set("steamids", JoinSteamIDs(friendIDs)) // Helper function or strings.Join

	var playersResp models.PlayerSummariesResponse
	if err := s.get("/ISteamUser/GetPlayerSummaries/v0002/", qSum, &playersResp); err != nil {
		return nil, err
	}

	return playersResp.Response.Players, nil
}

func (s *SteamClient) GetRecentlyPlayedGames(steamID string) ([]models.SteamGame, error) {
	q := url.Values{}
	q.Set("steamid", steamID)
	q.Set("count", "10")

	var resp models.RecentlyPlayedGamesResponse
	if err := s.get("/IPlayerService/GetRecentlyPlayedGames/v0001/", q, &resp); err != nil {
		return nil, err
	}

	return resp.Response.Games, nil
}

func (s *SteamClient) GetSteamLevel(steamID string) (int, error) {
	q := url.Values{}
	q.Set("steamid", steamID)

	var resp struct {
		Response struct {
			PlayerLevel int `json:"player_level"`
		} `json:"response"`
	}
	if err := s.get("/IPlayerService/GetSteamLevel/v1/", q, &resp); err != nil {
		return 0, err
	}
	return resp.Response.PlayerLevel, nil
}

func (s *SteamClient) GetPlayerBans(steamID string) (map[string]interface{}, error) {
	q := url.Values{}
	q.Set("steamids", steamID)

	var resp struct {
		Players []map[string]interface{} `json:"players"`
	}
	if err := s.get("/ISteamUser/GetPlayerBans/v1/", q, &resp); err != nil {
		return nil, err
	}

	if len(resp.Players) > 0 {
		return resp.Players[0], nil
	}
	return map[string]interface{}{}, nil
}

func (s *SteamClient) GetBadges(steamID string) (map[string]interface{}, error) {
	q := url.Values{}
	q.Set("steamid", steamID)

	var resp struct {
		Response map[string]interface{} `json:"response"`
	}
	// Note: GetBadges/v1 might return 400/403 if profile private, Handle gracefully?
	if err := s.get("/IPlayerService/GetBadges/v1/", q, &resp); err != nil {
		return nil, err
	}
	return resp.Response, nil
}

func JoinSteamIDs(ids []string) string {
	// Simple join with comma
	if len(ids) == 0 {
		return ""
	}
	res := ids[0]
	for _, id := range ids[1:] {
		res += "," + id
	}
	return res
}

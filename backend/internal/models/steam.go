package models

// SteamUser represents a user's Steam profile summary.
type SteamUser struct {
	SteamID      string `json:"steamid"`
	PersonName   string `json:"personaname"`
	ProfileURL   string `json:"profileurl"`
	Avatar       string `json:"avatar"`
	AvatarMedium string `json:"avatarmedium"`
	AvatarFull   string `json:"avatarfull"`
	LastLogoff   int    `json:"lastlogoff"`
	PersonState  int    `json:"personastate"`
}

// SteamGame represents a game owned by a user.
type SteamGame struct {
	AppID           int    `json:"appid"`
	Name            string `json:"name"`
	PlaytimeForever int    `json:"playtime_forever"`
	ImgIconURL      string `json:"img_icon_url"`
}

// SteamAchievement represents an achievement for a game.
type SteamAchievement struct {
	APIName     string `json:"apiname"`
	Achieved    bool   `json:"achieved"` // Mapped from int 0/1 in logic, but API returns int usually, we'll handle at service level or struct scan
	UnlockTime  int    `json:"unlocktime"`
	Name        string `json:"name"`        // From Schema
	Description string `json:"description"` // From Schema
}

// API Response Wrappers

type PlayerSummariesResponse struct {
	Response struct {
		Players []SteamUser `json:"players"`
	} `json:"response"`
}

type OwnedGamesResponse struct {
	Response struct {
		GameCount int         `json:"game_count"`
		Games     []SteamGame `json:"games"`
	} `json:"response"`
}

type PlayerAchievementsResponse struct {
	PlayerStats struct {
		SteamID      string `json:"steamID"`
		GameName     string `json:"gameName"`
		Achievements []struct {
			APIName    string `json:"apiname"`
			Achieved   int    `json:"achieved"`
			UnlockTime int    `json:"unlocktime"`
		} `json:"achievements"`
	} `json:"playerstats"`
}

type GameSchemaResponse struct {
	Game struct {
		AvailableGameStats struct {
			Achievements []struct {
				Name        string `json:"name"`
				DisplayName string `json:"displayName"`
				Description string `json:"description"`
				Icon        string `json:"icon"`
				IconGray    string `json:"icongray"`
			} `json:"achievements"`
		} `json:"availableGameStats"`
	} `json:"game"`
}

type FriendListResponse struct {
	FriendsList struct {
		Friends []struct {
			SteamID      string `json:"steamid"`
			Relationship string `json:"relationship"`
			FriendSince  int    `json:"friend_since"`
		} `json:"friends"`
	} `json:"friendslist"`
}

type RecentlyPlayedGamesResponse struct {
	Response struct {
		TotalCount int         `json:"total_count"`
		Games      []SteamGame `json:"games"`
	} `json:"response"`
}

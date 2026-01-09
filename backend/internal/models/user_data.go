package models

import "encoding/json"

type LocalGameStatus int

const (
	StatusNone LocalGameStatus = iota
	StatusBacklog
	StatusPlaying
	StatusCompleted
	StatusDropped
)

// LocalGameData represents the user's custom data for a game.
type LocalGameData struct {
	AppID      int             `json:"appId"`
	Rating     *float64        `json:"rating,omitempty"`
	Notes      *string         `json:"notes,omitempty"`
	Status     LocalGameStatus `json:"status"`
	IsFavorite bool            `json:"isFavorite"`
	PlayOrder  *int            `json:"playOrder,omitempty"`
}

func (l *LocalGameData) ToJSONString() (string, error) {
	b, err := json.Marshal(l)
	return string(b), err
}

func LocalGameDataFromJSONString(s string) (*LocalGameData, error) {
	var l LocalGameData
	err := json.Unmarshal([]byte(s), &l)
	return &l, err
}

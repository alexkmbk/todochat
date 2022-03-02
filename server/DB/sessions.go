package DB

import (
	"net/http"
	"time"

	"github.com/google/uuid"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// Session Session info
type Session struct {
	SessionID uuid.UUID `gorm:"primary_key"`
	LastVisit time.Time `gorm:"index"`
	UserID    int64     `gorm:"foreignKey:ID"`
}

var sessionDB, _ = gorm.Open(sqlite.Open("file::memory:?cache=shared"), &gorm.Config{})

// CheckSessionID Checks if session exists
func CheckSessionID(w http.ResponseWriter, r *http.Request) bool {
	SessionID := r.Header.Get("SessionID")
	//err := json.NewDecoder(r.Body).Decode(&loginData)
	var session Session
	var err error
	session.SessionID, err = uuid.Parse(SessionID)
	if err != nil {
		w.WriteHeader(401)
		w.Write([]byte("Unauthorised.\n"))
		return false
	}
	if err = sessionDB.First(&session).Error; err != nil {
		w.WriteHeader(401)
		w.Write([]byte("Unauthorised.\n"))
		return false
	}
	session.LastVisit = time.Now()
	sessionDB.Save(&session)
	return true //session.UserID
}

// GetUserID returns user id by given sessionID from htt request
func GetUserID(w http.ResponseWriter, r *http.Request) int64 {
	SessionID := r.Header.Get("SessionID")
	//err := json.NewDecoder(r.Body).Decode(&loginData)
	var session Session
	var err error
	session.SessionID, err = uuid.Parse(SessionID)
	if err != nil {
		w.WriteHeader(401)
		w.Write([]byte("Unauthorised.\n"))
		return 0
	}
	if err = sessionDB.First(&session).Error; err != nil {
		w.WriteHeader(401)
		w.Write([]byte("Unauthorised.\n"))
		return 0
	}
	session.LastVisit = time.Now()
	sessionDB.Save(&session)
	return session.UserID
}

func SessionIDExists(sessionID uuid.UUID) bool {
	var session Session
	var err error
	session.SessionID = sessionID
	if err = sessionDB.First(&session).Error; err != nil {
		return false
	}
	return true
}

// CreateNewSession ...
func CreateNewSession(user User) uuid.UUID {
	var session Session
	session.LastVisit = time.Now()
	session.SessionID = uuid.New()
	session.UserID = user.ID
	sessionDB.Create(&session)
	return session.SessionID
}

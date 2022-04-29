package DB

import (
	"net/http"
	"time"

	"github.com/google/uuid"
	//"gorm.io/driver/sqlite"
	"github.com/glebarez/sqlite"
	"gorm.io/gorm"
)

// Session Session info
type Session struct {
	SessionID uuid.UUID `gorm:"primary_key"`
	LastVisit time.Time `gorm:"index"`
	UserID    int64     `gorm:"foreignKey:ID"`
}

var sessionDB, _ = gorm.Open(sqlite.Open("file::memory:?cache=shared"), &gorm.Config{SkipDefaultTransaction: true})

// CheckSessionID Checks if session exists
func CheckSessionID(w http.ResponseWriter, r *http.Request, udateLastVisit bool) bool {
	SessionID := r.Header.Get("SessionID")
	//err := json.NewDecoder(r.Body).Decode(&loginData)
	var session Session
	var err error
	session.SessionID, err = uuid.Parse(SessionID)
	if err != nil {
		http.Error(w, "Unauthorised.", http.StatusUnauthorized)
		return false
	}
	if sessionDB.First(&session).Error != nil {
		http.Error(w, "Unauthorised.", http.StatusUnauthorized)
		return false
	}
	if udateLastVisit {
		session.LastVisit = time.Now()
		sessionDB.Save(&session)
	}
	return true //session.UserID
}

// GetUserID returns user id by given sessionID from htt request
func GetUserID(w http.ResponseWriter, r *http.Request) int64 {
	SessionID := r.Header.Get("SessionID")
	var session Session
	var err error
	session.SessionID, err = uuid.Parse(SessionID)
	if err != nil {
		http.Error(w, "Unauthorised.", http.StatusUnauthorized)
		return 0
	}
	if err = sessionDB.First(&session).Error; err != nil {
		http.Error(w, "Unauthorised.", http.StatusUnauthorized)
		return 0
	}
	return session.UserID
}

func GetUserIDBySessionID(sessionID uuid.UUID) int64 {
	var session Session
	session.SessionID = sessionID

	var err error
	if err = sessionDB.First(&session).Error; err != nil {
		return 0
	}
	return session.UserID
}

func SessionIDExists(sessionID uuid.UUID) bool {
	var session Session
	session.SessionID = sessionID
	if sessionDB.First(&session).Error != nil {
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

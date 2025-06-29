package service

import (
	"net/http"
	"time"

	"github.com/google/uuid"
	//"gorm.io/driver/sqlite"
	. "todochat_server/db"
	. "todochat_server/models"
	//"todochat_server/constrollers/Messages"
	//"todochat_server/handlers" // Importing handlers to use GetUnreadMessagesByProjects
)

//var sessionDB, _ = gorm.Open(sqlite.Open("file::memory:?cache=shared"), &gorm.Config{SkipDefaultTransaction: true})

// CheckSessionID Checks if session exists
func SessionExists(sessionID string, updateLastVisit bool) (bool, *User) {
	var session Session
	var err error
	session.SessionID, err = uuid.Parse(sessionID)
	if err != nil {
		return false, nil
	}
	if DB.Find(&session).RowsAffected == 0 {
		return false, nil
	}
	if updateLastVisit {
		session.LastVisit = time.Now()
		DB.Save(&session)
	}

	user, success := GetUserByID(session.UserID)

	if success {
		return true, user //session.UserID
	} else {
		return false, nil
	}

}

func Logoff(w http.ResponseWriter, r *http.Request) {

	sessionID, err := uuid.Parse(r.Header.Get("SessionID"))

	if err != nil {
		DeleteSession(sessionID)
	}

}

// GetUserID returns user id by given sessionID from htt request
func GetSession(sessionID string) (Session, error) {
	var session Session
	var err error
	session.SessionID, err = uuid.Parse(sessionID)
	if err != nil {
		return session, err
	}
	if err = DB.First(&session).Error; err != nil {
		return session, err
	}
	return session, nil
}

func GetUserIDBySessionID(sessionID uuid.UUID) int64 {
	var session Session
	session.SessionID = sessionID

	var err error
	if err = DB.First(&session).Error; err != nil {
		return 0
	}
	return session.UserID
}

func SessionIDExists(sessionID uuid.UUID) bool {
	var session Session
	session.SessionID = sessionID
	if DB.First(&session).Error != nil {
		return false
	}
	return true
}

func DeleteSession(sessionID uuid.UUID) {
	var session Session
	session.SessionID = sessionID
	DB.Delete(&session)
}

// CreateNewSession ...
func CreateNewSession(user *User) uuid.UUID {
	var session Session
	session.LastVisit = time.Now()
	session.SessionID = uuid.New()
	session.UserID = user.ID
	DB.Create(&session)
	return session.SessionID
}

package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/google/uuid"
	//"gorm.io/driver/sqlite"
	. "todochat_server/models"
	"todochat_server/service"
	//"todochat_server/constrollers/Messages"
	//"todochat_server/handlers" // Importing handlers to use GetUnreadMessagesByProjects
)

//var sessionDB, _ = gorm.Open(sqlite.Open("file::memory:?cache=shared"), &gorm.Config{SkipDefaultTransaction: true})

// CheckSessionID Checks if session exists
func CheckSessionID(w http.ResponseWriter, r *http.Request, updateLastVisit bool) (bool, *User) {

	return service.SessionExists(r.Header.Get("SessionID"), updateLastVisit)

}

func CheckLogin(w http.ResponseWriter, r *http.Request) {
	res, user := CheckSessionID(w, r, true)
	if res {

		decoder := json.NewDecoder(r.Body)
		var data map[string]string

		err := decoder.Decode(&data)
		if err != nil {
			http.Error(w, "Json parsing error", http.StatusBadRequest)
			return
		}

		res := map[string]interface{}{
			"username": user.Name,
			"userid":   user.ID}
		if data["returnUnreadMessages"] == "true" {
			res["unreadMessagesByProjects"] = service.GetUnreadMessagesByProjects()
		}
		if data["returnProjects"] == "true" {
			res["projects"] = service.GetProjectsList()
		}

		json.NewEncoder(w).Encode(data)
	}
}

func Login(w http.ResponseWriter, r *http.Request) {

	/*sessionID := createNewSession()
	io.WriteString(w, "{\"sessionID\":\""+sessionID.String()+"\"}")
	return*/

	/*var params LoginParams
	err := json.NewDecoder(r.Body).Decode(&params)
	if err != nil {
		log.Fatal(err)
	}*/

	decoder := json.NewDecoder(r.Body)
	var data map[string]string

	err := decoder.Decode(&data)
	if err != nil {
		http.Error(w, "Json parsing error", http.StatusBadRequest)
		return
	}

	UserName := data["UserName"]
	passwordHash := data["passwordHash"]

	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	user, success := service.FindUserByName(UserName)
	if !success {
		http.Error(w, "Unauthorised.\n User was not found.\n", http.StatusUnauthorized)
	} else {
		/*h := sha256.New()
		h.Write([]byte(Password))
		hs := fmt.Sprintf("%x", h.Sum(nil))*/
		if user.PasswordHash != passwordHash {
			http.Error(w, "Unauthorised.\n Wrong password.\n", http.StatusUnauthorized)
		} else {
			sessionID := service.CreateNewSession(user)
			res := make(map[string]interface{})
			res["SessionID"] = sessionID

			if data["returnUnreadMessages"] == "true" {
				res["unreadMessagesByProjects"] = service.GetUnreadMessagesByProjects()
			}
			if data["returnProjects"] == "true" {
				res["projects"] = service.GetProjectsList()
			}

			json.NewEncoder(w).Encode(res)
			//io.WriteString(w, "{\"sessionID\":\""+sessionID.String()+"\",\"userID\":\""+strconv.Itoa(user.ID)+"\"}")
		}
	}
	/*userName, pass, _ := r.BasicAuth()
	var user User
	w.Header().Set("WWW-Authenticate", `Basic realm="todolist"`)
	err := DB.Where("Name = ?", userName).First(&user)
	if err == nil {
		w.WriteHeader(401)
		w.Write([]byte("Unauthorised.\n User was not found. \n"))
	} else {
		h := sha1.New()
		h.Write([]byte(pass))
		hs := fmt.Sprintf("%x", h.Sum(nil))
		if user.passHash != hs {
			w.WriteHeader(401)
			w.Write([]byte("Unauthorised.\n Wrong password.\n"))
		} else {
			io.WriteString(w, `{result: true}`)
		}
	}*/
}

func Logoff(w http.ResponseWriter, r *http.Request) {

	sessionID, err := uuid.Parse(r.Header.Get("SessionID"))

	if err != nil {
		service.DeleteSession(sessionID)
	}

}

// GetUserID returns user id by given sessionID from htt request
func GetUserID(w http.ResponseWriter, r *http.Request) int64 {
	session, err := service.GetSession(r.Header.Get("SessionID"))
	if err != nil {
		http.Error(w, "Unauthorised.", http.StatusUnauthorized)
		return 0
	}

	return session.UserID
}

// func GetUserIDBySessionID(sessionID uuid.UUID) int64 {
// 	var session Session
// 	session.SessionID = sessionID

// 	var err error
// 	if err = DB.First(&session).Error; err != nil {
// 		return 0
// 	}
// 	return session.UserID
// }

// func SessionIDExists(sessionID uuid.UUID) bool {
// 	var session Session
// 	session.SessionID = sessionID
// 	if DB.First(&session).Error != nil {
// 		return false
// 	}
// 	return true
// }

// func DeleteSession(sessionID uuid.UUID) {
// 	var session Session
// 	session.SessionID = sessionID
// 	DB.Delete(&session)
// }

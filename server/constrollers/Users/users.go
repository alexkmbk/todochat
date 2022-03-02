package Users

import (
	"encoding/json"
	"io"
	"net/http"
	"strconv"

	. "todochat_server/DB"

	//"github.com/gorilla/mux"
	log "github.com/sirupsen/logrus"
)

func Login(w http.ResponseWriter, r *http.Request) {

	/*sessionID := createNewSession()
	io.WriteString(w, "{\"sessionID\":\""+sessionID.String()+"\"}")
	return*/

	/*var params LoginParams
	err := json.NewDecoder(r.Body).Decode(&params)
	if err != nil {
		log.Fatal(err)
	}*/
	UserName := r.Header.Get("UserName")
	passwordHash := r.Header.Get("passwordHash")
	var user User
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	err := DB.Where("Name = ?", UserName).First(&user).Error
	if err != nil {
		w.WriteHeader(401)
		w.Write([]byte("Unauthorised.\n User was not found. \n"))
	} else {
		/*h := sha256.New()
		h.Write([]byte(Password))
		hs := fmt.Sprintf("%x", h.Sum(nil))*/
		if user.PasswordHash != passwordHash {
			w.WriteHeader(401)
			w.Write([]byte("Unauthorised.\n Wrong password.\n"))
		} else {
			sessionID := CreateNewSession(user)
			res := make(map[string]interface{})
			res["SessionID"] = sessionID
			res["UserID"] = user.ID
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

func RegisterNewUser(w http.ResponseWriter, r *http.Request) {
	var user User

	decoder := json.NewDecoder(r.Body)
	var data map[string]string

	err := decoder.Decode(&data)
	if err != nil {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"updated": false, "error": "Record Not Found"}`)
	} else {
		log.WithFields(log.Fields{"User": data["Name"]}).Info("Add new User. Saving to database.")
		//message := &Message{Description: description, Completed: false, Creation_date: time.Now()}
		user.Name = data["Name"]
		user.PasswordHash = data["passwordHash"]
		DB.Create(&user)
		//DB.Last(&todo)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		//io.WriteString(w, `{result: true}`)
		//json.NewEncoder(w).Encode(user)
		sessionID := CreateNewSession(user)
		io.WriteString(w, "{\"sessionID\":\""+sessionID.String()+"\",\"userID\":"+strconv.FormatInt(user.ID, 10)+"}")

	}
}

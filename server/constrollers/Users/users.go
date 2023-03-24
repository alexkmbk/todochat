package Users

import (
	"encoding/json"
	"io"
	"net/http"
	"strconv"

	. "todochat_server/App"
	. "todochat_server/DB"
	//"github.com/gorilla/mux"
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

	decoder := json.NewDecoder(r.Body)
	var data map[string]string

	err := decoder.Decode(&data)
	if err != nil {
		http.Error(w, "Json parsing error", http.StatusBadRequest)
		return
	}

	UserName := data["UserName"]
	passwordHash := data["passwordHash"]

	var user User
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	err = DB.Where("Name = ?", UserName).First(&user).Error
	if err != nil {
		http.Error(w, "Unauthorised.\n User was not found.\n", http.StatusUnauthorized)
	} else {
		/*h := sha256.New()
		h.Write([]byte(Password))
		hs := fmt.Sprintf("%x", h.Sum(nil))*/
		if user.PasswordHash != passwordHash {
			http.Error(w, "Unauthorised.\n Wrong password.\n", http.StatusUnauthorized)
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

func GetItemByID(ID int64) (*User, bool) {
	user := &User{}
	result := DB.First(&user, ID)
	if result.Error != nil {
		Log_warn("User not found in database")
		return user, false
	}
	return user, true
}

func RegisterNewUser(w http.ResponseWriter, r *http.Request) {
	var user User

	decoder := json.NewDecoder(r.Body)
	var data map[string]string

	err := decoder.Decode(&data)
	if err != nil {
		http.Error(w, "Json parsing error", http.StatusBadRequest)
	} else {
		Log("Add new User. Saving to database.")
		user.Name = data["Name"]
		user.PasswordHash = data["passwordHash"]

		var count int64
		DB.Model(&User{}).Where("Name = ?", user.Name).Count(&count)

		if count > 0 {
			http.Error(w, "User already exists", http.StatusBadRequest)
		} else {
			DB.Create(&user)
			w.Header().Set("Content-Type", "application/json; charset=utf-8")
			sessionID := CreateNewSession(user)
			io.WriteString(w, "{\"sessionID\":\""+sessionID.String()+"\",\"userID\":"+strconv.FormatInt(user.ID, 10)+"}")

		}

	}
}

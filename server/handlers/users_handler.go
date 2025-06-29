package handlers

import (
	"encoding/json"
	"io"
	"net/http"
	"strconv"

	. "todochat_server/models"
	"todochat_server/service"
	"todochat_server/utils"
	//"github.com/gorilla/mux"
)

func RegisterNewUser(w http.ResponseWriter, r *http.Request) {
	var user User

	decoder := json.NewDecoder(r.Body)
	var data map[string]string

	err := decoder.Decode(&data)
	if err != nil {
		http.Error(w, "Json parsing error", http.StatusBadRequest)
	} else {
		utils.Log("Add new User. Saving to database.")
		user.Name = data["Name"]
		user.PasswordHash = data["passwordHash"]

		_, success := service.FindUserByName(user.Name)

		if success {
			http.Error(w, "User already exists", http.StatusBadRequest)
		} else {
			service.CreateUser(&user) // Assuming CreateUser is a function that saves the user to the database
			w.Header().Set("Content-Type", "application/json; charset=utf-8")
			sessionID := service.CreateNewSession(&user)
			io.WriteString(w, "{\"sessionID\":\""+sessionID.String()+"\",\"userID\":"+strconv.FormatInt(user.ID, 10)+"}")

		}

	}
}

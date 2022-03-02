package Messages

import (
	"encoding/json"
	"io"
	"net/http"
	"strconv"
	"time"

	//"github.com/gorilla/mux"
	"github.com/gorilla/mux"
	log "github.com/sirupsen/logrus"

	. "todochat_server/DB"
	WS "todochat_server/constrollers/WebSocked"
)

func GetMessages(w http.ResponseWriter, r *http.Request) {

	log.Info("Get Messages")

	if !CheckSessionID(w, r) {
		return
	}

	lastID, err := strconv.Atoi(r.Header.Get("lastID"))
	if err != nil {
		return
	}

	/*offset, err := strconv.Atoi(r.Header.Get("offset"))
	if err != nil {
		offset = 0
	}*/

	limit, err := strconv.Atoi(r.Header.Get("limit"))
	if err != nil {
		return
	}

	taskID, err := strconv.Atoi(r.Header.Get("taskID"))
	if err != nil {
		return
	}

	var messages []Message
	//DB.Where("task_id = ?", taskID).Order("created_at desc").Offset(offset).Limit(limit).Find(&messages)
	if lastID == 0 {
		DB.Order("ID desc").Where("task_id = ?", taskID).Limit(limit).Find(&messages)
	} else {
		DB.Order("ID desc").Where("task_id = ? AND ID < ?", taskID, lastID).Limit(limit).Find(&messages)
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	json.NewEncoder(w).Encode(messages)
}

func CreateMessage(w http.ResponseWriter, r *http.Request) {
	userID := GetUserID(w, r)
	if userID == 0 {
		return
	}
	decoder := json.NewDecoder(r.Body)
	var message Message

	err := decoder.Decode(&message)
	if err != nil {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"updated": false, "error": "Record Not Found"}`)
	} else {
		text := message.Text
		log.WithFields(log.Fields{"text": text}).Info("Add new Message. Saving to database.")
		//message := &Message{Description: description, Completed: false, Creation_date: time.Now()}
		message.Created_at = time.Now()
		message.UserID = userID
		DB.Create(&message)
		//DB.Last(&todo)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		//io.WriteString(w, `{result: true}`)
		json.NewEncoder(w).Encode(message)
		WS.SendWSMessage(message)
	}
}

func getItemByID(ID int) (*Message, bool) {
	message := &Message{}
	result := DB.First(&message, ID)
	if result.Error != nil {
		log.Warn("Message not found in database")
		return message, false
	}
	return message, true
}

func DeleteItem(w http.ResponseWriter, r *http.Request) {

	if !CheckSessionID(w, r) {
		return
	}

	// Get URL parameter from mux
	vars := mux.Vars(r)
	id, _ := strconv.Atoi(vars["id"])

	message, err := getItemByID(id)

	if err == false {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"deleted": false, "error": "Record Not Found"}`)
	} else {
		log.WithFields(log.Fields{"ID": id}).Info("Deleting TodoItem")

		DB.First(&message, id)
		DB.Delete(&message)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"deleted": true}`)
	}
}

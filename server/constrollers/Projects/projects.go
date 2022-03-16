package Projects

import (
	"encoding/json"
	"io"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
	log "github.com/sirupsen/logrus"

	. "todochat_server/DB"
)

func CreateItem(w http.ResponseWriter, r *http.Request) {
	userID := GetUserID(w, r)
	if userID == 0 {
		return
	}
	decoder := json.NewDecoder(r.Body)
	var item Project

	err := decoder.Decode(&item)
	if err != nil {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"updated": false, "error": "Record Not Found"}`)
	} else {
		description := item.Description
		log.WithFields(log.Fields{"description": description}).Info("Add new TodoItem. Saving to database.")
		DB.Create(&item)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(item)
	}
}

/*func UpdateItem(w http.ResponseWriter, r *http.Request) {
	// Get URL parameter from mux
	vars := mux.Vars(r)
	id, _ := strconv.Atoi(vars["id"])

	// Test if the TodoItem exist in DB
	err := getItemByID(id)
	if err == false {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"updated": false, "error": "Record Not Found"}`)
	} else {
		completed, _ := strconv.ParseBool(r.Header.Get("completed"))
		log.WithFields(log.Fields{"Id": id, "Completed": completed}).Info("Updating TodoItem")
		todo := &Task{}
		DB.First(&todo, id)
		todo.Completed = completed
		DB.Save(&todo)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"updated": true}`)
	}
}*/

func DeleteItem(w http.ResponseWriter, r *http.Request) {

	if !CheckSessionID(w, r) {
		return
	}

	// Get URL parameter from mux
	vars := mux.Vars(r)
	id, _ := strconv.Atoi(vars["id"])

	// Test if the TodoItem exist in DB
	item := getItemByID(id)
	if item == nil {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"deleted": false, "error": "Record Not Found"}`)
	} else {
		DB.Delete(&item)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"deleted": true}`)
	}
}

func getItemByID(ID int) *Project {
	item := &Project{}
	result := DB.First(&item, ID)
	if result.Error != nil {
		log.Warn("Project not found in database")
		return nil
	}
	return item
}

func GetItem(w http.ResponseWriter, r *http.Request) {

	vars := mux.Vars(r)
	id, _ := strconv.Atoi(vars["id"])

	item := getItemByID(id)
	if item == nil {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"deleted": false, "error": "Record Not Found"}`)
	} else {

		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(item)

	}
}

func GetItems(w http.ResponseWriter, r *http.Request) {

	log.Info("Get projects")

	if !CheckSessionID(w, r) {
		w.WriteHeader(401)
		w.Write([]byte("Unauthorised.\n User was not found. \n"))
		return
	}

	limit, err := strconv.Atoi(r.Header.Get("limit"))
	if err != nil {
		limit = 0
	}

	var items []Project
	if limit != 0 {
		DB.Order("Description asc").Limit(limit).Find(&items)
	} else {
		DB.Order("Description asc").Find(&items)
	}
	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	m := make(map[string]interface{})
	m["items"] = items
	json.NewEncoder(w).Encode(m)
}

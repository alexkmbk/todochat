package Projects

import (
	"encoding/json"
	"io"
	"net/http"
	"strconv"

	. "todochat_server/App"
	. "todochat_server/DB"

	"github.com/gorilla/mux"
)

func CreateItem(w http.ResponseWriter, r *http.Request) {
	decoder := json.NewDecoder(r.Body)
	var item Project

	err := decoder.Decode(&item)
	if err != nil {
		http.Error(w, "Json decode error", http.StatusInternalServerError)
	} else {
		Log("Add new TodoItem. Saving to database.")
		DB.Create(&item)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(item)
	}
}

func UpdateItem(w http.ResponseWriter, r *http.Request) {

	decoder := json.NewDecoder(r.Body)
	var item Project

	err := decoder.Decode(&item)
	if err != nil {
		http.Error(w, "Json decode error", http.StatusInternalServerError)
	} else {
		DB.Save(&item)
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

	// Get URL parameter from mux
	vars := mux.Vars(r)
	id, _ := strconv.Atoi(vars["id"])

	// Test if the TodoItem exist in DB
	item := getItemByID(id)
	if item == nil {
		http.Error(w, "Record Not Found", http.StatusNotFound)
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
		Log_warn("Project not found in database")
		return nil
	}
	return item
}

func GetItem(w http.ResponseWriter, r *http.Request) {

	vars := mux.Vars(r)
	id, _ := strconv.Atoi(vars["id"])

	item := getItemByID(id)
	if item == nil {
		http.Error(w, "Record Not Found", http.StatusNotFound)
	} else {

		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(item)

	}
}

func GetItems(w http.ResponseWriter, r *http.Request) {

	Log("Get projects")

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

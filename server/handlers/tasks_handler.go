package handlers

import (
	"encoding/json"
	"io"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"

	WS "todochat_server/WebSocked"
	. "todochat_server/models"
	"todochat_server/service"
	"todochat_server/utils"
)

func CreateTask(w http.ResponseWriter, r *http.Request) {
	userID := GetUserID(w, r)
	if userID == 0 {
		return
	}

	projectID, err := strconv.ParseInt(r.Header.Get("ProjectID"), 10, 64)
	if err != nil {
		return
	}

	decoder := json.NewDecoder(r.Body)
	var task Task

	err = decoder.Decode(&task)
	if err != nil {
		http.Error(w, "JSON parse error", http.StatusInternalServerError)
	} else {
		description := task.Description
		service.CreateTask(projectID, userID, description)
		utils.Log("Add new TodoItem. Saving to database.")

		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(task)

		go WS.SendTask(&task)

	}
}

func MarkAllRead(w http.ResponseWriter, r *http.Request) {

	UserID := GetUserID(w, r)
	if UserID == 0 {
		return
	}
	service.MarkAllRead(UserID)
}

func GetTask(w http.ResponseWriter, r *http.Request) {

	userID := GetUserID(w, r)
	if userID == 0 {
		return
	}

	// Get URL parameter from mux
	vars := mux.Vars(r)
	id := utils.ToInt64(vars["id"])

	task, err := service.GetTaskByID(id)

	if err != nil {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"error": "`+err.Error()+`"}`)
	} else {

		// return message as json
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(task)
	}
}

func UpdateTask(w http.ResponseWriter, r *http.Request) {
	decoder := json.NewDecoder(r.Body)
	var task Task

	err := decoder.Decode(&task)
	if err != nil {
		http.Error(w, "Record Not Found", http.StatusNotFound)
	} else {
		service.UpdateTask(&task)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"updated": true}`)
		go WS.SendUpdateTask(&task, 0)
	}
}

func DeleteTask(w http.ResponseWriter, r *http.Request) {

	// Get URL parameter from mux
	vars := mux.Vars(r)
	id := utils.ToInt64(vars["id"])

	utils.Log("Deleting TodoItem")
	task, err := service.DeleteTask(id)
	if err != nil {
		http.Error(w, "Record Not Found", http.StatusNotFound)
	} else {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"deleted": true}`)
		go WS.SendDeleteTask(task)
	}

}

func GetTasks(w http.ResponseWriter, r *http.Request) {

	utils.Log_warn("Get Tasks")

	query := r.URL.Query()
	lastID, err := strconv.Atoi(query.Get("lastID"))
	if err != nil {
		return
	}
	lastCreation_Date, _ := time.Parse(time.RFC3339, query.Get("lastCreation_date"))

	limit, err := strconv.Atoi(query.Get("limit"))
	if err != nil {
		return
	}

	showClosed, err := strconv.ParseBool(query.Get("showClosed"))
	if err != nil {
		showClosed = true
	}

	projectID, err := strconv.Atoi(query.Get("ProjectID"))
	if err != nil {
		return
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	UserID := GetUserID(w, r)

	tasks := service.GetTasks(UserID, int64(lastID), lastCreation_Date, limit, showClosed, int64(projectID))

	m := make(map[string]interface{})
	m["tasks"] = tasks
	json.NewEncoder(w).Encode(m)

}

func SearchTasks(w http.ResponseWriter, r *http.Request) {

	utils.Log("Search for Tasks")

	query := r.URL.Query()
	search := query.Get("search")
	showClosed, errShowClosed := strconv.ParseBool(query.Get("showClosed"))
	if errShowClosed != nil {
		showClosed = true
	}

	projectID := utils.ToInt64(query.Get("ProjectID"))

	UserID := GetUserID(w, r)

	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	m := make(map[string]interface{})
	m["tasks"] = service.SearchTasks(search, UserID, projectID, showClosed)
	json.NewEncoder(w).Encode(m)
}

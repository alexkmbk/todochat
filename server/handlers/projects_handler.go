package handlers

import (
	"encoding/json"
	"io"
	"net/http"
	"strconv"

	. "todochat_server/models"
	"todochat_server/service"

	"todochat_server/utils"

	"github.com/gorilla/mux"
)

func CreateProject(w http.ResponseWriter, r *http.Request) {
	decoder := json.NewDecoder(r.Body)
	var item Project

	err := decoder.Decode(&item)
	if err != nil {
		http.Error(w, "Json decode error", http.StatusInternalServerError)
	} else {
		utils.Log("Add new TodoItem. Saving to database.")
		service.CreateProject(&item)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(item)
	}
}

func UpdateProject(w http.ResponseWriter, r *http.Request) {

	decoder := json.NewDecoder(r.Body)
	var item Project

	err := decoder.Decode(&item)
	if err != nil {
		http.Error(w, "Json decode error", http.StatusInternalServerError)
	} else {
		service.UpdateProject(&item)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(item)
	}
}

func DeleteProject(w http.ResponseWriter, r *http.Request) {

	// Get URL parameter from mux
	vars := mux.Vars(r)
	id := utils.ToInt64(vars["id"])

	err := service.DeleteProject(id)
	if err != nil {
		http.Error(w, "Record Not Found", http.StatusNotFound)
	} else {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"deleted": true}`)
	}
}

func GetProject(w http.ResponseWriter, r *http.Request) {

	vars := mux.Vars(r)
	id := utils.ToInt64(vars["id"])

	item, err := service.GetProjectByID(id)
	if err != nil {
		http.Error(w, "Record Not Found", http.StatusNotFound)
	} else {

		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(item)

	}
}

func GetProjects(w http.ResponseWriter, r *http.Request) {

	utils.Log("Get projects")

	limit, err := strconv.Atoi(r.Header.Get("limit"))
	if err != nil {
		limit = 0
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	m := make(map[string]interface{})
	m["items"] = service.GetProjects(limit)
	json.NewEncoder(w).Encode(m)
}

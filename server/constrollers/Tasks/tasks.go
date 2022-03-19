package Tasks

import (
	"database/sql"
	"encoding/json"
	"io"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"
	log "github.com/sirupsen/logrus"

	. "todochat_server/DB"
)

func CreateItem(w http.ResponseWriter, r *http.Request) {
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
		log.WithFields(log.Fields{"description": description}).Info("Add new TodoItem. Saving to database.")
		task := &Task{Description: description, Completed: false, Creation_date: time.Now(), AuthorID: userID, ProjectID: projectID}
		DB.Create(&task)
		//DB.Last(&todo)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		//io.WriteString(w, `{result: true}`)
		json.NewEncoder(w).Encode(task)
	}
}

func UpdateItem(w http.ResponseWriter, r *http.Request) {
	// Get URL parameter from mux
	vars := mux.Vars(r)
	id, _ := strconv.Atoi(vars["id"])

	// Test if the TodoItem exist in DB
	err := getItemByID(id)
	if err == false {
		http.Error(w, "Record Not Found", http.StatusNotFound)
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
}

func DeleteItem(w http.ResponseWriter, r *http.Request) {

	// Get URL parameter from mux
	vars := mux.Vars(r)
	id, _ := strconv.Atoi(vars["id"])

	// Test if the TodoItem exist in DB
	err := getItemByID(id)
	if err == false {
		http.Error(w, "Record Not Found", http.StatusNotFound)
	} else {
		log.WithFields(log.Fields{"ID": id}).Info("Deleting TodoItem")
		todo := &Task{}
		DB.First(&todo, id)
		DB.Delete(&todo)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"deleted": true}`)
	}
}

func getItemByID(ID int) bool {
	todo := &Task{}
	result := DB.First(&todo, ID)
	if result.Error != nil {
		log.Warn("TodoItem not found in database")
		return false
	}
	return true
}

func GetItems(w http.ResponseWriter, r *http.Request) {

	log.Info("Get Tasks")

	lastID, err := strconv.Atoi(r.Header.Get("lastID"))
	if err != nil {
		return
	}

	lastCreation_Date, err := time.Parse("2006-01-02 15:04:05.999999Z", r.Header.Get("lastCreation_date"))
	if err != nil {

	}

	limit, err := strconv.Atoi(r.Header.Get("limit"))
	if err != nil {
		return
	}

	projectID, err := strconv.Atoi(r.Header.Get("ProjectID"))
	if err != nil {
		return
	}

	var tasks []Task
	if lastID == 0 {
		DB.Order("Creation_date desc, ID desc").Where("project_ID = @projectID", sql.Named("projectID", projectID)).Limit(limit).Find(&tasks)
	} else {
		DB.Order("Creation_date desc, ID desc").Where("project_ID = @projectID AND (Creation_date < @Creation_date OR (Creation_date = @Creation_date AND ID < @ID))", sql.Named("projectID", projectID), sql.Named("Creation_date", lastCreation_Date), sql.Named("ID", lastID)).Limit(limit).Find(&tasks)
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	m := make(map[string]interface{})
	m["tasks"] = tasks
	json.NewEncoder(w).Encode(m)

	//lastItem := r.Header.Get("lastItem")

	//DB.Where("completed = ?", false)

	//orderby := strings.Split(string(r.Header.Get("orderby")), ",")

	//filter := r.Header.Get("filter")

	//fmt.Sprintf()
	/*rows, err := DB.Raw("select TodoItem.Description from TodoItem where TodoItem.Description > &Description", sql.Named("Description", lastItem)).Rows()

	if err == nil {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(rows)
	}*/

	//var todos []TodoItem
	//DB.Where("completed = ?", false).Find(&todos)
}

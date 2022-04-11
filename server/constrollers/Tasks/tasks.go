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

	. "todochat_server/App"
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
	decoder := json.NewDecoder(r.Body)
	var task Task

	err := decoder.Decode(&task)
	if err != nil {
		http.Error(w, "Record Not Found", http.StatusNotFound)
	} else {
		print(task.Creation_date.GoString())
		DB.Save(&task)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"updated": true}`)
	}
}

func DeleteItem(w http.ResponseWriter, r *http.Request) {

	// Get URL parameter from mux
	vars := mux.Vars(r)
	id := ToInt64(vars["id"])

	// Test if the TodoItem exist in DB
	item, err := GetItemByID(id)
	if err == false {
		http.Error(w, "Record Not Found", http.StatusNotFound)
	} else {
		log.WithFields(log.Fields{"ID": id}).Info("Deleting TodoItem")
		var messages []*Message
		DB.Where("Task_ID = ?", item.ID).Find(&messages)
		tx := DB.Begin()
		tx.Delete(&messages)
		tx.Delete(&item)
		tx.Commit()
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"deleted": true}`)
	}
}

func GetItemByID(ID int64) (*Task, bool) {
	task := &Task{}
	result := DB.First(&task, ID)
	if result.Error != nil {
		log.Warn("TodoItem not found in database")
		return task, false
	}
	return task, true
}

func GetItems(w http.ResponseWriter, r *http.Request) {

	log.Info("Get Tasks")

	query := r.URL.Query()
	lastID, err := strconv.Atoi(query.Get("lastID"))
	if err != nil {
		return
	}

	lastCreation_Date, _ := time.Parse("2006-01-02 15:04:05.999999Z", query.Get("lastCreation_date"))

	limit, err := strconv.Atoi(query.Get("limit"))
	if err != nil {
		return
	}

	projectID, err := strconv.Atoi(query.Get("ProjectID"))
	if err != nil {
		return
	}

	//filter := query.Get("filter")

	var tasks []*Task
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

func SearchItems(w http.ResponseWriter, r *http.Request) {

	log.Info("Search for Tasks")

	query := r.URL.Query()
	search := query.Get("search")

	projectID := ToInt64(query.Get("ProjectID"))

	//filter := query.Get("filter")

	var tasks []*Task

	rows, err := DB.Raw(`SELECT 
	found_messages.message_id as message_id,
	messages.text as text,  
	messages.created_at,
	messages.task_id as task_id, 
	tasks.description as task_description,
	tasks.creation_date as task_creation_date,
	tasks.author_id
	from 
	(SELECT max(rowid) as message_id, task_id FROM messages_fts(@search) where project_id = @projectID group by task_id) as found_messages 
	inner join messages on messages.ID = found_messages.message_id
	inner join tasks as tasks on tasks.ID = found_messages.task_id 
	`, sql.Named("search", search), sql.Named("projectID", projectID)).Order("created_at desc").Rows()
	/*UNION tasks.last_message_id, tasks.last_message, messages.text, tasks_fts.rowid, tasks.description, tasks.creation_date, tasks.author_id FROM tasks_fts(@search)
	inner join tasks as tasks on tasks.ID = rowid
	inner join messages as messages on tasks.last_message_id = messages.ID where project_id = @projectID`, sql.Named("search", search), sql.Named("projectID", projectID)).Order("created_at desc").Rows()*/
	defer func() {
		if rows != nil {
			rows.Close()
		}
	}()

	if err != nil {
		return
	}

	for rows.Next() {
		var text string
		var created_at, task_creation_date time.Time
		var message_id int64
		var task_id, author_id int64
		var description string
		var task Task
		rows.Scan(&message_id, &text, &created_at, &task_id, &description, &task_creation_date, &author_id)
		task = Task{ID: task_id, Description: description, LastMessage: text, LastMessageID: message_id, ProjectID: projectID, Creation_date: task_creation_date, AuthorID: author_id}
		tasks = append(tasks, &task)
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	m := make(map[string]interface{})
	m["tasks"] = tasks
	json.NewEncoder(w).Encode(m)
}

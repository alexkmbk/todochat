package Tasks

import (
	"database/sql"
	"encoding/json"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gorilla/mux"

	. "todochat_server/App"
	. "todochat_server/DB"
	"todochat_server/constrollers/Users"
	WS "todochat_server/constrollers/WebSocked"
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
		Log("Add new TodoItem. Saving to database.")
		task := &Task{Description: description,
			Completed:     false,
			Closed:        false,
			Cancelled:     false,
			Creation_date: time.Now(),
			AuthorID:      userID,
			ProjectID:     projectID}

		user, success := Users.GetItemByID(userID)
		if success {
			task.AuthorName = user.Name
		}

		DB.Create(&task)

		seenTask := SeenTask{UserID: userID, TaskID: task.ID}

		if DB.Limit(1).Find(&seenTask).RowsAffected == 0 {
			DB.Create(&seenTask)
		}

		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		json.NewEncoder(w).Encode(task)

		go WS.SendTask(task)

	}
}

func UpdateItem(w http.ResponseWriter, r *http.Request) {
	decoder := json.NewDecoder(r.Body)
	var task Task

	err := decoder.Decode(&task)
	if err != nil {
		http.Error(w, "Record Not Found", http.StatusNotFound)
	} else {
		DB.Save(&task)
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"updated": true}`)
		go WS.SendUpdateTask(&task, 0)
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
		Log("Deleting TodoItem")
		var messages []*Message
		DB.Where("Task_ID = ?", item.ID).Find(&messages)
		tx := DB.Begin()
		tx.Delete(&messages)
		tx.Delete(&item)
		tx.Commit()
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		io.WriteString(w, `{"deleted": true}`)
		go WS.SendDeleteTask(item)
	}

}

func GetItemByID(ID int64) (*Task, bool) {
	task := &Task{}
	result := DB.First(&task, ID)
	if result.Error != nil {
		Log_warn("TodoItem not found in database")
		return task, false
	}
	return task, true
}

func GetItems(w http.ResponseWriter, r *http.Request) {

	Log_warn("Get Tasks")

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

	//filter := query.Get("filter")

	var tasks []*Task
	if lastID == 0 {
		DB.Order("Creation_date desc, ID desc").Where("project_ID = @projectID AND (NOT Closed OR @showClosed)", sql.Named("projectID", projectID), sql.Named("showClosed", showClosed)).Limit(limit).Find(&tasks)
	} else {
		DB.Order("Creation_date desc, ID desc").Where("project_ID = @projectID AND (NOT Closed OR @showClosed) AND ((Creation_date <= @Creation_date AND ID < @ID))", sql.Named("projectID", projectID), sql.Named("showClosed", showClosed), sql.Named("Creation_date", lastCreation_Date), sql.Named("ID", lastID)).Limit(limit).Find(&tasks)
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	UserID := GetUserID(w, r)
	if UserID != 0 {
		for i := range tasks {
			//seenTask := SeenTask{UserID: UserID, TaskID: tasks[i].ID}
			seenTask := SeenTask{UserID: UserID, TaskID: tasks[i].ID}
			if DB.Find(&seenTask).RowsAffected > 0 {
				tasks[i].Read = true
			}

			/*if DB.First(&seenTask).Error == nil {
				tasks[i].Read = true
			}*/
			var readCount, total int64
			DB.Model(&SeenMessage{}).Where("user_id = ? AND task_id = ?", UserID, tasks[i].ID).Count(&readCount)
			DB.Model(&Message{}).Where("task_id = ? AND NOT Is_Task_Description_Item", tasks[i].ID).Count(&total)

			UnreadMessages := int(total - readCount)

			if UnreadMessages < 0 {
				UnreadMessages = 0
			}
			tasks[i].UnreadMessages = UnreadMessages

		}

	}

	m := make(map[string]interface{})
	m["tasks"] = tasks
	json.NewEncoder(w).Encode(m)

}

func SearchItems(w http.ResponseWriter, r *http.Request) {

	Log("Search for Tasks")

	query := r.URL.Query()
	search := query.Get("search")
	showClosed, errShowClosed := strconv.ParseBool(query.Get("showClosed"))
	if errShowClosed != nil {
		showClosed = true
	}

	projectID := ToInt64(query.Get("ProjectID"))

	UserID := GetUserID(w, r)

	//filter := query.Get("filter")

	var tasks []*Task
	var queryStr string
	var err error

	if DBMS == "SQLite" {
		queryStr = `SELECT
	ifnull(found_messages.message_id, 0) as message_id,
	messages.text as text,
	messages.created_at,
	messages.task_id as task_id,
	tasks.description as task_description,
	tasks.creation_date as task_creation_date,
	tasks.author_id,
	tasks.author_name,
	messages.user_name
	from
	(SELECT max(rowid) as message_id, task_id FROM messages_fts(@search) where project_id = @projectID group by task_id) as found_messages
	inner join messages on messages.ID = found_messages.message_id AND NOT messages.Is_Task_Description_Item
	inner join tasks as tasks on tasks.ID = found_messages.task_id AND (NOT tasks.Closed OR @showClosed) 
	UNION
	SELECT ifnull(tasks.last_message_id, 0),
	ifnull(tasks.last_message, 0),
	ifnull(messages.created_at, CURRENT_TIMESTAMP),
	tasks_fts.rowid,
	tasks.description,
	tasks.creation_date,
	tasks.author_id,
	tasks.author_name,
	tasks.Last_Message_User_Name
	FROM tasks_fts(@search)
	inner join tasks as tasks on tasks.ID = tasks_fts.rowid
	left join messages as messages on tasks.last_message_id = messages.ID where tasks.project_id = @projectID AND (NOT Closed OR @showClosed) AND (messages.project_id = @projectID OR messages.project_id IS NULL)
	UNION
	SELECT ifnull(tasks.last_message_id, 0),
	ifnull(tasks.last_message, 0),
	ifnull(messages.created_at, CURRENT_TIMESTAMP),
	tasks.id,
	tasks.description,
	tasks.creation_date,
	tasks.author_id,
	tasks.author_name,
	tasks.Last_Message_User_Name
	FROM tasks 
	left join messages as messages on tasks.last_message_id = messages.ID where tasks.id = @taskID AND tasks.project_id = @projectID AND (NOT Closed OR @showClosed) AND (messages.project_id = @projectID OR messages.project_id IS NULL)`

	} else {
		search = "%" + search + "%"
		queryStr = `SELECT
		coalesce(found_messages.message_id, 0) as message_id,
		messages.text as text,
		messages.created_at,
		messages.task_id as task_id,
		tasks.description as task_description,
		tasks.creation_date as task_creation_date,
		tasks.author_id,
		tasks.author_name,
		messages.user_name
		from
		(SELECT max(id) as message_id, task_id FROM messages where project_id = @projectID  AND messages.text like @search group by task_id) as found_messages
		inner join messages on messages.ID = found_messages.message_id AND NOT messages.Is_Task_Description_Item
		inner join tasks as tasks on tasks.ID = found_messages.task_id AND (NOT tasks.Closed OR @showClosed)
		UNION
		SELECT coalesce(found_tasks.last_message_id, 0),
		coalesce(found_tasks.last_message, ''),
		coalesce(messages.created_at, CURRENT_TIMESTAMP),
		found_tasks.id,
		found_tasks.description,
		found_tasks.creation_date,
		found_tasks.author_id,
		found_tasks.author_name,
		found_tasks.Last_Message_User_Name
		FROM (SELECT * from tasks WHERE tasks.project_id = @projectID AND (NOT tasks.Closed OR @showClosed) AND (tasks.Description Like @search OR tasks.ID = @taskID)) as found_tasks
		left join messages as messages on found_tasks.last_message_id = messages.ID where (messages.project_id = @projectID OR messages.project_id IS NULL)`
	}

	rows, err := DB.Raw(queryStr, sql.Named("search", search), sql.Named("showClosed", showClosed), sql.Named("projectID", projectID), sql.Named("taskID", strings.TrimLeft(search, "0"))).Order("created_at desc").Rows()

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
		var lastMessageUserName string
		var authorName string
		rows.Scan(&message_id, &text, &created_at, &task_id, &description, &task_creation_date, &author_id, &authorName, &lastMessageUserName)
		task = Task{ID: task_id, Description: description, LastMessage: text, LastMessageID: message_id, ProjectID: projectID, Creation_date: task_creation_date, AuthorID: author_id, AuthorName: authorName, LastMessageUserName: lastMessageUserName}

		if UserID != 0 {
			seenTask := SeenTask{UserID: UserID, TaskID: task.ID}
			if DB.Find(&seenTask).RowsAffected > 0 {
				task.Read = true
			}
		}

		tasks = append(tasks, &task)
	}

	w.Header().Set("Content-Type", "application/json; charset=utf-8")

	m := make(map[string]interface{})
	m["tasks"] = tasks
	json.NewEncoder(w).Encode(m)
}

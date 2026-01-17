package service

import (
	"database/sql"
	"strings"
	"time"

	. "todochat_server/db"
	. "todochat_server/models"
	"todochat_server/utils"
)

func CreateTask(userID int64, projectID int64, task *Task) {

	utils.Log("Add new TodoItem. Saving to database.")
	task.Creation_date = time.Now()
	task.AuthorID = userID
	task.ProjectID = projectID

	user, success := GetUserByID(userID)
	if success {
		task.AuthorName = user.Name
	}

	DB.Create(&task)

	seenTask := SeenTask{UserID: userID, TaskID: task.ID}

	if DB.Limit(1).Find(&seenTask).RowsAffected == 0 {
		DB.Create(&seenTask)
	}
}

func MarkAllRead(UserID int64) {

	queryStr := "select id from tasks where id NOT in (select task_id from seen_tasks where user_id = @user_id)"
	rows, err := DB.Raw(queryStr, sql.Named("user_id", UserID)).Rows()
	var seenTasks []*SeenTask

	if err == nil {
		for rows.Next() {
			var taskID int64
			rows.Scan(&taskID)
			seenTasks = append(seenTasks, &SeenTask{UserID: UserID, TaskID: taskID})
		}
		if rows != nil {
			rows.Close()
		}

		for i := range seenTasks {
			if DB.Find(seenTasks[i]).RowsAffected == 0 {
				DB.Create(seenTasks[i])
			}
		}
	}

	var seenMessages []*SeenMessage

	queryStr = "select id, task_id from messages where messages.id NOT in (select task_id from seen_messages where user_id = @user_id)"
	rows, err = DB.Raw(queryStr, sql.Named("user_id", UserID)).Rows()
	if err == nil {
		for rows.Next() {
			var taskID int64
			var messageID int64
			rows.Scan(&messageID, &taskID)
			seenMessages = append(seenMessages, &SeenMessage{UserID: UserID, TaskID: taskID, MessageID: messageID})
		}

		if rows != nil {
			rows.Close()
		}

		for i := range seenMessages {
			if DB.Find(seenMessages[i]).RowsAffected == 0 {
				DB.Create(seenMessages[i])
			}
		}
	}
}

func GetTaskByID(id int64) (*Task, error) {
	task := &Task{ID: id}
	result := DB.First(&task)
	if result.Error != nil {
		utils.Log_warn("TodoItem not found in database")
		return nil, result.Error
	}
	return task, nil
}

func UpdateTask(task *Task) {
	DB.Save(&task)
}

func DeleteTask(id int64) (*Task, error) {
	item, err := GetTaskByID(id)
	if err != nil {
		return item, err
	} else {
		var messages []*Message
		DB.Where("Task_ID = ?", item.ID).Find(&messages)
		tx := DB.Begin()
		tx.Delete(&messages)
		tx.Delete(&item)
		tx.Commit()
	}
	return item, nil
}

// func GetTaskByID(ID int64) (*Task, error) {
// 	task := &Task{}
// 	result := DB.First(&task, ID)
// 	if result.Error != nil {
// 		utils.Log_warn("TodoItem not found in database")
// 		return task, result.Error
// 	}
// 	return task, nil
// }

func GetTasks(UserID int64, lastID int64, lastCreation_Date time.Time, limit int, showClosed bool, projectID int64) []*Task {

	//filter := query.Get("filter")

	var tasks []*Task
	if lastID == 0 {
		DB.Order("Creation_date desc, ID desc").Where("project_ID = @projectID AND (NOT Closed OR @showClosed)", sql.Named("projectID", projectID), sql.Named("showClosed", showClosed)).Limit(limit).Find(&tasks)
	} else {
		DB.Order("Creation_date desc, ID desc").Where("project_ID = @projectID AND (NOT Closed OR @showClosed) AND ((Creation_date <= @Creation_date AND ID < @ID))", sql.Named("projectID", projectID), sql.Named("showClosed", showClosed), sql.Named("Creation_date", lastCreation_Date), sql.Named("ID", lastID)).Limit(limit).Find(&tasks)
	}

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

	return tasks

}

func SearchTasks(search string, userID int64, projectID int64, showClosed bool) []*Task {

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
		return tasks
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

		if userID != 0 {
			seenTask := SeenTask{UserID: userID, TaskID: task.ID}
			if DB.Find(&seenTask).RowsAffected > 0 {
				task.Read = true
			}
		}

		tasks = append(tasks, &task)
	}

	return tasks
}

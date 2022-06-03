package DB

import (
	"crypto/sha256"
	"encoding/hex"
	"path/filepath"

	"github.com/google/uuid"
	log "github.com/sirupsen/logrus"

	. "todochat_server/App"

	//"gorm.io/driver/sqlite"
	"github.com/glebarez/sqlite"
	"gorm.io/gorm"
)

//+var db, _ = gorm.Open("mysql", "root:root@/todolist?charset=utf8&parseTime=True&loc=Local")
//var dsn = "host=localhost user=postgres password=123 dbname=todolist port=5432 sslmode=disable TimeZone=Asia/Shanghai"
var DB *gorm.DB

func DropUnusedColumns(dst interface{}) {

	stmt := &gorm.Statement{DB: DB}
	stmt.Parse(dst)
	fields := stmt.Schema.Fields
	columns, _ := DB.Debug().Migrator().ColumnTypes(dst)

	for i := range columns {
		found := false
		for j := range fields {
			if columns[i].Name() == fields[j].DBName {
				found = true
				break
			}
		}
		if !found {
			DB.Migrator().DropColumn(dst, columns[i].Name())
		}
	}
}

func InitDB() {

	var err error
	DBPAth := filepath.Join(GetCurrentDir(), "gorm.db")
	DB, err = gorm.Open(sqlite.Open("file:///"+DBPAth+"?cache=shared&_pragma=journal_mode(MEMORY)&_pragma=busy_timeout(20000)"), &gorm.Config{})
	if err != nil {
		log.Println(err)
		return
	}
	SQLDB, _ := DB.DB()
	SQLDB.SetMaxIdleConns(10)
	SQLDB.SetMaxOpenConns(100)

	//defer db.Close()

	//db.DropTableIfExist = //.DropTableIfExist(&TodoItemModel{})

	//db.Migrator().DropTable(&User{})

	DB.AutoMigrate(&User{})
	DropUnusedColumns(&User{})
	DB.AutoMigrate(&Project{})
	DropUnusedColumns(&Project{})
	DB.AutoMigrate(&Task{})
	DropUnusedColumns(&Task{})
	DB.AutoMigrate(&Message{})
	DropUnusedColumns(&Message{})
	DB.AutoMigrate(&SeenMessage{})
	DropUnusedColumns(&SeenMessage{})
	DB.AutoMigrate(&SeenTask{})
	DropUnusedColumns(&SeenTask{})

	/*var tasks []*Task
	DB.Where("last_message_ID = 0").Find(&tasks)

	for i := range tasks {
		var message Message
		DB.Where("task_ID = ?", tasks[i].ID).Order("created_at desc").First(&message)
		tasks[i].LastMessageID = message.ID
		tasks[i].LastMessage = message.Text
	}
	if len(tasks) > 0 {
		DB.Save(&tasks)
	}*/

	var count int64
	DB.Model(&Project{}).Count(&count)
	if count == 0 {
		var project Project
		project.Description = "Default project"
		DB.Create(&project)
	}

	DB.Model(&User{}).Count(&count)
	if count == 0 {
		var user User
		hash := sha256.Sum256([]byte(""))
		user.PasswordHash = hex.EncodeToString(hash[:])
		user.Name = "admin"
		DB.Create(&user)
	}

	/*var messages []*Message
	DB.Where("project_id = 0 OR project_id is null AND task_id > 0").Find(&messages)

	for i := range messages {
		var task Task
		DB.Where("id = ?", messages[i].TaskID).First(&task)
		if task.ID > 0 {
			var message *Message
			message = messages[i]
			message.ProjectID = task.ProjectID
			//DB.Save(message)
			DB.Model(message).Updates(message)
		}

	}*/
	/*if len(messages) > 0 {
		DB.Save(&messages)
	}*/

	// Full text search

	// FTS Messages
	DB.Exec("DROP TABLE IF EXISTS messages_fts")
	DB.Exec("CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts USING fts5(text, task_id, project_id, content=messages, content_rowid=ID)")
	DB.Exec("INSERT INTO messages_fts (rowid, text, task_id, project_id) SELECT ID, text, task_id, project_id FROM messages")

	// MESSAGE INSERT TRIGGER
	DB.Exec("DROP TRIGGER IF EXISTS messages_ai")
	trigger_query := `CREATE TRIGGER IF NOT EXISTS messages_ai AFTER INSERT ON messages 
	    BEGIN
	        INSERT INTO messages_fts (rowid, text, task_id, project_id) 
	        VALUES (new.id, new.text, new.task_id, new.project_id);
	    END;`

	DB.Exec(trigger_query)

	// MESSAGE DELETE TRIGGER
	DB.Exec("DROP TRIGGER IF EXISTS messages_ad")
	trigger_query = `CREATE TRIGGER IF NOT EXISTS messages_ad AFTER DELETE ON messages BEGIN
	INSERT INTO messages_fts(messages_fts, rowid, text, task_id, project_id) VALUES('delete', old.id, old.text, old.task_id, old.project_id);
  END`

	DB.Exec(trigger_query)

	// MESSAGE UPDATE TRIGGER
	DB.Exec("DROP TRIGGER IF EXISTS messages_au")
	trigger_query = `CREATE TRIGGER IF NOT EXISTS messages_au AFTER UPDATE ON messages BEGIN
	INSERT INTO messages_fts(messages_fts, rowid, text, task_id, project_id) VALUES('delete', old.id, old.text, old.task_id, old.project_id);
	INSERT INTO messages_fts(rowid, text, task_id, project_id) VALUES(new.id, new.text, new.task_id, new.project_id);
  END`

	DB.Exec(trigger_query)

	// FTS Tasks
	DB.Exec("DROP TABLE IF EXISTS tasks_fts")
	DB.Exec("CREATE VIRTUAL TABLE IF NOT EXISTS tasks_fts USING fts5(description, project_id, content=tasks, content_rowid=ID)")
	DB.Exec("INSERT INTO tasks_fts (rowid, description, project_id) SELECT ID, description, project_id FROM tasks")

	// TASK INSERT TRIGGER
	DB.Exec("DROP TRIGGER IF EXISTS tasks_ai")
	trigger_query = `CREATE TRIGGER IF NOT EXISTS tasks_ai AFTER INSERT ON tasks
	    BEGIN
	        INSERT INTO tasks_fts (rowid, description, project_id)
	        VALUES (new.id, new.description, new.project_id);
	    END;`

	DB.Exec(trigger_query)

	// TASK DELETE TRIGGER
	DB.Exec("DROP TRIGGER IF EXISTS tasks_ad")
	trigger_query = `CREATE TRIGGER IF NOT EXISTS tasks_ad AFTER DELETE ON tasks BEGIN
	INSERT INTO tasks_fts(tasks_fts, rowid, description, project_id) VALUES('delete', old.id, old.description, old.project_id);
  END`

	DB.Exec(trigger_query)

	// TASK UPDATE TRIGGER
	DB.Exec("DROP TRIGGER IF EXISTS tasks_au")
	trigger_query = `CREATE TRIGGER IF NOT EXISTS tasks_au AFTER UPDATE ON tasks BEGIN
	INSERT INTO tasks_fts(tasks_fts, rowid, description, project_id) VALUES('delete', old.id, old.description, old.project_id);
	INSERT INTO tasks_fts(rowid, description, project_id) VALUES(new.id, new.description, new.project_id);
  END`

	DB.Exec(trigger_query)

	/*var tasks []*Task

	rows, err := DB.Raw(`
	SELECT tasks.last_message_id,
	tasks.last_message,
	messages.created_at,
	tasks_fts.rowid,
	tasks.description,
	tasks.creation_date,
	tasks.author_id
	FROM tasks_fts(@search)
	inner join tasks as tasks on tasks.ID = tasks_fts.rowid
	inner join messages as messages on tasks.last_message_id = messages.ID where tasks_fts.project_id = @projectID`, sql.Named("search", search), sql.Named("projectID", projectID)).Order("created_at desc").Rows()
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
	}*/

	/*var tasks []*Task
	DB.Where("Project_ID = 0").Find(&tasks)

	for i := range tasks {
		tasks[i].ProjectID = 2
	}
	DB.Save(&tasks)*/
	/*var messages []*Message
	DB.Find(&messages)

	for i := range messages {
		messages[i].SmallImageName = messages[i].SmallImageLocalPath
	}

	DB.Save(&messages)*/

	/*var tasks []Task
	DB.Find(&tasks)

	for i := range tasks {
		tasks[i].ProjectID = 2
	}

	DB.Save(&tasks)*/
	// Sessions
	sessionDB.AutoMigrate(&Session{})

	/*var message Message
	message.ID = 4
	message.TaskID = 34
	message.Text = "Hi"
	db.Create(&message)*/
	//DB.Migrator().DropColumn(&Message{}, "picture_data_base64")
	/*db.Migrator().DropColumn(&Message{}, "deleted_at")
	db.Migrator().AddColumn(&Message{}, "field2")*/

}

func GetMessagesDB(SessionID uuid.UUID, lastID int64, limit int64, taskID int64, filter string, messageIDPosition int64) []*Message {

	//	start := time.Now()
	log.Info("Get Messages")

	var messages []*Message
	//DB.Where("task_id = ?", taskID).Order("created_at desc").Offset(offset).Limit(limit).Find(&messages)
	if lastID == 0 {
		if messageIDPosition > 0 {
			var addMessages []*Message
			DB.Order("ID desc").Where("task_id = ? AND ID >= ?", taskID, messageIDPosition).Find(&addMessages)
			DB.Order("ID desc").Where("task_id = ? AND ID < ?", taskID, messageIDPosition).Limit(int(limit)).Find(&messages)
			messages = append(addMessages, messages...)
			/*DB.Raw("? UNION ?",
				DB.Order("ID desc").Where("task_id = ? AND ID >= ?", taskID, messageIDPosition).Model(&Message{}),
				DB.Order("ID desc").Where("task_id = ? AND ID >= ?", taskID, messageIDPosition).Model(&Message{}),
			).Scan(&messages)*/
		} else {
			DB.Order("ID desc").Where("task_id = ?", taskID).Limit(int(limit)).Find(&messages)
		}
	} else {
		DB.Order("ID desc").Where("task_id = ? AND ID < ?", taskID, lastID).Limit(int(limit)).Find(&messages)
	}

	UserID := GetUserIDBySessionID(SessionID)
	if UserID != 0 {
		for i := range messages {
			seenMessage := SeenMessage{UserID: UserID, TaskID: taskID, MessageID: messages[i].ID}
			if DB.Find(&seenMessage).RowsAffected == 0 {
				DB.Create(&seenMessage)
			}
		}

		seenTask := SeenTask{UserID: UserID, TaskID: taskID}

		if DB.Find(&seenTask).RowsAffected == 0 { // not found
			DB.Create(&seenTask)
		}
	}

	/*res, err := json.Marshal(messages)

	if err != nil {
		res = []byte{}
	}*/
	//elapsed := time.Since(start)
	//log.Printf("Get messages took %s", elapsed.Seconds())

	return messages
}

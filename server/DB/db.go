package DB

import (
	"path/filepath"
	"time"

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
	DB, err = gorm.Open(sqlite.Open(DBPAth+"?_pragma=journal_mode(MEMORY)"), &gorm.Config{})
	if err != nil {
		log.Println(err)
		return
	}
	//defer db.Close()

	//db.DropTableIfExist = //.DropTableIfExist(&TodoItemModel{})

	//db.Migrator().DropTable(&User{})

	/*DB.AutoMigrate(&User{})
	DropUnusedColumns(&User{})
	DB.AutoMigrate(&Project{})
	DropUnusedColumns(&Project{})
	DB.AutoMigrate(&Task{})
	DropUnusedColumns(&Task{})
	DB.AutoMigrate(&Message{})
	DropUnusedColumns(&Message{})*/

	var count int64
	DB.Model(&Project{}).Count(&count)
	if count == 0 {
		var project Project
		project.Description = "Default project"
		DB.Create(&project)
	}

	// Full text search

	// FTS Messages
	DB.Exec("DROP TABLE IF EXISTS messages_fts")
	DB.Exec("CREATE VIRTUAL TABLE IF NOT EXISTS messages_fts USING fts5(text, task_id, project_id content=messages, content_rowid=ID)")
	DB.Exec("INSERT INTO messages_fts (rowid, text, task_id, project_id) (SELECT ID, text, task_id, project_id FROM messages)")

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
	INSERT INTO messages_fts(messages_fts, rowid, text, project_id) VALUES('delete', old.id, old.text, old.task_id, old.project_id);
	INSERT INTO messages_fts(rowid, text, task_id) VALUES(new.id, new.text, new.task_id, new.project_id);
  END`

	DB.Exec(trigger_query)

	// FTS Tasks
	DB.Exec("DROP TABLE IF EXISTS tasks_fts")
	DB.Exec("CREATE VIRTUAL TABLE IF NOT EXISTS tasks_fts USING fts5(description, content=tasks, content_rowid=ID)")
	DB.Exec("INSERT INTO tasks_fts (rowid, description) SELECT ID, description FROM tasks")

	// TASK INSERT TRIGGER
	DB.Exec("DROP TRIGGER IF EXISTS tasks_ai")
	trigger_query = `CREATE TRIGGER IF NOT EXISTS tasks_ai AFTER INSERT ON tasks
	    BEGIN
	        INSERT INTO tasks_fts (rowid, description)
	        VALUES (new.id, new.description);
	    END;`

	DB.Exec(trigger_query)

	// TASK DELETE TRIGGER
	DB.Exec("DROP TRIGGER IF EXISTS tasks_ad")
	trigger_query = `CREATE TRIGGER IF NOT EXISTS tasks_ad AFTER DELETE ON tasks BEGIN
	INSERT INTO tasks_fts(tasks_fts, rowid, description) VALUES('delete', old.id, old.description);
  END`

	DB.Exec(trigger_query)

	// TASK UPDATE TRIGGER
	trigger_query = `CREATE TRIGGER IF NOT EXISTS tasks_au AFTER UPDATE ON tasks BEGIN
	INSERT INTO tasks_fts(tasks_fts, rowid, description) VALUES('delete', old.id, old.description);
	INSERT INTO tasks_fts(rowid, description) VALUES(new.id, new.description);
  END`

	DB.Exec(trigger_query)

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

func GetMessagesDB(lastID int64, limit int64, taskID int64, filter string) []*Message {

	start := time.Now()
	log.Info("Get Messages")

	var messages []*Message
	//DB.Where("task_id = ?", taskID).Order("created_at desc").Offset(offset).Limit(limit).Find(&messages)
	if lastID == 0 {
		DB.Order("ID desc").Where("task_id = ?", taskID).Limit(int(limit)).Find(&messages)
	} else {
		DB.Order("ID desc").Where("task_id = ? AND ID < ?", taskID, lastID).Limit(int(limit)).Find(&messages)
	}

	/*for i := range messages {
		data, err_read := os.ReadFile(filepath.Join(FileStoragePath, messages[i].SmallImageLocalPath))
		if err_read == nil {
			messages[i].SmallImageBase64 = ToBase64(data)
		}

	}*/
	/*res, err := json.Marshal(messages)

	if err != nil {
		res = []byte{}
	}*/
	elapsed := time.Since(start)
	log.Printf("Get messages took %s", elapsed.Seconds())

	return messages
}
